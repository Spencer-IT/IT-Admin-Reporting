<#
.SYNOPSIS
    Identifies and reports on Office 365 email entities: Distribution Groups, Shared Mailboxes, or Others.

.DESCRIPTION
    This script takes a list of email addresses, determines each entity type, and extracts relevant metadata
    (owners, members, permissions, forwarding, etc.). Outputs all results to a CSV file.

.PARAMETER EmailAddresses
    One or more email addresses to analyze.

.PARAMETER OutputCsv
    Path to the CSV report file. Defaults to 'ExchangeEntityReport.csv' in the current directory.

.EXAMPLE
    PS C:\> .\Get-ExchangeEntityReport.ps1 -EmailAddresses "payroll@techhelpfast.com","info@techhelpfast.com"

.NOTES
    Requires the ExchangeOnlineManagement module or appropriate Exchange PowerShell module.
    For Office 365, connect via Connect-ExchangeOnline or Connect-EXOPSSession as needed.

#>

param (
    [Parameter(Mandatory=$true)]
    [string[]]$EmailAddresses,

    [Parameter(Mandatory=$false)]
    [string]$OutputCsv = ".\ExchangeEntityReport.csv"
)

# -----------------------
# Connect to Exchange Online (if applicable)
# -----------------------
# Uncomment the following if you need to connect to Exchange Online:
# Import-Module ExchangeOnlineManagement
# Connect-ExchangeOnline -UserPrincipalName youradmin@domain.com

# -----------------------
# Define Helper Functions
# -----------------------

function Get-DistributionGroupDetails {
    param(
        [string]$Identity
    )

    $dg = Get-DistributionGroup -Identity $Identity -ErrorAction Stop
    $dgMembers = Try {
        (Get-DistributionGroupMember -Identity $Identity -ErrorAction Stop |
            Select-Object -ExpandProperty PrimarySmtpAddress) -join ", "
    } Catch {
        "No Members"
    }

    $ownerList = $dg.ManagedBy | ForEach-Object { $_.PrimarySmtpAddress } -join ", "
    if (-not $ownerList) { $ownerList = "No Owners" }

    # External send permission check
    $externalAllowed = if ($dg.RequireSenderAuthenticationEnabled -eq $false) { "Yes" } else { "No" }

    return [PSCustomObject]@{
        Owner               = $ownerList
        Members             = $dgMembers
        SendAsPermissions   = "N/A"
        FullAccessPermissions = "N/A"
        ExternalSenders     = $externalAllowed
        ForwardingAddress   = "No Forwarding"
    }
}

function Get-SharedMailboxDetails {
    param(
        [string]$Identity
    )

    $mbx = Get-Mailbox -Identity $Identity -ErrorAction Stop

    # Full Access permissions
    $fullAccessList = (Get-MailboxPermission -Identity $Identity -ErrorAction SilentlyContinue |
        Where-Object { $_.AccessRights -contains "FullAccess" -and $_.User -notlike "NT AUTHORITY\SELF" } |
        Select-Object -ExpandProperty User) -join ", "

    # SendAs permissions
    $sendAsList = (Get-RecipientPermission -Identity $Identity -ErrorAction SilentlyContinue |
        Where-Object { $_.AccessRights -contains "SendAs" } |
        Select-Object -ExpandProperty Trustee) -join ", "

    if (-not $fullAccessList) { $fullAccessList = "N/A" }
    if (-not $sendAsList) { $sendAsList = "N/A" }

    # Forwarding address (if any)
    $forwarding = if ($mbx.ForwardingSMTPAddress) { 
        $mbx.ForwardingSMTPAddress 
    } else {
        "No Forwarding"
    }

    return [PSCustomObject]@{
        Owner                  = "N/A"          # Typically, 'ManagedBy' doesn't apply to shared mailboxes in the same way
        Members                = "N/A"          # Shared mailboxes don't have traditional 'members' 
        SendAsPermissions      = $sendAsList
        FullAccessPermissions  = $fullAccessList
        ExternalSenders        = "N/A"
        ForwardingAddress      = $forwarding
    }
}

function Get-OtherEntityDetails {
    # For entities that are not recognized as DG or Shared Mailbox.
    return [PSCustomObject]@{
        Owner                  = "N/A"
        Members                = "N/A"
        SendAsPermissions      = "N/A"
        FullAccessPermissions  = "N/A"
        ExternalSenders        = "N/A"
        ForwardingAddress      = "N/A"
    }
}

# -----------------------
# Main Script Logic
# -----------------------

# Prepare a list for results
$results = @()

foreach ($email in $EmailAddresses) {

    Write-Host "Processing $email ..."

    # Try retrieving the recipient object
    $recipient = Get-Recipient -ErrorAction SilentlyContinue -Filter "EmailAddresses -eq 'SMTP:$email'"

    if (-not $recipient) {
        Write-Warning "Recipient not found for $email. Logging error in output."
        
        # Log an entry with error info
        $results += [PSCustomObject]@{
            EntityName             = "Not Found"
            EntityType             = "N/A"
            PrimaryEmail           = $email
            Aliases                = "N/A"
            Owner                  = "N/A"
            Members                = "N/A"
            SendAsPermissions      = "N/A"
            FullAccessPermissions  = "N/A"
            ExternalSenders        = "N/A"
            ForwardingAddress      = "N/A"
        }
        continue
    }

    # Identify entity type
    $entityType = $recipient.RecipientTypeDetails

    # Aliases
    # Note: $recipient.EmailAddresses is an array of SMTP, smtp, etc. We filter only SMTP/proxy addresses.
    $aliases = ($recipient.EmailAddresses | Where-Object { $_ -like "smtp:*" -or $_ -like "SMTP:*" }) -join ", "
    
    # Collect baseline object properties
    $entityName  = $recipient.DisplayName
    $primaryEmail = $recipient.PrimarySmtpAddress
    
    # Prepare placeholders
    $owner              = $null
    $members            = $null
    $sendAsPermissions  = $null
    $fullAccessPermissions = $null
    $externalSenders    = $null
    $forwardingAddress  = $null

    # -----------------------
    # Handle entity-specific details
    # -----------------------
    switch -Wildcard ($entityType) {
        "MailUniversalDistributionGroup" {
            # Classic distribution group
            $details = Get-DistributionGroupDetails -Identity $primaryEmail
            $entityTypeReadable = "Distribution Group"
        }

        "MailUniversalSecurityGroup" {
            # Security group mail-enabled (treated similarly to distribution group in many ways)
            $details = Get-DistributionGroupDetails -Identity $primaryEmail
            $entityTypeReadable = "Distribution Group (Security)"
        }

        "SharedMailbox" {
            $details = Get-SharedMailboxDetails -Identity $primaryEmail
            $entityTypeReadable = "Shared Mailbox"
        }

        default {
            # Fallback if not recognized as DG or Shared
            $details = Get-OtherEntityDetails
            $entityTypeReadable = "Other"
        }
    }

    # Build result record
    $results += [PSCustomObject]@{
        EntityName            = $entityName
        EntityType            = $entityTypeReadable
        PrimaryEmail          = $primaryEmail
        Aliases               = $aliases
        Owner                 = $details.Owner
        Members               = $details.Members
        SendAsPermissions     = $details.SendAsPermissions
        FullAccessPermissions = $details.FullAccessPermissions
        ExternalSenders       = $details.ExternalSenders
        ForwardingAddress     = $details.ForwardingAddress
    }

}

# -----------------------
# Output Results to CSV
# -----------------------
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
Write-Host "Report saved to $OutputCsv"
