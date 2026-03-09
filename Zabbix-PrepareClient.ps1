#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Aktiviert PowerShell Remoting auf dem Client für Zabbix Agent Installation
.DESCRIPTION
    VORBEREITUNG: Aktiviert WinRM auf dem lokalen Computer
    
    WICHTIG: Dieses Script MUSS auf jedem Client lokal als Administrator ausgeführt werden!
    
    Danach können Remote-Installationen via .\Zabbix-COMPLETE.ps1 durchgeführt werden
    
.EXAMPLE
    # Lokal auf dem Client ausführen:
    powershell -Command "Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force; & 'C:\Temp\Zabbix-PrepareClient.ps1'"
    
    # Oder direkt im Terminal:
    .\Zabbix-PrepareClient.ps1
#>

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  ZABBIX CLIENT VORBEREITUNG - WINRM AKTIVIEREN         ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Prüfe ob Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "FEHLER: Dieses Script muss als Administrator ausgeführt werden!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Ausführung:" -ForegroundColor Yellow
    Write-Host "  powershell -Command `"Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force; & '$($MyInvocation.MyCommand.Path)'`"" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

Write-Host "✓ Läuft mit Administrator-Rechten`n" -ForegroundColor Green

# Schritt 1: WinRM prüfen
Write-Host "[1] Prüfe WinRM Status..." -ForegroundColor Yellow
$winrmStatus = Get-Service WinRM -ErrorAction SilentlyContinue
if ($winrmStatus) {
    Write-Host "    Service WinRM existiert: $($winrmStatus.Status)" -ForegroundColor Gray
}
else {
    Write-Host "    Service WinRM nicht gefunden" -ForegroundColor Red
}

# Schritt 2: Enable-PSRemoting
Write-Host ""
Write-Host "[2] Aktiviere PowerShell Remoting..." -ForegroundColor Yellow
try {
    Enable-PSRemoting -Force -ErrorAction Stop
    Write-Host "    ✓ PSRemoting aktiviert" -ForegroundColor Green
}
catch {
    Write-Host "    FEHLER: $_" -ForegroundColor Red
    exit 1
}

# Schritt 3: Firewall erlauben
Write-Host ""
Write-Host "[3] Konfiguriere Windows Firewall..." -ForegroundColor Yellow
try {
    # Windows Defender Firewall - WinRM HTTP
    $fwRule = Get-NetFirewallRule -DisplayName "Windows Remote Management (HTTP-In)" -ErrorAction SilentlyContinue
    if ($fwRule) {
        if ($fwRule.Enabled -eq $false) {
            Set-NetFirewallRule -DisplayName "Windows Remote Management (HTTP-In)" -Enabled $true
            Write-Host "    ✓ WinRM HTTP Firewall-Regel aktiviert" -ForegroundColor Green
        }
        else {
            Write-Host "    ✓ WinRM HTTP Firewall-Regel bereits aktiviert" -ForegroundColor Green
        }
    }
    else {
        Write-Host "    ⚠ WinRM HTTP Firewall-Regel nicht gefunden (optional)" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "    ⚠ Firewall-Fehler: $_" -ForegroundColor Yellow
}

# Schritt 4: WinRM starten und aktivieren
Write-Host ""
Write-Host "[4] Starte WinRM Service..." -ForegroundColor Yellow
try {
    if ((Get-Service WinRM).Status -ne 'Running') {
        Start-Service WinRM
        Write-Host "    ✓ WinRM Service gestartet" -ForegroundColor Green
    }
    else {
        Write-Host "    ✓ WinRM Service läuft bereits" -ForegroundColor Green
    }
    
    # Service auf automatischer Start setzen
    Set-Service -Name WinRM -StartupType Automatic
    Write-Host "    ✓ WinRM: Automatischer Start aktiviert" -ForegroundColor Green
}
catch {
    Write-Host "    FEHLER: $_" -ForegroundColor Red
    exit 1
}

# Schritt 5: Listener prüfen
Write-Host ""
Write-Host "[5] Prüfe WinRM Listener..." -ForegroundColor Yellow
try {
    $listeners = Get-WSManInstance winrm/config/Listener -Enumerate -ErrorAction SilentlyContinue
    if ($listeners) {
        Write-Host "    ✓ WinRM Listener sind konfiguriert:" -ForegroundColor Green
        $listeners | ForEach-Object {
            Write-Host "      - $($_.Transport) auf Port $($_.Port)" -ForegroundColor Cyan
        }
    }
    else {
        Write-Host "    ⚠ Keine Listener konfiguriert (wird automatisch aktiviert)" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "    ⚠ Konnte Listener nicht prüfen (optional): $_" -ForegroundColor Yellow
}

# Schritt 6: Vertrauenswürdige Hosts
Write-Host ""
Write-Host "[6] Konfiguriere vertrauenswürdige Hosts..." -ForegroundColor Yellow
try {
    $trustedHosts = (Get-Item WSMan:\localhost\Client\TrustedHosts).Value
    if ($trustedHosts -notlike "*") {
        Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force
        Write-Host "    ✓ Alle Hosts als vertrauenswürdig markiert" -ForegroundColor Green
    }
    else {
        Write-Host "    ✓ Vertrauenswürdige Hosts bereits konfiguriert" -ForegroundColor Green
    }
}
catch {
    Write-Host "    ⚠ Fehler bei TrustedHosts: $_" -ForegroundColor Yellow
}

# Erfolgreicher Abschluss
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║         VORBEREITUNG ABGESCHLOSSEN ✓                   ║" -ForegroundColor Green
Write-Host "╠════════════════════════════════════════════════════════╣" -ForegroundColor Green
Write-Host "║                                                        ║" -ForegroundColor Green
Write-Host "║  Dieser Computer ist jetzt bereit für Remote-Zugriff!  ║" -ForegroundColor Green
Write-Host "║                                                        ║" -ForegroundColor Green
Write-Host "║  Nächster Schritt:                                    ║" -ForegroundColor Green
Write-Host "║  .\Zabbix-COMPLETE.ps1 auf dem Management-Computer   ║" -ForegroundColor Green
Write-Host "║                                                        ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
