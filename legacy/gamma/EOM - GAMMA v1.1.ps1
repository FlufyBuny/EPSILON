# Check if the ExchangeOnlineManagement module is installed, and install it if not
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host "ExchangeOnlineManagement module not found. Installing now..."
    Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber
    Import-Module ExchangeOnlineManagement
} else {
    Write-Host "ExchangeOnlineManagement module is already installed."
}

function Show-Menu {
    param (
        [string]$Title = 'Exchange Online Administration Menu (GAMMA v1.1)'
    )
    Clear-Host
    Write-Host "================ $Title ================"
    Write-Host "1: List all mailboxes"
    Write-Host "2: Get mailbox details"
    Write-Host "3: Create new mailbox"
    Write-Host "4: Delete a mailbox"
    Write-Host "5: Delegate user to a mailbox"
    Write-Host "6: Remove delegate user to a mailbox"
    Write-Host "7: Turn on Archiving for a mailbox"
    Write-Host "8: Turn on AutoExpandingArchiving for a mailbox (!00GB+ Only)"
    Write-Host "9: Start Archiving for a mailbox NOW"
    Write-Host "R: View Mailbox Rules"
    Write-Host "C: Change Global Admin"
    Write-Host "Q: Quit"
}

function Connect-ToExchangeOnline {
    Clear-Host     
    Connect-ExchangeOnline -ShowBanner:$false
}

function List-Mailboxes {
    Clear-Host
    Get-Mailbox -ResultSize Unlimited | Select DisplayName, UserPrincipalName, PrimarySmtpAddress
}

function Get-MailboxDetails {
    Clear-Host    
    $mailbox = Read-Host "Enter the email address of the mailbox"
    Get-Mailbox $mailbox | Format-List
}

function Create-Mailbox {
    Clear-Host    
    $name = Read-Host "Enter the full name"
    $password = Read-Host "Enter password" -AsSecureString
    $alias = Read-Host "Enter alias (e.g., jimbob for jimbob@bob.com)"
    $firstName = Read-Host "Enter first name"
    $lastName = Read-Host "Enter last name"
    $primarySmtpAddress = Read-Host "Enter primary SMTP address (e.g., user@domain.com)"
    New-Mailbox -Alias $alias -Name $name -FirstName $firstName -LastName $lastName -DisplayName $name -MicrosoftOnlineServicesID $primarySmtpAddress -Password $password -ResetPasswordOnNextLogon $true
    Write-Host "$mailbox Created!"
}

function Delete-Mailbox {
    Clear-Host    
    $mailbox = Read-Host "Enter the email address of the mailbox to delete"
    Remove-Mailbox -Identity $mailbox -Confirm:$false
    Write-Host "$mailbox DELETED!!!"
}

function Delegate-Access {
    Clear-Host    
    $mailbox = Read-Host "Enter the email address of the mailbox"
    $delegate = Read-Host "Enter the email address of the delegate"
    Add-MailboxPermission -Identity $mailbox -User $delegate  -AccessRights FullAccess -InheritanceType All
    Write-Host "Full Access has been given to $delegate on mailbox $mailbox"
}

function Remove-Access {
    Clear-Host    
    $mailbox = Read-Host "Enter the email address of the mailbox"
    $delegate = Read-Host "Enter the email address of the delegate"
    Remove-MailboxPermission -Identity $mailbox -User $delegate  -AccessRights FullAccess -InheritanceType All
    Write-Host "Full Access has been removed from $delegate to mailbox $mailbox"
}

function Enable-Archiving {
    Clear-Host    
    $mailbox = Read-Host "Enter the email address of the mailbox (Archive)"
    Enable-Mailbox -Identity $mailbox -Archive
    Write-Host "Archiving has been enabled for $mailbox"
}

function Enable-ExpandingArchiving {
    Clear-Host    
    $mailbox = Read-Host "Enter the email address of the mailbox to expand archive"
    Enable-Mailbox -Identity $mailbox -AutoExpandArchive
    Write-Host "AutoExpandingArchiving has been enabled for $mailbox"
}

function Configure-AutoArchiving {
    Clear-Host 
    $mailbox = Read-Host "Enter the email address of the mailbox to AutoArchive"
    Start-ManagedFolderAssistant -Identity $mailbox
    Write-Host "Auto-archiving Started NOW for $mailbox"
}

function Rules {
    Clear-Host   
    $mailbox = Read-Host "Enter the email address of the mailbox"
    Get-InboxRule -Mailbox $mailbox | Select Name, Identity, Description | fl
}

function Change-GA {
    Clear-Host
    Write-Host "Reconnecting to Exchange Online..."    
    Connect-ExchangeOnline -ShowBanner:$false
    Write-Host "Reconnected to Exchange Online."
}

# Entry point of the script
Connect-ToExchangeOnline

do {
    Show-Menu
    $input = Read-Host "Please select an option"
    switch ($input) {
        '1' { List-Mailboxes }
        '2' { Get-MailboxDetails }
        '3' { Create-Mailbox }
        '4' { Delete-Mailbox }
        '5' { Delegate-Access }
        '6' { Remove-Access }
        '7' { Enable-Archiving }
        '8' { Enable-ExpandingArchiving }
        '9' { Configure-AutoArchiving }
        'R' { Rules }
        'C' { Change-GA }
        'Q' { Clear-Host 
               Write-Host "Exiting..."; break }
        default { Write-Host "Invalid option, please try again." }
    }
    Read-Host -Prompt "Press Enter to continue"
} while ($input -ne 'Q')
