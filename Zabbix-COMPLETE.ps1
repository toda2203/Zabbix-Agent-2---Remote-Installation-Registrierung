#Requires -Version 5.1
<#
.SYNOPSIS
    Komplette Zabbix Agent Installation mit automatischer Host-Registrierung
.DESCRIPTION
    1. Installiert Zabbix Agent auf Remote-Client
    2. Registriert Host automatisch auf Zabbix Server via API
.PARAMETER Credential
    Domain-Credentials für Remote-Installation
.PARAMETER ZabbixAPIUser
    Zabbix API Benutzer (Standard: Admin)
.PARAMETER ZabbixAPIPassword
    Zabbix API Passwort
.PARAMETER RegisterHost
    Host automatisch auf Zabbix Server registrieren (Standard: $true)
.EXAMPLE
    .\Zabbix-COMPLETE.ps1
.EXAMPLE
    .\Zabbix-COMPLETE.ps1 -RegisterHost $false
#>

param(
    [System.Management.Automation.PSCredential]$Credential,
    
    [string]$ZabbixAPIUser = "Admin",
    
    [SecureString]$ZabbixAPIPassword,
    
    [bool]$RegisterHost = $true,
    
    [string]$HostGroup = "Windows clients",
    
    [string]$Template = "Windows by Zabbix agent active Client PC",

    [string]$ConfigPath = "$PSScriptRoot\Zabbix-Config.psd1"
)

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   ZABBIX AGENT - VOLLINSTALLATION" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# FUNKTION: Zabbix API Call (Zabbix 7.x mit Authorization Header)
function Invoke-ZabbixAPI {
    param(
        [string]$URL,
        [string]$Method,
        [hashtable]$Params,
        [string]$Auth = $null
    )
    
    $body = @{
        jsonrpc = "2.0"
        method = $Method
        params = $Params
        id = 1
    }
    
    $json = $body | ConvertTo-Json -Depth 10 -Compress
    
    $headers = @{
        "Content-Type" = "application/json-rpc"
    }
    
    if ($Auth) {
        $headers["Authorization"] = "Bearer $Auth"
    }
    
    try {
        $response = Invoke-RestMethod -Uri $URL -Method Post -Body $json -Headers $headers -ErrorAction Stop
        
        if ($response.error) {
            throw "API Error: $($response.error.message) (Code: $($response.error.code))"
        }
        
        return $response.result
    }
    catch {
        Write-Host "  API Fehler: $_" -ForegroundColor Red
        return $null
    }
}

