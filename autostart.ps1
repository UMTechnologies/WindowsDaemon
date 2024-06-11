# Проверка запуска с правами администратора
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $scriptArguments = "-NoExit -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Definition)`" $args"

    Start-Process powershell.exe -ArgumentList $scriptArguments -Verb RunAs
    exit
}


# Указываем путь к вашему скрипту
$scriptPath = "C:\Users\NVR\Documents\Daemon\angel.ps1"
$taskName = "MonitoringAutoStart"

# Проверяем, существует ли уже такая задача
if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Write-Output "Task $taskName already configured..."
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# Создаем действие, которое будет выполнять ваш скрипт
$action = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "-NoProfile -WindowStyle Normal -File `"$scriptPath`""

# Создаем триггер на запуск при входе пользователя в систему
$trigger = New-ScheduledTaskTrigger -AtLogon

# Задаем основные параметры задачи
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive

# Регистрируем задачу в планировщике
try {
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -ErrorAction Stop
    Write-Output "Success."
} catch {
    Write-Error "Error: $_"
}
