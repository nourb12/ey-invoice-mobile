param(
  [Parameter(Mandatory = $false)]
  [string]$DeviceId = ""
)

$ErrorActionPreference = "Stop"

function Resolve-AdbPath {
  $cmd = Get-Command adb -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }

  $candidate = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
  if (Test-Path $candidate) { return $candidate }

  return $null
}

$adb = Resolve-AdbPath
if (-not $adb) {
  Write-Error "adb.exe introuvable. Installe Android SDK Platform-Tools ou ajoute adb au PATH."
  exit 1
}

$devices = & $adb devices | Select-String -Pattern "`tdevice$" | ForEach-Object {
  ($_ -split "`t")[0].Trim()
}

if (-not $devices -or $devices.Count -eq 0) {
  Write-Error "Aucun téléphone détecté. Branche le Samsung en USB + active le débogage USB."
  exit 1
}

$target = $DeviceId
if ([string]::IsNullOrWhiteSpace($target)) {
  if ($devices.Count -ne 1) {
    Write-Error ("Plusieurs devices détectés: {0}. Relance avec -DeviceId <id>." -f ($devices -join ", "))
    exit 1
  }
  $target = $devices[0]
}

Write-Host "Device: $target"
& $adb -s $target reverse tcp:5051 tcp:5051 | Out-Null
Write-Host "Reverse actif:"
& $adb -s $target reverse --list