# FUNKTION: Host auf Zabbix Server registrieren
function Register-ZabbixHost {
    param(
        [string]$ZabbixServer,
        [string]$HostName,
        [string]$HostIP,
        [string]$APIUser,
        [string]$APIPassword,
        [string]$HostGroup,
        [string]$Template
    )
    
    $apiURL = "http://$ZabbixServer/zabbix/api_jsonrpc.php"
    
    Write-Host "`n[6] Registriere Host auf Zabbix Server..." -ForegroundColor Yellow
    Write-Host "  Server: $ZabbixServer"
    Write-Host "  Hostname: $HostName"
    Write-Host "  IP: $HostIP"
    
    $authToken = $null
    
    # Login
    Write-Host "  [6a] API Login..." -ForegroundColor Gray
    $authToken = Invoke-ZabbixAPI -URL $apiURL -Method "user.login" -Params @{
        username = $APIUser
        password = $APIPassword
    }
    
    if (-not $authToken) {
        Write-Host "  ✗ Login fehlgeschlagen!" -ForegroundColor Red
        return $false
    }
    Write-Host "      ✓ Login erfolgreich" -ForegroundColor Green
    
    # Prüfe ob Host existiert
    Write-Host "  [6b] Prüfe ob Host existiert..." -ForegroundColor Gray
    $existingHost = Invoke-ZabbixAPI -URL $apiURL -Method "host.get" -Auth $authToken -Params @{
        filter = @{ host = @($HostName) }
    }
    
    if ($existingHost -and $existingHost.Count -gt 0) {
        Write-Host "      ⚠ Host existiert bereits (ID: $($existingHost[0].hostid))" -ForegroundColor Yellow
        Write-Host "      Aktualisiere Host-Status..." -ForegroundColor Gray
        
        $null = Invoke-ZabbixAPI -URL $apiURL -Method "host.update" -Auth $authToken -Params @{
            hostid = $existingHost[0].hostid
            status = 0
        }
        Write-Host "      ✓ Host reaktiviert" -ForegroundColor Green
        
        $null = Invoke-ZabbixAPI -URL $apiURL -Method "user.logout" -Auth $authToken
        Write-Host "  OK - Host auf Zabbix Server registriert!" -ForegroundColor Green
        return $true
    }
    
    # Hole/Erstelle Host Group
    Write-Host "  [6c] Suche Host-Gruppe '$HostGroup'..." -ForegroundColor Gray
    $groups = Invoke-ZabbixAPI -URL $apiURL -Method "hostgroup.get" -Auth $authToken -Params @{
        filter = @{ name = @($HostGroup) }
    }
    
    $groupId = $null
    if (-not $groups -or $groups.Count -eq 0) {
        Write-Host "      Host-Gruppe nicht gefunden, erstelle..." -ForegroundColor Gray
        $newGroup = Invoke-ZabbixAPI -URL $apiURL -Method "hostgroup.create" -Auth $authToken -Params @{
            name = $HostGroup
        }
        $groupId = $newGroup.groupids[0]
        Write-Host "      ✓ Host-Gruppe erstellt (ID: $groupId)" -ForegroundColor Green
    }
    else {
        $groupId = $groups[0].groupid
        Write-Host "      ✓ Host-Gruppe gefunden (ID: $groupId)" -ForegroundColor Green
    }
    
    # Hole Template (optional)
    Write-Host "  [6d] Suche Template '$Template'..." -ForegroundColor Gray
    $templates = Invoke-ZabbixAPI -URL $apiURL -Method "template.get" -Auth $authToken -Params @{
        filter = @{ host = @($Template) }
    }
    
    $templateId = $null
    if ($templates -and $templates.Count -gt 0) {
        $templateId = $templates[0].templateid
        Write-Host "      ✓ Template gefunden (ID: $templateId)" -ForegroundColor Green
    }
    else {
        Write-Host "      ⚠ Template nicht gefunden (wird übersprungen)" -ForegroundColor Yellow
    }
    
    # Erstelle Host (OHNE Interface - Agent Active meldet sich selbst)
    Write-Host "  [6e] Erstelle Host..." -ForegroundColor Gray
    
    $hostParams = @{
        host = $HostName
        name = $HostName
        groups = @( @{ groupid = $groupId } )
        status = 0
    }
    
    if ($templateId) {
        $hostParams.templates = @( @{ templateid = $templateId } )
    }
    
    $newHost = Invoke-ZabbixAPI -URL $apiURL -Method "host.create" -Auth $authToken -Params $hostParams
    
    if ($newHost -and $newHost.hostids) {
        Write-Host "      ✓ Host erfolgreich erstellt (ID: $($newHost.hostids[0]))" -ForegroundColor Green
    }
    else {
        Write-Host "      ✗ Host-Erstellung fehlgeschlagen" -ForegroundColor Red
        $null = Invoke-ZabbixAPI -URL $apiURL -Method "user.logout" -Auth $authToken
        return $false
    }
    
    # Logout
    $null = Invoke-ZabbixAPI -URL $apiURL -Method "user.logout" -Auth $authToken
    
    Write-Host "  OK - Host auf Zabbix Server registriert!" -ForegroundColor Green
    return $true
}

function Convert-SecureStringToPlainText {
    param([SecureString]$SecureValue)

    if (-not $SecureValue) {
        return $null
    }

    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureValue)
    try {
        return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    }
    finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

