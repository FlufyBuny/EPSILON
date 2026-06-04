# ============================================================
# EPSILON - Exchange Online / User Management Toolkit
# Version: 1.4.4 Test Build
# L1-Friendly Edition - Email Address Based
# ============================================================

$Host.UI.RawUI.WindowTitle = "EPSILON - Exchange Online Toolkit"

# -----------------------------
# Core Helpers
# -----------------------------

function Pause-Epsilon {
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Show-Header {
    param([string]$Title)

    Clear-Host
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " EPSILON - $Title" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Ensure-Module {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )

    try {
        if (-not (Get-Module -ListAvailable -Name $ModuleName)) {
            Write-Host "Installing required module: $ModuleName..." -ForegroundColor Yellow

            $progressBackup = $global:ProgressPreference
            $global:ProgressPreference = "SilentlyContinue"

            Install-Module $ModuleName `
                -Scope CurrentUser `
                -Force `
                -AllowClobber `
                -Confirm:$false `
                -ErrorAction Stop | Out-Null

            $global:ProgressPreference = $progressBackup
        }

        Import-Module $ModuleName -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
        return $true
    }
    catch {
        Write-Host "Failed to load module $ModuleName`: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Test-EpsilonExchangeConnected {
    try {
        $connections = Get-ConnectionInformation -ErrorAction Stop
        return ($connections.Count -gt 0)
    }
    catch {
        return $false
    }
}

function Require-EpsilonExchangeConnected {
    if (Test-EpsilonExchangeConnected) {
        return $true
    }

    Write-Host ""
    Write-Host "Exchange Online is not connected." -ForegroundColor Yellow
    Write-Host "Please use option 1 from the Main Menu to connect first." -ForegroundColor Yellow
    Pause-Epsilon
    return $false
}

function Ensure-GraphConnection {
    try {
        $ctx = Get-MgContext -ErrorAction SilentlyContinue
        if ($ctx -and $ctx.Account) {
            return $true
        }
    }
    catch {}

    if (-not (Ensure-Module -ModuleName Microsoft.Graph.Authentication)) { return $false }
    if (-not (Ensure-Module -ModuleName Microsoft.Graph.Users)) { return $false }
    if (-not (Ensure-Module -ModuleName Microsoft.Graph.Users.Actions)) { return $false }

    try {
        Write-Host "Connecting to Microsoft user management services..." -ForegroundColor Cyan
        Connect-MgGraph -Scopes "User.ReadWrite.All" -NoWelcome -ErrorAction Stop
        Write-Host "Connected successfully." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Failed to connect to Microsoft user management services: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# -----------------------------
# Connections
# -----------------------------

function Connect-EpsilonExchange {
    Show-Header "Connect to Exchange Online"

    if (-not (Ensure-Module -ModuleName ExchangeOnlineManagement)) {
        Pause-Epsilon
        return
    }

    try {
        Write-Host "Connecting to Exchange Online..." -ForegroundColor Cyan
        Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop

        if (Test-EpsilonExchangeConnected) {
            Write-Host ""
            Write-Host "Connected to Exchange Online." -ForegroundColor Green
        }
        else {
            Write-Host ""
            Write-Host "Connection command completed, but no active session was detected." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Failed to connect to Exchange Online: $($_.Exception.Message)" -ForegroundColor Red
    }

    Pause-Epsilon
}

function Connect-EpsilonCompliance {
    Show-Header "Connect to Compliance / Purview"

    if (-not (Ensure-Module -ModuleName ExchangeOnlineManagement)) {
        Pause-Epsilon
        return
    }

    try {
        Connect-IPPSSession -ErrorAction Stop
        Write-Host "Connected to Compliance / Purview." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to connect to Compliance / Purview: $($_.Exception.Message)" -ForegroundColor Red
    }

    Pause-Epsilon
}

function Show-EpsilonGraphContext {
    Show-Header "Connected Microsoft Account / Tenant"

    if (-not (Ensure-GraphConnection)) {
        Pause-Epsilon
        return
    }

    try {
        Get-MgContext | Select-Object Account, TenantId, Scopes | Format-List
    }
    catch {
        Write-Host "Failed to show connected account information: $($_.Exception.Message)" -ForegroundColor Red
    }

    Pause-Epsilon
}

function Disconnect-EpsilonSessions {
    Show-Header "Disconnect Sessions"

    try {
        Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
        Write-Host "Disconnected Exchange Online session." -ForegroundColor Green
    }
    catch {
        Write-Host "No Exchange Online session was disconnected." -ForegroundColor Yellow
    }

    try {
        Disconnect-MgGraph -ErrorAction SilentlyContinue
        Write-Host "Disconnected Microsoft user management session." -ForegroundColor Green
    }
    catch {}

    Pause-Epsilon
}

# -----------------------------
# User Resolver
# -----------------------------

function Resolve-EpsilonUserByEmail {
    param(
        [Parameter(Mandatory = $true)]
        [string]$EmailAddress
    )

    $EmailAddress = $EmailAddress.Trim()

    if ([string]::IsNullOrWhiteSpace($EmailAddress)) {
        throw "Email address cannot be blank."
    }

    if ($EmailAddress -notmatch "@") {
        throw "Please enter a full email address."
    }

    if (-not (Test-EpsilonExchangeConnected)) {
        throw "Exchange Online must be connected first."
    }

    $recipient = $null

    try {
        $recipient = Get-EXORecipient -Identity $EmailAddress -ErrorAction Stop
    }
    catch {
        throw "No Exchange recipient was found for '$EmailAddress'. Confirm the email address and tenant."
    }

    Write-Host ""
    Write-Host "Exchange Recipient Found:" -ForegroundColor Cyan
    Write-Host "Name         : $($recipient.DisplayName)"
    Write-Host "Email        : $($recipient.PrimarySmtpAddress)"
    Write-Host "Type         : $($recipient.RecipientTypeDetails)"
    Write-Host ""

    if (-not $recipient.ExternalDirectoryObjectId) {
        throw "This recipient does not have a Microsoft user object ID. It may be a contact, external user, distribution group, or non-user recipient."
    }

    try {
        $user = Get-MgUser `
            -UserId $recipient.ExternalDirectoryObjectId `
            -Property Id,DisplayName,UserPrincipalName,Mail,AccountEnabled,ProxyAddresses `
            -ErrorAction Stop

        return $user
    }
    catch {
        throw "Exchange found the recipient, but Microsoft user management could not find the matching user object. Verify the connected Microsoft account/tenant."
    }
}

function Show-EpsilonUserSummary {
    param(
        [Parameter(Mandatory = $true)]
        $User
    )

    Write-Host ""
    Write-Host "User Found:" -ForegroundColor Cyan
    Write-Host "Name         : $($User.DisplayName)"
    Write-Host "Email        : $($User.Mail)"
    Write-Host "Sign-In Name : $($User.UserPrincipalName)"
    Write-Host "Sign-In      : $(if ($User.AccountEnabled) { 'Allowed' } else { 'Blocked' })"
    Write-Host ""
}

# -----------------------------
# Exchange User Management
# -----------------------------

function List-EpsilonMailboxes {
    Show-Header "List Mailboxes"

    if (-not (Require-EpsilonExchangeConnected)) { return }

    try {
        Get-EXOMailbox -ResultSize Unlimited |
            Select-Object DisplayName, PrimarySmtpAddress, RecipientTypeDetails |
            Sort-Object DisplayName |
            Format-Table -AutoSize
    }
    catch {
        Write-Host "Failed to list mailboxes: $($_.Exception.Message)" -ForegroundColor Red
    }

    Pause-Epsilon
}

function Get-EpsilonMailboxDetails {
    Show-Header "Mailbox Details"

    if (-not (Require-EpsilonExchangeConnected)) { return }

    $emailAddress = Read-Host "Enter user's email address"

    try {
        Get-EXOMailbox -Identity $emailAddress -ErrorAction Stop |
            Select-Object DisplayName, PrimarySmtpAddress, RecipientTypeDetails, ArchiveStatus, LitigationHoldEnabled |
            Format-List

        Get-EXOMailboxStatistics -Identity $emailAddress -ErrorAction Stop |
            Select-Object DisplayName, TotalItemSize, ItemCount, LastLogonTime |
            Format-List
    }
    catch {
        Write-Host "Failed to get mailbox details: $($_.Exception.Message)" -ForegroundColor Red
    }

    Pause-Epsilon
}

function Enable-EpsilonArchive {
    Show-Header "Enable Archive Mailbox"

    if (-not (Require-EpsilonExchangeConnected)) { return }

    $emailAddress = Read-Host "Enter user's email address"

    try {
        Enable-Mailbox -Identity $emailAddress -Archive -ErrorAction Stop
        Write-Host "Archive enabled for $emailAddress." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to enable archive: $($_.Exception.Message)" -ForegroundColor Red
    }

    Pause-Epsilon
}

function Enable-EpsilonAutoExpandingArchive {
    Show-Header "Enable Auto-Expanding Archive"

    if (-not (Require-EpsilonExchangeConnected)) { return }

    $emailAddress = Read-Host "Enter user's email address"

    try {
        Enable-Mailbox -Identity $emailAddress -AutoExpandingArchive -ErrorAction Stop
        Write-Host "Auto-expanding archive enabled for $emailAddress." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to enable auto-expanding archive: $($_.Exception.Message)" -ForegroundColor Red
    }

    Pause-Epsilon
}

function Start-EpsilonManagedFolderAssistant {
    Show-Header "Start Managed Folder Assistant"

    if (-not (Require-EpsilonExchangeConnected)) { return }

    $emailAddress = Read-Host "Enter user's email address"

    try {
        Start-ManagedFolderAssistant -Identity $emailAddress -ErrorAction Stop
        Write-Host "Managed Folder Assistant started for $emailAddress." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to start Managed Folder Assistant: $($_.Exception.Message)" -ForegroundColor Red
    }

    Pause-Epsilon
}

function Block-EpsilonUserSignIn {
    Show-Header "Block User Sign-In & Revoke Sessions"

    if (-not (Require-EpsilonExchangeConnected)) { return }

    $emailAddress = Read-Host "Enter user's email address"

    try {
        if (-not (Ensure-GraphConnection)) {
            Pause-Epsilon
            return
        }

        $user = Resolve-EpsilonUserByEmail -EmailAddress $emailAddress
        Show-EpsilonUserSummary -User $user

        $confirm = Read-Host "Type BLOCK to disable sign-in and revoke active sessions"

        if ($confirm -ne "BLOCK") {
            Write-Host "Operation cancelled." -ForegroundColor Yellow
            Pause-Epsilon
            return
        }

        Update-MgUser -UserId $user.Id -AccountEnabled:$false -ErrorAction Stop
        Revoke-MgUserSignInSession -UserId $user.Id -ErrorAction SilentlyContinue | Out-Null

        Write-Host ""
        Write-Host "Success: Sign-in blocked and active sessions revoked." -ForegroundColor Green
    }
    catch {
        Write-Host "Unable to locate the user or perform the action." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Pause-Epsilon
}

function Unblock-EpsilonUserSignIn {
    Show-Header "Unblock User Sign-In"

    if (-not (Require-EpsilonExchangeConnected)) { return }

    $emailAddress = Read-Host "Enter user's email address"

    try {
        if (-not (Ensure-GraphConnection)) {
            Pause-Epsilon
            return
        }

        $user = Resolve-EpsilonUserByEmail -EmailAddress $emailAddress
        Show-EpsilonUserSummary -User $user

        $confirm = Read-Host "Type UNBLOCK to re-enable sign-in"

        if ($confirm -ne "UNBLOCK") {
            Write-Host "Operation cancelled." -ForegroundColor Yellow
            Pause-Epsilon
            return
        }

        Update-MgUser -UserId $user.Id -AccountEnabled:$true -ErrorAction Stop

        Write-Host ""
        Write-Host "Success: Sign-in has been re-enabled." -ForegroundColor Green
    }
    catch {
        Write-Host "Unable to locate the user or perform the action." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Pause-Epsilon
}

function Check-EpsilonUserSignInStatus {
    Show-Header "Check User Sign-In Status"

    if (-not (Require-EpsilonExchangeConnected)) { return }

    $emailAddress = Read-Host "Enter user's email address"

    try {
        if (-not (Ensure-GraphConnection)) {
            Pause-Epsilon
            return
        }

        $user = Resolve-EpsilonUserByEmail -EmailAddress $emailAddress
        Show-EpsilonUserSummary -User $user
    }
    catch {
        Write-Host "Unable to locate the user." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Pause-Epsilon
}

function Revoke-EpsilonUserSessionsOnly {
    Show-Header "Revoke User Sessions"

    if (-not (Require-EpsilonExchangeConnected)) { return }

    $emailAddress = Read-Host "Enter user's email address"

    try {
        if (-not (Ensure-GraphConnection)) {
            Pause-Epsilon
            return
        }

        $user = Resolve-EpsilonUserByEmail -EmailAddress $emailAddress

        Write-Host ""
        Write-Host "User Found:" -ForegroundColor Cyan
        Write-Host "Name         : $($user.DisplayName)"
        Write-Host "Email        : $($user.Mail)"
        Write-Host ""

        $confirm = Read-Host "Type REVOKE to invalidate active sessions"

        if ($confirm -ne "REVOKE") {
            Write-Host "Operation cancelled." -ForegroundColor Yellow
            Pause-Epsilon
            return
        }

        Revoke-MgUserSignInSession -UserId $user.Id -ErrorAction Stop | Out-Null

        Write-Host ""
        Write-Host "Success: Active sessions revoked." -ForegroundColor Green
    }
    catch {
        Write-Host "Unable to locate the user or perform the action." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Pause-Epsilon
}

# -----------------------------
# Delegation
# -----------------------------

function Grant-EpsilonFullAccess {
    Show-Header "Grant FullAccess"

    if (-not (Require-EpsilonExchangeConnected)) { return }

    $mailboxEmail = Read-Host "Enter mailbox email address"
    $userEmail = Read-Host "Enter user email address receiving access"

    try {
        Add-MailboxPermission -Identity $mailboxEmail -User $userEmail -AccessRights FullAccess -InheritanceType All -AutoMapping:$true -ErrorAction Stop
        Write-Host "FullAccess granted." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to grant FullAccess: $($_.Exception.Message)" -ForegroundColor Red
    }

    Pause-Epsilon
}

function Remove-EpsilonFullAccess {
    Show-Header "Remove FullAccess"

    if (-not (Require-EpsilonExchangeConnected)) { return }

    $mailboxEmail = Read-Host "Enter mailbox email address"
    $userEmail = Read-Host "Enter user email address to remove"

    try {
        Remove-MailboxPermission -Identity $mailboxEmail -User $userEmail -AccessRights FullAccess -InheritanceType All -Confirm:$false -ErrorAction Stop
        Write-Host "FullAccess removed." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to remove FullAccess: $($_.Exception.Message)" -ForegroundColor Red
    }

    Pause-Epsilon
}

function Grant-EpsilonSendAs {
    Show-Header "Grant SendAs"

    if (-not (Require-EpsilonExchangeConnected)) { return }

    $mailboxEmail = Read-Host "Enter mailbox email address"
    $userEmail = Read-Host "Enter user email address receiving SendAs"

    try {
        Add-RecipientPermission -Identity $mailboxEmail -Trustee $userEmail -AccessRights SendAs -Confirm:$false -ErrorAction Stop
        Write-Host "SendAs granted." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to grant SendAs: $($_.Exception.Message)" -ForegroundColor Red
    }

    Pause-Epsilon
}

function Remove-EpsilonSendAs {
    Show-Header "Remove SendAs"

    if (-not (Require-EpsilonExchangeConnected)) { return }

    $mailboxEmail = Read-Host "Enter mailbox email address"
    $userEmail = Read-Host "Enter user email address to remove"

    try {
        Remove-RecipientPermission -Identity $mailboxEmail -Trustee $userEmail -AccessRights SendAs -Confirm:$false -ErrorAction Stop
        Write-Host "SendAs removed." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to remove SendAs: $($_.Exception.Message)" -ForegroundColor Red
    }

    Pause-Epsilon
}

function Grant-EpsilonSendOnBehalf {
    Show-Header "Grant Send on Behalf"

    if (-not (Require-EpsilonExchangeConnected)) { return }

    $mailboxEmail = Read-Host "Enter mailbox email address"
    $userEmail = Read-Host "Enter user email address receiving Send on Behalf"

    try {
        Set-Mailbox -Identity $mailboxEmail -GrantSendOnBehalfTo @{Add=$userEmail} -ErrorAction Stop
        Write-Host "Send on Behalf granted." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to grant Send on Behalf: $($_.Exception.Message)" -ForegroundColor Red
    }

    Pause-Epsilon
}

function Remove-EpsilonSendOnBehalf {
    Show-Header "Remove Send on Behalf"

    if (-not (Require-EpsilonExchangeConnected)) { return }

    $mailboxEmail = Read-Host "Enter mailbox email address"
    $userEmail = Read-Host "Enter user email address to remove"

    try {
        Set-Mailbox -Identity $mailboxEmail -GrantSendOnBehalfTo @{Remove=$userEmail} -ErrorAction Stop
        Write-Host "Send on Behalf removed." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to remove Send on Behalf: $($_.Exception.Message)" -ForegroundColor Red
    }

    Pause-Epsilon
}

# -----------------------------
# Inbox Rules
# -----------------------------

function List-EpsilonInboxRules {
    Show-Header "List Inbox Rules"

    if (-not (Require-EpsilonExchangeConnected)) { return }

    $emailAddress = Read-Host "Enter user's email address"

    try {
        Get-InboxRule -Mailbox $emailAddress |
            Select-Object Name, Identity, Enabled, Description |
            Format-List
    }
    catch {
        Write-Host "Failed to list inbox rules: $($_.Exception.Message)" -ForegroundColor Red
    }

    Pause-Epsilon
}

function Remove-EpsilonInboxRule {
    Show-Header "Remove Inbox Rule"

    if (-not (Require-EpsilonExchangeConnected)) { return }

    $identity = Read-Host "Enter full rule Identity"

    try {
        Remove-InboxRule -Identity $identity -Confirm:$false -ErrorAction Stop
        Write-Host "Inbox rule removed." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to remove inbox rule: $($_.Exception.Message)" -ForegroundColor Red
    }

    Pause-Epsilon
}

# -----------------------------
# Calendar Permissions
# -----------------------------

function Grant-EpsilonCalendarPermission {
    Show-Header "Grant Calendar Permission"

    if (-not (Require-EpsilonExchangeConnected)) { return }

    $mailboxEmail = Read-Host "Enter mailbox email address"
    $userEmail = Read-Host "Enter user email address receiving calendar access"
    $access = Read-Host "Enter access level, example Reviewer, Editor, Owner, AvailabilityOnly, LimitedDetails"

    $calendarPath = "$mailboxEmail`:\Calendar"

    try {
        Add-MailboxFolderPermission -Identity $calendarPath -User $userEmail -AccessRights $access -ErrorAction Stop
        Write-Host "Calendar permission granted." -ForegroundColor Green
    }
    catch {
        try {
            Set-MailboxFolderPermission -Identity $calendarPath -User $userEmail -AccessRights $access -ErrorAction Stop
            Write-Host "Existing calendar permission updated." -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to grant/update calendar permission: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Pause-Epsilon
}

function Remove-EpsilonCalendarPermission {
    Show-Header "Remove Calendar Permission"

    if (-not (Require-EpsilonExchangeConnected)) { return }

    $mailboxEmail = Read-Host "Enter mailbox email address"
    $userEmail = Read-Host "Enter user email address to remove"

    $calendarPath = "$mailboxEmail`:\Calendar"

    try {
        Remove-MailboxFolderPermission -Identity $calendarPath -User $userEmail -Confirm:$false -ErrorAction Stop
        Write-Host "Calendar permission removed." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to remove calendar permission: $($_.Exception.Message)" -ForegroundColor Red
    }

    Pause-Epsilon
}

function View-EpsilonCalendarPermissions {
    Show-Header "View Calendar Permissions"

    if (-not (Require-EpsilonExchangeConnected)) { return }

    $mailboxEmail = Read-Host "Enter mailbox email address"
    $calendarPath = "$mailboxEmail`:\Calendar"

    try {
        Get-MailboxFolderPermission -Identity $calendarPath |
            Format-Table User, AccessRights, SharingPermissionFlags -AutoSize
    }
    catch {
        Write-Host "Failed to view calendar permissions: $($_.Exception.Message)" -ForegroundColor Red
    }

    Pause-Epsilon
}

# -----------------------------
# Compliance / Purview
# -----------------------------

function Search-EpsilonComplianceBySubject {
    Show-Header "Compliance Search by Subject"

    $subject = Read-Host "Enter subject or subject keyword"
    $searchName = "EPSILON_Search_$((Get-Date).ToString('yyyyMMdd_HHmmss'))"
    $query = "subject:`"$subject`""

    try {
        New-ComplianceSearch -Name $searchName -ExchangeLocation All -ContentMatchQuery $query -ErrorAction Stop | Out-Null
        Start-ComplianceSearch -Identity $searchName -ErrorAction Stop

        Write-Host "Compliance search started." -ForegroundColor Green
        Write-Host "Search Name: $searchName"
    }
    catch {
        Write-Host "Failed to start compliance search: $($_.Exception.Message)" -ForegroundColor Red
    }

    Pause-Epsilon
}

function Get-EpsilonComplianceSearchStatus {
    Show-Header "Compliance Search Status"

    $searchName = Read-Host "Enter Compliance Search name"

    try {
        Get-ComplianceSearch -Identity $searchName |
            Select-Object Name, Status, Items, Size, CreatedTime |
            Format-List
    }
    catch {
        Write-Host "Failed to get compliance search status: $($_.Exception.Message)" -ForegroundColor Red
    }

    Pause-Epsilon
}

function Purge-EpsilonComplianceSearch {
    Show-Header "Purge Compliance Search Results"

    $searchName = Read-Host "Enter completed Compliance Search name"

    Write-Host "WARNING: This will purge matching messages from mailboxes." -ForegroundColor Red
    $confirm = Read-Host "Type PURGE to continue"

    if ($confirm -ne "PURGE") {
        Write-Host "Cancelled." -ForegroundColor Yellow
        Pause-Epsilon
        return
    }

    try {
        New-ComplianceSearchAction -SearchName $searchName -Purge -PurgeType SoftDelete -Confirm:$false -ErrorAction Stop
        Write-Host "Purge action started." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to start purge action: $($_.Exception.Message)" -ForegroundColor Red
    }

    Pause-Epsilon
}

# -----------------------------
# Menus
# -----------------------------

function Show-ExchangeUserManagementMenu {
    do {
        Show-Header "Exchange User Management"

        Write-Host "1. List Mailboxes"
        Write-Host "2. Mailbox Details"
        Write-Host "3. Enable Archive"
        Write-Host "4. Enable Auto-Expanding Archive"
        Write-Host "5. Start Managed Folder Assistant"
        Write-Host ""
        Write-Host "6. Block User Sign-In & Revoke Sessions"
        Write-Host "7. Unblock User Sign-In"
        Write-Host "8. Check User Sign-In Status"
        Write-Host "9. Revoke User Sessions"
        Write-Host "10. Show Connected Microsoft Account / Tenant"
        Write-Host ""
        Write-Host "Q. Back to Main Menu"
        Write-Host ""

        $choice = Read-Host "Select an option"

        switch ($choice.ToUpper()) {
            "1"  { List-EpsilonMailboxes }
            "2"  { Get-EpsilonMailboxDetails }
            "3"  { Enable-EpsilonArchive }
            "4"  { Enable-EpsilonAutoExpandingArchive }
            "5"  { Start-EpsilonManagedFolderAssistant }
            "6"  { Block-EpsilonUserSignIn }
            "7"  { Unblock-EpsilonUserSignIn }
            "8"  { Check-EpsilonUserSignInStatus }
            "9"  { Revoke-EpsilonUserSessionsOnly }
            "10" { Show-EpsilonGraphContext }
            "Q"  { return }
            default {
                Write-Host "Invalid selection." -ForegroundColor Yellow
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
}

function Show-DelegationMenu {
    do {
        Show-Header "Mailbox Delegation"

        Write-Host "1. Grant FullAccess"
        Write-Host "2. Remove FullAccess"
        Write-Host "3. Grant SendAs"
        Write-Host "4. Remove SendAs"
        Write-Host "5. Grant Send on Behalf"
        Write-Host "6. Remove Send on Behalf"
        Write-Host ""
        Write-Host "Q. Back to Main Menu"
        Write-Host ""

        $choice = Read-Host "Select an option"

        switch ($choice.ToUpper()) {
            "1" { Grant-EpsilonFullAccess }
            "2" { Remove-EpsilonFullAccess }
            "3" { Grant-EpsilonSendAs }
            "4" { Remove-EpsilonSendAs }
            "5" { Grant-EpsilonSendOnBehalf }
            "6" { Remove-EpsilonSendOnBehalf }
            "Q" { return }
            default {
                Write-Host "Invalid selection." -ForegroundColor Yellow
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
}

function Show-InboxRulesMenu {
    do {
        Show-Header "Inbox Rules"

        Write-Host "1. List Inbox Rules"
        Write-Host "2. Remove Inbox Rule by Identity"
        Write-Host ""
        Write-Host "Q. Back to Main Menu"
        Write-Host ""

        $choice = Read-Host "Select an option"

        switch ($choice.ToUpper()) {
            "1" { List-EpsilonInboxRules }
            "2" { Remove-EpsilonInboxRule }
            "Q" { return }
            default {
                Write-Host "Invalid selection." -ForegroundColor Yellow
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
}

function Show-CalendarMenu {
    do {
        Show-Header "Calendar Permissions"

        Write-Host "1. Grant / Update Calendar Permission"
        Write-Host "2. Remove Calendar Permission"
        Write-Host "3. View Calendar Permissions"
        Write-Host ""
        Write-Host "Q. Back to Main Menu"
        Write-Host ""

        $choice = Read-Host "Select an option"

        switch ($choice.ToUpper()) {
            "1" { Grant-EpsilonCalendarPermission }
            "2" { Remove-EpsilonCalendarPermission }
            "3" { View-EpsilonCalendarPermissions }
            "Q" { return }
            default {
                Write-Host "Invalid selection." -ForegroundColor Yellow
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
}

function Show-ComplianceMenu {
    do {
        Show-Header "Compliance / Purview"

        Write-Host "1. Search by Subject"
        Write-Host "2. Check Compliance Search Status"
        Write-Host "3. Purge Completed Search"
        Write-Host ""
        Write-Host "Q. Back to Main Menu"
        Write-Host ""

        $choice = Read-Host "Select an option"

        switch ($choice.ToUpper()) {
            "1" { Search-EpsilonComplianceBySubject }
            "2" { Get-EpsilonComplianceSearchStatus }
            "3" { Purge-EpsilonComplianceSearch }
            "Q" { return }
            default {
                Write-Host "Invalid selection." -ForegroundColor Yellow
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
}

function Show-MainMenu {
    do {
        Show-Header "Main Menu"

        $exchangeConnected = Test-EpsilonExchangeConnected

        Write-Host "1. Connect to Exchange Online"

        if ($exchangeConnected) {
            Write-Host ""
            Write-Host "Exchange Online Status: Connected" -ForegroundColor Green
            Write-Host ""
            Write-Host "2. Connect to Compliance / Purview"
            Write-Host "3. Exchange User Management"
            Write-Host "4. Mailbox Delegation"
            Write-Host "5. Inbox Rules"
            Write-Host "6. Calendar Permissions"
            Write-Host "7. Compliance / Purview"
            Write-Host ""
            Write-Host "8. Disconnect Sessions"
        }
        else {
            Write-Host ""
            Write-Host "Exchange Online Status: Not Connected" -ForegroundColor Yellow
            Write-Host "Exchange menus are hidden until you connect." -ForegroundColor Yellow
        }

        Write-Host ""
        Write-Host "Q. Quit"
        Write-Host ""

        $choice = Read-Host "Select an option"

        switch ($choice.ToUpper()) {
            "1" { Connect-EpsilonExchange }

            "2" {
                if ($exchangeConnected) { Connect-EpsilonCompliance }
                else {
                    Write-Host "Please connect to Exchange Online first." -ForegroundColor Yellow
                    Start-Sleep -Seconds 2
                }
            }

            "3" {
                if ($exchangeConnected) { Show-ExchangeUserManagementMenu }
                else {
                    Write-Host "Please connect to Exchange Online first." -ForegroundColor Yellow
                    Start-Sleep -Seconds 2
                }
            }

            "4" {
                if ($exchangeConnected) { Show-DelegationMenu }
                else {
                    Write-Host "Please connect to Exchange Online first." -ForegroundColor Yellow
                    Start-Sleep -Seconds 2
                }
            }

            "5" {
                if ($exchangeConnected) { Show-InboxRulesMenu }
                else {
                    Write-Host "Please connect to Exchange Online first." -ForegroundColor Yellow
                    Start-Sleep -Seconds 2
                }
            }

            "6" {
                if ($exchangeConnected) { Show-CalendarMenu }
                else {
                    Write-Host "Please connect to Exchange Online first." -ForegroundColor Yellow
                    Start-Sleep -Seconds 2
                }
            }

            "7" {
                if ($exchangeConnected) { Show-ComplianceMenu }
                else {
                    Write-Host "Please connect to Exchange Online first." -ForegroundColor Yellow
                    Start-Sleep -Seconds 2
                }
            }

            "8" {
                if ($exchangeConnected) { Disconnect-EpsilonSessions }
                else {
                    Write-Host "No active Exchange Online session found." -ForegroundColor Yellow
                    Start-Sleep -Seconds 2
                }
            }

            "Q" {
                Clear-Host
                Write-Host ""
                Write-Host "============================================================" -ForegroundColor Cyan
                Write-Host " EPSILON" -ForegroundColor Cyan
                Write-Host "============================================================" -ForegroundColor Cyan
                Write-Host ""
                Write-Host "Thank you for using EPSILON." -ForegroundColor Green
                Write-Host "Goodbye!" -ForegroundColor Green
                Write-Host ""
                return
            }

            default {
                Write-Host "Invalid selection." -ForegroundColor Yellow
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
}

# -----------------------------
# Start EPSILON
# -----------------------------

Show-MainMenu