# EPSILON v1.3 – Release Notes

## Overview

EPSILON v1.3 expands the toolkit with a new Delegation Management module, giving administrators better visibility and control over folder-level and mailbox-level delegation in Exchange Online.

This release builds on the stability and administrative improvements of v1.2, with a strong focus on real-world assistant, executive, and MSP delegation workflows.

---

## What's New

- Added **Delegation Management** module
  - Update folder-level delegate permissions across common folders
  - Review folder-level delegate permissions
  - Review mailbox-level delegation
  - Downgrade mailbox-level delegates to folder-level Reviewer

- Expanded administrative visibility
  - Review **Full Access**
  - Review **Send As**
  - Review **Send on Behalf**

- Improved delegation workflows for:
  - assistant / executive access
  - shared mailbox support
  - scoped reviewer-only access models

---

## Development Evolution

EPSILON v1.3 continues the progression of prior internal development phases:

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

- EPSILON (v1.1 → v1.3)
  - Consolidation into production-ready toolkit  
  - Calendar and delegation management added  
  - Expansion into broader Exchange administration workflows  

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

### Calendar & Delegation

- Grant calendar permissions (Reviewer, Editor, Owner, etc.)  
- Modify existing calendar permissions dynamically  
- Remove calendar access  
- View current calendar permissions  
- Built-in access level selection menu  
- Automatic detection and update of existing permissions  

---

### Delegation Management (New in v1.3)

- Update folder-level delegate permissions across:
  - Inbox
  - Calendar
  - Contacts
  - Tasks
  - Notes
  - Journal
  - Drafts
  - Sent Items

- Review folder-level delegate permissions  
- Review mailbox-level delegation:
  - Full Access
  - Send As
  - Send on Behalf

- Downgrade mailbox-level delegates to folder-level Reviewer  

---

### Shared Mailbox Management

- List shared mailboxes  
- Convert user mailbox to shared  
- Convert shared mailbox to regular  
- Add / remove Full Access  
- Add / remove Send As  

---

### Compliance (Purview)

- Compliance search creation  
- Search execution and monitoring  
- Email purge functionality  
- Subject-based search filtering  

---

## Improvements

- Added dedicated Delegation Management module to the Exchange menu  
- Improved visibility into mailbox-level and folder-level delegation  
- Simplified downgrade path from mailbox-level access to folder-level reviewer access  
- Continued refinement of script structure, reliability, and usability  
- Maintained separation between Exchange and Compliance connections  

---

## Known Limitations

- Inbox rule creation timestamps are not available via standard Exchange cmdlets  
- Some Exchange operations (e.g., Managed Folder Assistant) may return intermittent service-side RPC errors  
- Calendar permissions do not automatically configure full Outlook delegate behavior (meeting handling requires additional configuration)  
- Folder names may vary in some environments, which can affect folder-level delegation operations  

---

## Notes

EPSILON v1.3 represents a meaningful expansion of administrative control, especially for organizations that rely heavily on delegated mailbox and calendar access.

This release continues to strengthen EPSILON as a practical Microsoft 365 administration toolkit for real-world MSP operations.
