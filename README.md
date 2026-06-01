<img width="550" height="453" alt="epsilon_dark" src="https://github.com/user-attachments/assets/3066fbff-b612-43fd-8d53-392bf3210ca0" />

## Changelog
See [CHANGELOG.md](./CHANGELOG.md) for version history.

---

## What's New in v1.3

- Added **Delegation Management** module
  - Update folder-level delegate permissions across common folders
  - Review folder-level delegate permissions
  - Review mailbox-level delegation
  - Downgrade mailbox-level delegates to folder-level Reviewer

- Expanded delegation visibility
  - Review **Full Access**
  - Review **Send As**
  - Review **Send on Behalf**

- Improved assistant / executive workflow support
  - Better handling of scoped reviewer access
  - Easier transition from mailbox-level access to folder-level delegation

- Continued improvements to script structure, reliability, and usability

---

## Project

**EPSILON – Exchange Online & Compliance Toolkit**

EPSILON is a PowerShell-based administrative toolkit designed to simplify and streamline common tasks in Microsoft 365, specifically across Exchange Online and the Compliance (Purview) Center.

Built with MSP workflows in mind, EPSILON provides a menu-driven interface for fast, repeatable operations without needing to remember complex PowerShell commands.

---

## Project Structure

This repository includes three deployment formats:

### Windows PowerShell Script
- `EPSILON.ps1`  
- Full interactive menu for Exchange Online & Compliance tasks  

### macOS PowerShell Script
- `EPSILON-MAC.ps1`  
- Compatible with PowerShell Core (`pwsh`) on macOS  

### Executable Version
- `EPSILON.exe`  
- Packaged version of the PowerShell script for simplified execution  
- **Note:** This is a wrapped `.ps1`, not a compiled binary  

---

## Features

### Exchange Online
- List mailboxes  
- View mailbox details  
- Create mailboxes  
- Remove mailboxes  
- Enable archive mailbox  
- Enable auto-expanding archive  
- Trigger Managed Folder Assistant  
- View inbox rules  
- Remove inbox rules  

### Calendar & Delegation
- Grant calendar access (Reviewer, Editor, Owner, etc.)  
- Modify existing calendar permissions  
- Remove calendar access  
- View calendar permissions  
- Built-in access level selection  
- Automatic update of existing permissions  

### Delegation Management (New in v1.3)
- Update folder-level delegate permissions across common folders  
- Review folder-level delegate permissions  
- Review mailbox-level delegation  
- Downgrade mailbox-level delegates to folder-level Reviewer  

### Shared Mailbox Management
- List shared mailboxes  
- Convert user mailbox to shared  
- Convert shared mailbox to regular  
- Add / remove Full Access  
- Add / remove Send As  

### Compliance (Purview)
- Create Compliance Searches (by subject)  
- Start and monitor searches  
- Purge emails from tenant  
- Status tracking and completion loops  

---

## Requirements

- PowerShell 5.1+ (Windows) or PowerShell Core (macOS/Linux)

### Microsoft Modules
- ExchangeOnlineManagement  
- Microsoft.Graph *(optional depending on usage)*  

If modules are missing, EPSILON can prompt or install them automatically depending on version.

---

## Permissions Required

- Exchange Admin or Global Admin  
- Compliance Admin *(for Purview features)*  

---

## Usage

### Windows (PS1)
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\EPSILON - v1.3.ps1"
```

### macOS (PowerShell Core)
```bash
pwsh ./EPSILON - v1.3 - MAC.ps1
```

### Executable
```text
EPSILON - v1.3.exe
```

---

## Execution Policy / Security

If you encounter script blocking:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
```

This allows the script to run without permanently lowering system security.

---

## Notes

- The EXE version is a wrapped PowerShell script and may still trigger security warnings  
- Some features (like Compliance purge) can take time — EPSILON includes built-in progress loops  
- Managed Folder Assistant errors (RPC issues) are typically server-side and not caused by the script  
- Folder-level delegation depends on common default folder names and may vary in some environments  

---

## Known Issues

- `Start-ManagedFolderAssistant` may return:

  ```text
  RPC Error -2147220992
  ```

  This is a Microsoft service-side issue and usually resolves on retry.

- Inbox rule creation timestamps are not directly exposed via standard cmdlets  

- Calendar permissions do not automatically configure full Outlook delegate behavior (meeting handling requires additional configuration)

- Folder-level delegation operations may be affected by localized or non-standard folder names

---

## Roadmap / Future Enhancements

- CSV reporting / export options  
- Enhanced auditing capabilities  
- Microsoft Graph integration  
- Expanded error handling  
- Potential GUI version  

---

## Contributing

Contributions, improvements, and ideas are welcome.

If you’re an MSP or admin using this in production, feel free to submit:

- Feature requests  
- Bug reports  
- Enhancements  

---

## License

This project is provided **as-is** for administrative use.

Customize freely for internal or client environments.

Developed for real-world MSP operations to reduce friction and increase efficiency in Microsoft 365 administration.

EPSILON is licensed under the GNU Affero General Public License v3.0 (AGPL-3.0).

See the LICENSE file for details.

---

![Version](https://img.shields.io/badge/version-v1.3-blue)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS-lightgrey)
![PowerShell](https://img.shields.io/badge/powershell-5.1%2B%20%7C%20Core-blue)
