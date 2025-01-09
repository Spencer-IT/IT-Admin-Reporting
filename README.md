# IT Admin Reporting

For now this is a single PowerShell script designed to identify and report on Office 365 email entities, including Distribution Groups, Shared Mailboxes, and other types. This tool provides a detailed overview of email-related configurations, making IT administration easier and more efficient.

This first script is for Office 365.

---

## Features

- Identify the type of Office 365 email entity:
  - Distribution Groups
  - Shared Mailboxes
  - Other Email Entities
- Extract and report metadata:
  - Owners
  - Members
  - Permissions (SendAs, FullAccess)
  - Forwarding Settings
- Generate detailed reports in CSV format.

---

## Requirements

- **PowerShell** (I'm using 7x, not sure what this will work on yet)
- **ExchangeOnlineManagement Module**
  - Install using:
    ```powershell
    Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser
    ```
- Office 365 administrator credentials (or whatever permissions) to run the script.

---

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/Spencer-IT/IT-Admin-Reporting.git
   cd IT-Admin-Reporting
   ```

2. Install required PowerShell modules:
    
    ```powershell
    Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser
    ```
    
3. Ensure you have the appropriate permissions to connect to Office 365. you can use granular permissions which could be the following I just haven't verified:

    ```
    TODO: Coming later
    ```
    

---

## Usage

TODO: Test connecting without doing so beforehand. I was going to add a connection and test it. All I did at this point is add the lines and comment them out. For now I connect before I run the scripts by running:

  ```powershell
  Connect-ExchangeOnline
  ```
                                                                    

1. Open PowerShell and navigate to the directory containing the script.
2. Run the script with the required parameters:
    
    ```powershell
    .\Get-ExchangeEntityReport.ps1 -EmailAddresses "email1@yourdomain.com", "email2@yourdomain.com" -OutputCsv "Report.csv"
    ```
    If you don't specify -OutputCsv then it will default to ExcahngeEntityReport.csv (I say the same thing in a few lines)
    
3. Use/view the generated `Report.csv` file

---

## Parameters

- `EmailAddresses` (Mandatory): A list of email addresses to analyze.
- `OutputCsv` (Optional): Path to save the generated CSV report. Defaults to `ExchangeEntityReport.csv` in the current directory.

---

## Example

```powershell
.\Get-ExchangeEntityReport.ps1 -EmailAddresses "support@company.com", "admin@company.com"
```

The script will:

- Connect to Exchange Online (I always connect before running the script)
- Identify email entities and retrieve metadata.
- Save the results in `ExchangeEntityReport.csv`.

---

## Known Issues and Limitations

- The script requires modern authentication (MFA-enabled accounts are supported)
- Large lists of email addresses may take longer to process
- Errors in retrieving specific entities will be logged in the CSV
- 365 Groups support not added yet
- I get a error cannot convert the "-joins" value of type "system.string".... It still gets the ouput I need right now so I'm not going to spend the time on it until it causes some issues for me. It is also possible this error was introduced when I plugged my original code into ChatGPT. I will test that theory later.
- I had ChatGPT make this inital README. It did an ok job, I liked the formating and not having to write all the details, but I did have to change a lot of things so please submit anything you find wrong

---

## Contributing

Contributions are welcome! Feel free to submit pull requests or report issues in the [Issues](https://github.com/Spencer-IT/IT-Admin-Reporting/issues) section.

---

## License

This project is licensed under the [MIT License](https://github.com/Spencer-IT/IT-Admin-Reporting/blob/main/LICENSE).

---

## Contact

If you have questions or need support, contact **Spencer** at `spencer@techsico.it`.


---

## Things I want to add/try:
- Easy tenant switching
- Microsoft 365 Group support
- I took my original script and used ChatGPT to add comments and it made some minor changes. I might upload the original and then the ChatGPT version to show the changes.
- I used to have Copilot last year but didn't use it so I cancelled. I may get it back to see what kinds of changes and updates it recommends
- As I add scripts and tools I will create a folder structure
- Potentially have a main menu
- Potentially have a GUI, if I go that route I will start a C# project

