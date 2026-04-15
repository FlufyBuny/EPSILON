# EPSILON v1.2 – Release Notes

## Overview

EPSILON v1.2 builds upon the stable foundation established in v1.1, introducing enhanced calendar and delegation management capabilities while continuing to refine the unified, menu-driven PowerShell toolkit for Exchange Online and Compliance administration.

This release expands real-world usability, particularly for MSP and executive-support scenarios.

---

## Development Evolution

EPSILON v1.2 continues the progression of prior internal development phases:

- ALPHA
  - Initial concept and basic Exchange Online interaction

- DELTA (v0.01 → v0.8)
  - Introduction of core menu system  
  - Archiving and mailbox management features  
  - Compliance search and purge functionality  
  - Iterative improvements and feature expansion  

- GAMMA (v0.9 → v1.0)
  - Stabilization of core features  
  - Refinement of menu structure and usability  
  - Preparation for production use  

- EPSILON (v1.1 → v1.2)
  - Consolidation into production-ready toolkit  
  - Introduction of advanced administrative workflows  
  - Expansion into calendar and delegation management  

---

## Core Features

### Exchange Online

- Mailbox management (create, remove, view details)  
- Archive mailbox enablement  
- Auto-expanding archive support  
- Managed Folder Assistant execution (with retry logic)  
- Inbox rule visibility and management  
- Inbox rule deletion via Identity  
- Mail user and contact management  

---

### Calendar & Delegation (New in v1.2)

- Grant calendar permissions (Reviewer, Editor, Owner, etc.)  
- Modify existing calendar permissions dynamically  
- Remove calendar access  
- View current calendar permissions  
- Built-in access level selection menu  
- Automatic detection and update of existing permissions  

---

### Compliance (Purview)

- Compliance search creation  
- Search execution and monitoring  
- Email purge functionality  
- Subject-based search filtering  

---

## Improvements

- Expanded menu structure to include Calendar Permissions module  
- Added predefined permission levels for faster administration  
- Improved handling of existing permissions (update vs. duplicate errors)  
- Enhanced real-world MSP workflows (assistant / executive scenarios)  
- Continued refinement of script reliability and user experience  
- Maintained separation between Exchange and Compliance connections  

---

## Known Limitations

- Inbox rule creation timestamps are not available via standard Exchange cmdlets  
- Some Exchange operations (e.g., Managed Folder Assistant) may return intermittent service-side RPC errors  
- Calendar permissions do not automatically configure full Outlook delegate behavior (meeting handling requires additional configuration)  

---

## Notes

EPSILON v1.2 represents a significant step forward in practical administration, introducing calendar and delegation capabilities that align with real-world support needs.

This version continues to serve as a stable foundation for future enhancements, including deeper delegation controls, reporting, and Microsoft Graph integration.  