function Test-RemoteWinRMPrereq {
    param([string]$ComputerName)

    $result = @{
        Computer = $ComputerName
        DnsOk = $false
        ResolvedIP = $null
        Port5985 = $false
        Ready = $false
        Error = $null
    }

    try {
        $dns = Resolve-DnsName -Name $ComputerName -ErrorAction Stop | Where-Object { $_.Type -eq 'A' } | Select-Object -First 1
        if ($dns) {
            $result.DnsOk = $true
            $result.ResolvedIP = $dns.IPAddress
        }
    }
    catch {
        $result.Error = "DNS-Aufloesung fehlgeschlagen"
        return $result
    }

    try {
        $tnc = Test-NetConnection -ComputerName $ComputerName -Port 5985 -WarningAction SilentlyContinue
        $result.Port5985 = [bool]$tnc.TcpTestSucceeded
        if (-not $result.Port5985) {
            $result.Error = "Port 5985 nicht erreichbar"
            return $result
        }
    }
    catch {
        $result.Error = "Port-Test fehlgeschlagen"
        return $result
    }

    $result.Ready = $true
    return $result
}

# ============================================
# HAUPTSKRIPT
# ============================================

# Konfiguration laden
$config = @{}
if (Test-Path $ConfigPath) {
    try {
        $config = Import-PowerShellDataFile -Path $ConfigPath
        Write-Host "Konfiguration geladen: $ConfigPath" -ForegroundColor Green
    }
    catch {
        Write-Host "Warnung: Konfigurationsdatei konnte nicht gelesen werden: $ConfigPath" -ForegroundColor Yellow
    }
}
else {
    Write-Host "Hinweis: Keine Konfigurationsdatei gefunden ($ConfigPath), nutze Standardwerte." -ForegroundColor Yellow
}

$DomainName = if ($config.ContainsKey("Domain")) { $config.Domain } else { "de401850" }
$DomainAdminUser = if ($config.ContainsKey("DomainAdminUser")) { $config.DomainAdminUser } else { "admin.dt" }
$DomainPasswordFromConfig = if ($config.ContainsKey("DomainPassword")) { $config.DomainPassword } else { $null }

$DomainUserName = if ([string]::IsNullOrWhiteSpace($DomainName)) { $DomainAdminUser } else { "$DomainName\$DomainAdminUser" }

if ($config.ContainsKey("ZabbixApiUser") -and -not [string]::IsNullOrWhiteSpace($config.ZabbixApiUser)) {
    $ZabbixAPIUser = $config.ZabbixApiUser
}

if (-not $ZabbixAPIPassword -and $config.ContainsKey("ZabbixApiPassword") -and -not [string]::IsNullOrWhiteSpace($config.ZabbixApiPassword)) {
    $ZabbixAPIPassword = ConvertTo-SecureString -String $config.ZabbixApiPassword -AsPlainText -Force
}

$Server = if ($config.ContainsKey("ZabbixServer") -and -not [string]::IsNullOrWhiteSpace($config.ZabbixServer)) { $config.ZabbixServer } else { "10.56.131.163" }
$MSI = if ($config.ContainsKey("MsiPath") -and -not [string]::IsNullOrWhiteSpace($config.MsiPath)) { $config.MsiPath } else { "\\bsserver\GROUPS\Ordner-Transfer\Installation\zabbix_agent.msi" }

# Credentials abfragen
if (-not $Credential) {
    if (-not [string]::IsNullOrWhiteSpace($DomainPasswordFromConfig)) {
        $credSecurePwd = ConvertTo-SecureString -String $DomainPasswordFromConfig -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential($DomainUserName, $credSecurePwd)
        Write-Host "Domain-Credentials aus Konfigurationsdatei geladen." -ForegroundColor Green
    }
    else {
        Write-Host "Domain-Credentials eingeben:" -ForegroundColor Yellow
        $Credential = Get-Credential -UserName $DomainUserName
    }
}

# Computername abfragen
Write-Host "Eingabe:" -ForegroundColor Yellow
$Computer = Read-Host "Computername (z.B. DE401850M00033)"
if (-not $Computer) {
    Write-Host "Fehler: Computername erforderlich!" -ForegroundColor Red
    exit 1
}

