if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $scriptArguments = "-NoExit -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Definition)`" $args"

    Start-Process powershell.exe -ArgumentList $scriptArguments -Verb RunAs
    exit
}

# Имя задачи в Планировщике задач
$taskName = "MonitoringAutoStart"

# Проверка на наличие задачи и её удаление
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host "Task '$taskName' has been removed."
} else {
    Write-Host "No task named '$taskName' was found."
}

# Очистка файла лога
$logFilePath = Join-Path -Path $PSScriptRoot -ChildPath "logs.txt"
if (Test-Path $logFilePath) {
    Clear-Content -Path $logFilePath
    Write-Host "Log file has been cleared."
} else {
    Write-Host "Log file not found."
}
