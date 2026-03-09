#Requires -Version 5.1
<#
.SYNOPSIS
    Legt einen Host auf dem Zabbix Server über die API an
.DESCRIPTION
    Verwendet die Zabbix JSON-RPC API um automatisch einen Host anzulegen
.PARAMETER HostName
    Der Hostname des Clients (z.B. DE401850M00033)
.PARAMETER HostIP
    Die IP-Adresse des Clients
.PARAMETER ZabbixServer
    Zabbix Server URL
.PARAMETER ZabbixUser
    Zabbix API Benutzer
.PARAMETER ZabbixPassword
    Zabbix API Passwort
.EXAMPLE
    .\Add-ZabbixHost.ps1 -HostName "DE401850M00033" -HostIP "10.56.131.100"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$HostName,
    
    [Parameter(Mandatory=$false)]
    [string]$HostIP,
    
    [Parameter(Mandatory=$false)]
    [string]$ZabbixServer = "10.56.131.163",
    
    [Parameter(Mandatory=$false)]
    [string]$ZabbixUser = "Admin",
    
    [Parameter(Mandatory=$false)]
    [SecureString]$ZabbixPassword,
    
    [Parameter(Mandatory=$false)]
    [string]$HostGroup = "Windows clients",
    
    [Parameter(Mandatory=$false)]
    [string]$Template = "Windows by Zabbix agent active Client PC"
)

# Interaktive Eingabe falls nicht angegeben
if (-not $HostName) {
    $HostName = Read-Host "Hostname des Clients"
}

if (-not $HostIP) {
    $HostIP = Read-Host "IP-Adresse des Clients"
}

$ZabbixURL = "http://$ZabbixServer/zabbix/api_jsonrpc.php"

if (-not $ZabbixPassword) {
    # Versuche zuerst Standard-Passwort "zabbix"
    $ZabbixPassword = ConvertTo-SecureString "zabbix" -AsPlainText -Force
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ZabbixPassword)
    $ZabbixPwd = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    
    # Teste ob Passwort funktioniert
    try {
        $loginBody = @{
            jsonrpc = "2.0"
            method = "user.login"
            params = @{
                username = $ZabbixUser
                password = $ZabbixPwd
            }
            id = 1
        } | ConvertTo-Json
        
        $loginResp = Invoke-RestMethod -Uri $ZabbixURL -Method Post -Body $loginBody -ContentType "application/json" -ErrorAction Stop
        
        if ($loginResp.error) {
            # Standard-Passwort funktioniert nicht
            Write-Host "Standard-Passwort funktioniert nicht" -ForegroundColor Yellow
            $ZabbixPassword = Read-Host "Zabbix API Passwort eingeben" -AsSecureString
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ZabbixPassword)
            $ZabbixPwd = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        }
    }
    catch {
        # Fehler beim Test - frage manuell
        $ZabbixPassword = Read-Host "Zabbix API Passwort eingeben" -AsSecureString
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ZabbixPassword)
        $ZabbixPwd = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    }
}
else {
    # Passwort wurde als Parameter übergeben
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ZabbixPassword)
    $ZabbixPwd = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
}

Write-Host "`n=== ZABBIX HOST REGISTRATION ===" -ForegroundColor Cyan
Write-Host "Zabbix Server: $ZabbixServer"
Write-Host "Hostname: $HostName"
Write-Host "IP-Adresse: $HostIP"
Write-Host ""

function Invoke-ZabbixAPI {
    param(
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
        $response = Invoke-RestMethod -Uri $ZabbixURL -Method Post -Body $json -Headers $headers
        
        if ($response.error) {
            throw "Zabbix API Error: $($response.error.message) (Code: $($response.error.code))"
        }
        
        return $response.result
    }
    catch {
        Write-Host "FEHLER beim API-Aufruf: $_" -ForegroundColor Red
        throw
    }
}