# Zabbix API Passwort (falls Host registriert werden soll)
$ZabbixAPIPwd = $null
if ($RegisterHost) {
    if ($ZabbixAPIPassword) {
        $ZabbixAPIPwd = Convert-SecureStringToPlainText -SecureValue $ZabbixAPIPassword
    }
    else {
        # Versuche zuerst Standard-Passwort
        $ZabbixAPIPwd = "zabbix"
        Write-Host "`nTeste Zabbix API mit Standard-Passwort..." -ForegroundColor Gray

        try {
            $loginBody = @{
                jsonrpc = "2.0"
                method = "user.login"
                params = @{
                    username = $ZabbixAPIUser
                    password = $ZabbixAPIPwd
                }
                id = 1
            } | ConvertTo-Json

            $loginResp = Invoke-RestMethod -Uri "http://$Server/zabbix/api_jsonrpc.php" -Method Post -Body $loginBody -ContentType "application/json" -ErrorAction Stop

            if ($loginResp.error) {
                Write-Host "Standard-Passwort funktioniert nicht, frage manuell..." -ForegroundColor Yellow
                $ZabbixAPIPassword = Read-Host "Zabbix API Passwort für '$ZabbixAPIUser'" -AsSecureString
                $ZabbixAPIPwd = Convert-SecureStringToPlainText -SecureValue $ZabbixAPIPassword
            }
        }
        catch {
            Write-Host "Fehler bei Test: frage manuell nach Passwort..." -ForegroundColor Yellow
            $ZabbixAPIPassword = Read-Host "Zabbix API Passwort für '$ZabbixAPIUser'" -AsSecureString
            $ZabbixAPIPwd = Convert-SecureStringToPlainText -SecureValue $ZabbixAPIPassword
        }
    }
}

Write-Host ""
Write-Host "Konfiguration:" -ForegroundColor Cyan
Write-Host "  Computer: $Computer"
Write-Host "  Zabbix Server: $Server"
Write-Host "  MSI: $MSI"
Write-Host "  Host registrieren: $(if ($RegisterHost) {'Ja'} else {'Nein'})"
Write-Host ""

$HostIP = $null

