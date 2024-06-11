# Список приложений для мониторинга
$applications = @(
    @{ Path="C:\Users\NVR\Documents\PhotoNotifier\monitor.exe"; Args=""; MaxRestarts=3; MonitoringEnabled=$true; MonitoringUrl="https://uptime.ahae.ru/api/push/qB4n5jp4bh?status=up&msg=OK&ping="; MonitoringInterval=50 },
    @{ Path="C:\Program Files\Blue Iris 5\BlueIris.exe"; Args=""; MaxRestarts=3; MonitoringEnabled=$false }
)

# Инициализация счетчиков перезапуска и времени последнего мониторинга
foreach ($app in $applications) {
    $app.RestartCount = 0
    $app.LastMonitoringTime = Get-Date
}

# Функция для записи в лог-файл
function Write-Log {
    param([string]$message)
    $logPath = "C:\Users\NVR\Documents\Daemon\logs.txt"
    Add-Content -Path $logPath -Value "$(Get-Date) - $message"
}

# Функция для отправки GET запроса
function Send-MonitoringHeartbeat {
    param([string]$url, [string]$appName)
    try {
        $response = Invoke-WebRequest -Uri $url -Method Get -UseBasicParsing -OutVariable Ignore
        Write-Log "[INFO]: Monitoring heartbeat sent to $url for $appName"
    } catch {
        Write-Log "[ERROR]: Failed to send monitoring heartbeat to $url for $appName. Error: $_"
    }
}


# Бесконечный цикл для мониторинга
while ($true) {
    foreach ($app in $applications) {
        $processName = (Split-Path $app.Path -Leaf).Replace('.exe', '')
        $process = Get-Process -Name $processName -ErrorAction SilentlyContinue
        if (-not $process) {
            if ($app.RestartCount -lt $app.MaxRestarts) {
                try {
                    $workingDirectory = Split-Path $app.Path
                    Start-Process -FilePath $app.Path -WorkingDirectory $workingDirectory
                    $app.RestartCount++
                    Write-Log "[INFO]: Restarted application $($app.Path) successfully."
                } catch {
                    Write-Log "[ERROR]: Failed to start application $($app.Path). Error: $_"
                }
            } else {
                Write-Log "[WARNING]: Maximum restart attempts reached for application $($app.Path)."
            }
        } else {
            $app.RestartCount = 0
            # Проверяем, нужно ли отправлять метрику
            if ($app.MonitoringEnabled -and ((Get-Date) - $app.LastMonitoringTime).TotalSeconds -ge $app.MonitoringInterval) {
                Send-MonitoringHeartbeat -url $app.MonitoringUrl -appName $processName
                $app.LastMonitoringTime = Get-Date
            }
        }
    }
    Start-Sleep -Seconds 10
}
