$wua = New-Object -ComObject Microsoft.Update.Session
$updates = $wua.CreateupdateSearcher().Search($criteria).Updates
$count = $updates.Count
if ($count -gt 0) {
    $downloader = $wua.CreateUpdateDownloader()
    $downloader.Updates = $updates
    $downloader.Download()
    $installer = $wua.CreateUpdateInstaller()
    $installer.Updates = $updates
    $installationResult = $installer.Install()
    if ($installationResult.rebootRequired) {
        $obj = New-Object -ComObject WScript.Shell
        $null = $obj.Popup("Updates installed successfully. A reboot is required. Your computer will restart in 10 minutes. Press OK to schedule the reboot or Cancel to postpone it.", 0, "Restart Required", 0x1)
        if ($null -ne 1) {
            # Schedule a reboot in 10 minutes
            $obj = New-Object -ComObject "Schedule.Service"
            $obj.Connect()
            $task = $obj.NewTask(0)
            $task.RegistrationInfo.Description = "Scheduled Reboot"
            $taskSettings = $task.Settings
            $taskSettings.Enabled = $true
            $taskSettings.StartWhenAvailable = $true
            $trigger = $task.Triggers.Create(0)
            $trigger.StartBoundary = (Get-Date).AddMinutes(10).ToString("yyyy-MM-dd'T'HH:mm:ss")
            $trigger.Enabled = $true
            $action = $task.Actions.Create(0)
            $action.Path = "shutdown.exe"
            $action.Arguments = "/r /t 0"
            $objFolder = $obj.GetFolder("\")
            $objFolder.RegisterTaskDefinition("Scheduled Reboot", $task, 6, "System", $null, 5)
            Write-Output "Reboot scheduled in 10 minutes"
        }
        else {
            Write-Output "Reboot postponed"
        }
    }
    else {
        Write-Output "Updates installed successfully. No reboot required."
    }
}
else {
    $obj = New-Object -ComObject WScript.Shell
    $null = $obj.Popup([string]"No updates are available. Press Enter to exit.", 0, "No Updates Available", 0x0)
    Read-Host "Press Enter to exit."
}   