try {
    $session = $null

    # PRECHECK: DNS + WinRM Port
    Write-Host "[0] Prüfe Erreichbarkeit/WinRM..." -ForegroundColor Yellow
    $precheck = Test-RemoteWinRMPrereq -ComputerName $Computer
    if (-not $precheck.DnsOk) {
        throw "Precheck fehlgeschlagen: DNS-Aufloesung fuer '$Computer' nicht moeglich."
    }
    Write-Host "  DNS: OK ($($precheck.ResolvedIP))" -ForegroundColor Gray

    if (-not $precheck.Port5985) {
        throw "Precheck fehlgeschlagen: WinRM Port 5985 auf '$Computer' nicht erreichbar."
    }
    Write-Host "  WinRM Port 5985: OK" -ForegroundColor Gray

    # SCHRITT 1: Verbinden
    Write-Host "[1] Verbinde zu $Computer..." -ForegroundColor Yellow
    $session = New-PSSession -ComputerName $Computer -Credential $Credential -ErrorAction Stop
    Write-Host "  OK" -ForegroundColor Green
    
    # Hole IP-Adresse für API-Registrierung
    if ($RegisterHost) {
        $HostIP = Invoke-Command -Session $session -ScriptBlock {
            (Get-NetIPAddress -AddressFamily IPv4 | 
                Where-Object { $_.IPAddress -notmatch '^127\.' -and $_.IPAddress -notmatch '^169\.254\.' } | 
                Select-Object -First 1).IPAddress
        }
        Write-Host "  IP-Adresse: $HostIP" -ForegroundColor Gray
    }
    
    # SCHRITT 2: Cleanup
    Write-Host "[2] Räume auf..." -ForegroundColor Yellow
    
    Invoke-Command -Session $session -ScriptBlock {
        Get-Service -Name "*zabbix*" -ErrorAction SilentlyContinue | 
            ForEach-Object { Stop-Service -Name $_.Name -Force -ErrorAction SilentlyContinue }
        
        Start-Sleep -Seconds 2
        
        # Registry-basierte Deinstallation
        $regPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
        $zabbixInstalls = Get-ChildItem $regPath -ErrorAction SilentlyContinue | 
            Where-Object { $_.GetValue("DisplayName") -like "*Zabbix*" }
        
        if ($zabbixInstalls.Count -gt 0) {
            foreach ($install in $zabbixInstalls) {
                & msiexec.exe /x $install.PSChildName /qn | Out-Null
            }
            Start-Sleep -Seconds 5
        }
        
        New-Item -Path "C:\Temp" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
        Remove-Item "C:\Temp\zabbix_*" -Force -Recurse -ErrorAction SilentlyContinue
    }
    
    Write-Host "  OK" -ForegroundColor Green
    
    # SCHRITT 3: MSI kopieren
    Write-Host "[3] Kopiere MSI..." -ForegroundColor Yellow
    Copy-Item -Path $MSI -Destination "\\$Computer\C`$\Temp\zabbix_agent.msi" -Force
    Write-Host "  OK" -ForegroundColor Green
    
    # SCHRITT 4: Installation
    Write-Host "[4] Installiere Zabbix Agent..." -ForegroundColor Yellow
    
    $result = Invoke-Command -Session $session -ScriptBlock {
        param([string]$ZabbixServer)
        
        $msi = "C:\Temp\zabbix_agent.msi"
        $logPath = "C:\Temp\zabbix_install.log"
        
        $args = @(
            "/i", "`"$msi`"",
            "/qn",
            "/norestart",
            "/l*v", "`"$logPath`"",
            "SERVER=$ZabbixServer",
            "SERVERACTIVE=$ZabbixServer"
        )
        
        $proc = Start-Process -FilePath "msiexec.exe" -ArgumentList $args -Wait -PassThru -NoNewWindow
        
        return @{
            Code = $proc.ExitCode
            LogPath = $logPath
        }
    } -ArgumentList $Server
    
    if ($result.Code -ne 0) {
        Write-Host "  FEHLER: Exit Code $($result.Code)" -ForegroundColor Red
        throw "Installation fehlgeschlagen"
    }
    
    Write-Host "  OK - Installation erfolgreich" -ForegroundColor Green
    
    # SCHRITT 4b: Config anpassen
    Write-Host "[4b] Konfiguriere HostnameItem..." -ForegroundColor Yellow
    
    Invoke-Command -Session $session -ScriptBlock {
        Start-Sleep -Seconds 2
        
        $confPaths = @(
            "C:\Program Files\Zabbix Agent\zabbix_agentd.conf",
            "C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf",
            "C:\ProgramData\Zabbix Agent\zabbix_agentd.conf"
        )
        
        $confPath = $confPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
        
        if ($confPath) {
            Copy-Item $confPath "$confPath.bak" -Force -ErrorAction SilentlyContinue
            
            $config = Get-Content $confPath
            $newConfig = $config | Where-Object { $_ -notmatch "^Hostname=" -and $_ -notmatch "^HostnameItem=" }
            $newConfig += ""
            $newConfig += "# Dynamischer Hostname"
            $newConfig += "HostnameItem=system.hostname"
            
            $newConfig | Set-Content $confPath
        }
    }
    
    Write-Host "  OK" -ForegroundColor Green
    
    # SCHRITT 5: Service starten
    Write-Host "[5] Starte Service..." -ForegroundColor Yellow
    
    $svcStatus = Invoke-Command -Session $session -ScriptBlock {
        Start-Sleep -Seconds 3
        
        $svc = Get-Service -Name "*zabbix*" -ErrorAction SilentlyContinue | Select-Object -First 1
        
        if ($svc) {
            Set-Service -Name $svc.Name -StartupType Automatic -ErrorAction SilentlyContinue
            Start-Service -Name $svc.Name -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            
            $updatedSvc = Get-Service -Name $svc.Name
            return @{
                Name = $updatedSvc.Name
                Status = $updatedSvc.Status
            }
        }
        
        return @{ Name = "NOT_FOUND"; Status = "NOT_FOUND" }
    }
    
    if ($svcStatus.Status -eq "NOT_FOUND") {
        Write-Host "  WARNUNG: Service nicht gefunden!" -ForegroundColor Yellow
    } else {
        Write-Host "  OK - Service '$($svcStatus.Name)' läuft" -ForegroundColor Green
    }
    
    Remove-PSSession $session
    
    # SCHRITT 6: Host auf Zabbix Server registrieren (optional)
    if ($RegisterHost -and $HostIP -and $ZabbixAPIPwd) {
        $registered = Register-ZabbixHost -ZabbixServer $Server `
                                          -HostName $Computer `
                                          -HostIP $HostIP `
                                          -APIUser $ZabbixAPIUser `
                                          -APIPassword $ZabbixAPIPwd `
                                          -HostGroup $HostGroup `
                                          -Template $Template
        
        if (-not $registered) {
            Write-Host "  ⚠ Host-Registrierung fehlgeschlagen (Agent läuft aber)" -ForegroundColor Yellow
        }
    }
    elseif ($RegisterHost) {
        Write-Host "`n[6] Host-Registrierung übersprungen (API-Credentials fehlen)" -ForegroundColor Yellow
    }
    
    # ERFOLG
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "   INSTALLATION ERFOLGREICH!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Computer: $Computer" -ForegroundColor Gray
    Write-Host "IP: $HostIP" -ForegroundColor Gray
    Write-Host "Zabbix Server: $Server" -ForegroundColor Gray
    if ($svcStatus.Status -ne "NOT_FOUND") {
        Write-Host "Service: $($svcStatus.Name) - $($svcStatus.Status)" -ForegroundColor Gray
    }
    if ($RegisterHost -and $registered) {
        Write-Host "Zabbix Host: Registriert als '$Computer'" -ForegroundColor Green
    }
    Write-Host ""
    Write-Host "Der Agent sollte in 1-2 Minuten erste Daten senden!" -ForegroundColor Cyan
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "FEHLER: $_" -ForegroundColor Red
    Write-Host ""
    
    # Prüfe ob es ein WinRM/Remoting-Fehler ist
    if ($_ -match "WinRM|remote" -or $_ -match "PSRemoting|Connecting") {
        Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Yellow
        Write-Host "⚠  WINRM / POWERSHELL REMOTING NICHT AKTIVIERT" -ForegroundColor Yellow
        Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Lösung:" -ForegroundColor Cyan
        Write-Host "  1. Führe LOKAL auf dem Client aus (als Administrator):" -ForegroundColor Cyan
        Write-Host ""
        Write-Host '     powershell -Command "Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force; & '"'"'C:\Temp\Zabbix-PrepareClient.ps1'"'"'"' -ForegroundColor White
        Write-Host ""
        Write-Host "  2. Oder kurz:" -ForegroundColor Cyan
        Write-Host "     cd C:\Temp" -ForegroundColor White
        Write-Host "     .\Zabbix-PrepareClient.ps1" -ForegroundColor White
        Write-Host ""
        Write-Host "  3. Dann erneut versuchen:" -ForegroundColor Cyan
        Write-Host "     .\Zabbix-COMPLETE.ps1" -ForegroundColor White
        Write-Host ""
        Write-Host "Mit dem Prep-Script wird aktiviert:" -ForegroundColor Gray
        Write-Host "  ✓ Enable-PSRemoting" -ForegroundColor Gray
        Write-Host "  ✓ Windows Firewall (WinRM)" -ForegroundColor Gray
        Write-Host "  ✓ WinRM Service Start" -ForegroundColor Gray
        Write-Host "  ✓ Vertrauenswürdige Hosts konfiguriert" -ForegroundColor Gray
        Write-Host ""
        Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Yellow
    }
    
    if ($session) {
        Remove-PSSession $session -ErrorAction SilentlyContinue
    }
    exit 1
}
finally {
    # Cleanup
    if ($ZabbixAPIPwd) {
        $ZabbixAPIPwd = $null
    }
}