try {
    # SCHRITT 1: API Login
    Write-Host "[1] Authentifiziere bei Zabbix API..." -ForegroundColor Yellow
    $authToken = Invoke-ZabbixAPI -Method "user.login" -Params @{
        username = $ZabbixUser
        password = $ZabbixPwd
    }
    Write-Host "    ✓ Login erfolgreich (Token: $($authToken.Substring(0,8))...)" -ForegroundColor Green
    
    # SCHRITT 2: Prüfe ob Host bereits existiert
    Write-Host "`n[2] Prüfe ob Host bereits existiert..." -ForegroundColor Yellow
    $existingHost = Invoke-ZabbixAPI -Method "host.get" -Auth $authToken -Params @{
        filter = @{
            host = @($HostName)
        }
    }
    
    if ($existingHost.Count -gt 0) {
        Write-Host "    ⚠ Host '$HostName' existiert bereits (ID: $($existingHost[0].hostid))" -ForegroundColor Yellow
        $hostId = $existingHost[0].hostid
        Write-Host "    Aktualisiere bestehenden Host..." -ForegroundColor Yellow
        
        # Host aktualisieren
        $updateResult = Invoke-ZabbixAPI -Method "host.update" -Auth $authToken -Params @{
            hostid = $hostId
            status = 0  # 0 = enabled
        }
        Write-Host "    ✓ Host aktualisiert" -ForegroundColor Green
    }
    else {
        Write-Host "    ✓ Host existiert noch nicht, lege neu an..." -ForegroundColor Green
        
        # SCHRITT 3: Hole Host Group ID
        Write-Host "`n[3] Suche Host-Gruppe '$HostGroup'..." -ForegroundColor Yellow
        $groups = Invoke-ZabbixAPI -Method "hostgroup.get" -Auth $authToken -Params @{
            filter = @{
                name = @($HostGroup)
            }
        }
        
        if ($groups.Count -eq 0) {
            Write-Host "    ⚠ Host-Gruppe '$HostGroup' nicht gefunden, erstelle sie..." -ForegroundColor Yellow
            $newGroup = Invoke-ZabbixAPI -Method "hostgroup.create" -Auth $authToken -Params @{
                name = $HostGroup
            }
            $groupId = $newGroup.groupids[0]
            Write-Host "    ✓ Host-Gruppe erstellt (ID: $groupId)" -ForegroundColor Green
        }
        else {
            $groupId = $groups[0].groupid
            Write-Host "    ✓ Host-Gruppe gefunden (ID: $groupId)" -ForegroundColor Green
        }
        
        # SCHRITT 4: Hole Template ID
        Write-Host "`n[4] Suche Template '$Template'..." -ForegroundColor Yellow
        $templates = Invoke-ZabbixAPI -Method "template.get" -Auth $authToken -Params @{
            filter = @{
                host = @($Template)
            }
        }
        
        if ($templates.Count -eq 0) {
            Write-Host "    ⚠ Template '$Template' nicht gefunden" -ForegroundColor Yellow
            Write-Host "    Verfügbare Templates:" -ForegroundColor Cyan
            $allTemplates = Invoke-ZabbixAPI -Method "template.get" -Auth $authToken -Params @{
                output = @("templateid", "host", "name")
                filter = @{
                    host = "*Windows*"
                }
            }
            $allTemplates | ForEach-Object { Write-Host "      - $($_.host)" }
            $templateId = $null
        }
        else {
            $templateId = $templates[0].templateid
            Write-Host "    ✓ Template gefunden (ID: $templateId)" -ForegroundColor Green
        }
        
        # SCHRITT 5: Host erstellen (OHNE Interface - Agent Active meldet sich selbst)
        Write-Host "`n[5] Erstelle Host auf Zabbix Server..." -ForegroundColor Yellow
        
        $hostParams = @{
            host = $HostName
            name = $HostName
            groups = @(
                @{ groupid = $groupId }
            )
            status = 0  # 0 = enabled, 1 = disabled
        }
        
        # Template nur hinzufügen wenn gefunden
        if ($templateId) {
            $hostParams.templates = @(
                @{ templateid = $templateId }
            )
        }
        
        $newHost = Invoke-ZabbixAPI -Method "host.create" -Auth $authToken -Params $hostParams
        $hostId = $newHost.hostids[0]
        
        Write-Host "    ✓ Host erfolgreich erstellt!" -ForegroundColor Green
        Write-Host "    Host ID: $hostId" -ForegroundColor Green
    }
    
    # SCHRITT 6: Hole Host Details
    Write-Host "`n[6] Lese Host-Details..." -ForegroundColor Yellow
    $hostDetails = Invoke-ZabbixAPI -Method "host.get" -Auth $authToken -Params @{
        hostids = $hostId
        selectInterfaces = "extend"
        selectGroups = "extend"
        selectParentTemplates = "extend"
    }
    
    Write-Host "`n=== HOST ERFOLGREICH REGISTRIERT ===" -ForegroundColor Green
    Write-Host "Host ID: $($hostDetails[0].hostid)"
    Write-Host "Hostname: $($hostDetails[0].host)"
    Write-Host "Status: $(if ($hostDetails[0].status -eq '0') { 'Enabled' } else { 'Disabled' })"
    Write-Host "Gruppen: $($hostDetails[0].groups.name -join ', ')"
    Write-Host "Templates: $($hostDetails[0].parentTemplates.name -join ', ')"
    Write-Host "Interface: $($hostDetails[0].interfaces[0].ip):$($hostDetails[0].interfaces[0].port)"
    Write-Host "`nDer Host sollte in 1-2 Minuten erste Daten empfangen!" -ForegroundColor Cyan
    
    # SCHRITT 7: Logout
    $null = Invoke-ZabbixAPI -Method "user.logout" -Auth $authToken
    
}
catch {
    Write-Host "`n✗ FEHLER: $_" -ForegroundColor Red
    exit 1
}
finally {
    # Cleanup
    if ($ZabbixPwd) {
        $ZabbixPwd = $null
    }
}
