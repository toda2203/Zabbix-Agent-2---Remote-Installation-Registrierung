#Requires -Version 5.1
<#
.SYNOPSIS
    Zabbix Agent Installation - GUI Frontend
.DESCRIPTION
    Grafische Oberfläche für Installation und Registrierung von Zabbix Agent
    Nutzt Windows Forms für benutzerfreundliche Eingabe
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ============================================
# WINDOW SETUP
# ============================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "Zabbix Agent 2 - Installation und Registrierung"
$form.Width = 600
$form.Height = 750
$form.StartPosition = "CenterScreen"
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$form.BackColor = [System.Drawing.Color]::White

# Icon
try {
    $form.Icon = [System.Drawing.SystemIcons]::Application
} catch {}

# ============================================
# LABELS
# ============================================
$y = 15

# Title
$labelTitle = New-Object System.Windows.Forms.Label
$labelTitle.Text = "Zabbix Agent Installation"
$labelTitle.Location = New-Object System.Drawing.Point(15, $y)
$labelTitle.Size = New-Object System.Drawing.Size(550, 25)
$labelTitle.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$labelTitle.ForeColor = [System.Drawing.Color]::DarkBlue
$form.Controls.Add($labelTitle)
$y += 35

# ============================================
# SECTION: DOMAIN CREDENTIALS
# ============================================
$groupDomain = New-Object System.Windows.Forms.GroupBox
$groupDomain.Text = "Domain Credentials (de401850\admin.dt)"
$groupDomain.Location = New-Object System.Drawing.Point(15, $y)
$groupDomain.Size = New-Object System.Drawing.Size(555, 95)
$form.Controls.Add($groupDomain)

$labelDomainUser = New-Object System.Windows.Forms.Label
$labelDomainUser.Text = "Passwort:"
$labelDomainUser.Location = New-Object System.Drawing.Point(15, 25)
$labelDomainUser.Size = New-Object System.Drawing.Size(100, 20)
$groupDomain.Controls.Add($labelDomainUser)

$textDomainPwd = New-Object System.Windows.Forms.TextBox
$textDomainPwd.Location = New-Object System.Drawing.Point(120, 25)
$textDomainPwd.Size = New-Object System.Drawing.Size(410, 25)
$textDomainPwd.PasswordChar = '*'
$groupDomain.Controls.Add($textDomainPwd)

$labelDomainInfo = New-Object System.Windows.Forms.Label
$labelDomainInfo.Text = "> Benutzer: de401850\admin.dt"
$labelDomainInfo.Location = New-Object System.Drawing.Point(15, 55)
$labelDomainInfo.Size = New-Object System.Drawing.Size(520, 30)
$labelDomainInfo.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$labelDomainInfo.ForeColor = [System.Drawing.Color]::Gray
$groupDomain.Controls.Add($labelDomainInfo)

$y += 110

# ============================================
# SECTION: CLIENT INFORMATION
# ============================================
$groupClient = New-Object System.Windows.Forms.GroupBox
$groupClient.Text = "Ziel-Computer"
$groupClient.Location = New-Object System.Drawing.Point(15, $y)
$groupClient.Size = New-Object System.Drawing.Size(555, 75)
$form.Controls.Add($groupClient)

$labelComputerName = New-Object System.Windows.Forms.Label
$labelComputerName.Text = "Computername:"
$labelComputerName.Location = New-Object System.Drawing.Point(15, 25)
$labelComputerName.Size = New-Object System.Drawing.Size(100, 20)
$groupClient.Controls.Add($labelComputerName)

$textComputerName = New-Object System.Windows.Forms.TextBox
$textComputerName.Location = New-Object System.Drawing.Point(120, 25)
$textComputerName.Size = New-Object System.Drawing.Size(410, 25)
$textComputerName.Text = "DE401850M00023"
$groupClient.Controls.Add($textComputerName)

$labelComputerInfo = New-Object System.Windows.Forms.Label
$labelComputerInfo.Text = "> z.B. DE401850C00034, DE401850M00023, DE401850M00033"
$labelComputerInfo.Location = New-Object System.Drawing.Point(15, 50)
$labelComputerInfo.Size = New-Object System.Drawing.Size(520, 20)
$labelComputerInfo.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$labelComputerInfo.ForeColor = [System.Drawing.Color]::Gray
$groupClient.Controls.Add($labelComputerInfo)

$y += 95

# ============================================
# SECTION: ZABBIX CONFIGURATION
# ============================================
$groupZabbix = New-Object System.Windows.Forms.GroupBox
$groupZabbix.Text = "Zabbix Server (Standard: 10.56.131.163)"
$groupZabbix.Location = New-Object System.Drawing.Point(15, $y)
$groupZabbix.Size = New-Object System.Drawing.Size(555, 120)
$form.Controls.Add($groupZabbix)

$labelZabbixServer = New-Object System.Windows.Forms.Label
$labelZabbixServer.Text = "Server:"
$labelZabbixServer.Location = New-Object System.Drawing.Point(15, 25)
$labelZabbixServer.Size = New-Object System.Drawing.Size(100, 20)
$groupZabbix.Controls.Add($labelZabbixServer)

$textZabbixServer = New-Object System.Windows.Forms.TextBox
$textZabbixServer.Location = New-Object System.Drawing.Point(120, 25)
$textZabbixServer.Size = New-Object System.Drawing.Size(410, 25)
$textZabbixServer.Text = "10.56.131.163"
$groupZabbix.Controls.Add($textZabbixServer)

$labelZabbixUser = New-Object System.Windows.Forms.Label
$labelZabbixUser.Text = "Admin:"
$labelZabbixUser.Location = New-Object System.Drawing.Point(15, 53)
$labelZabbixUser.Size = New-Object System.Drawing.Size(100, 20)
$groupZabbix.Controls.Add($labelZabbixUser)

$textZabbixUser = New-Object System.Windows.Forms.TextBox
$textZabbixUser.Location = New-Object System.Drawing.Point(120, 53)
$textZabbixUser.Size = New-Object System.Drawing.Size(410, 25)
$textZabbixUser.Text = "Admin"
$textZabbixUser.Enabled = $false
$groupZabbix.Controls.Add($textZabbixUser)

$labelZabbixPwd = New-Object System.Windows.Forms.Label
$labelZabbixPwd.Text = "Passwort:"
$labelZabbixPwd.Location = New-Object System.Drawing.Point(15, 81)
$labelZabbixPwd.Size = New-Object System.Drawing.Size(100, 20)
$groupZabbix.Controls.Add($labelZabbixPwd)

$textZabbixPwd = New-Object System.Windows.Forms.TextBox
$textZabbixPwd.Location = New-Object System.Drawing.Point(120, 81)
$textZabbixPwd.Size = New-Object System.Drawing.Size(410, 25)
$textZabbixPwd.PasswordChar = '*'
$textZabbixPwd.Text = "zabbix"
$groupZabbix.Controls.Add($textZabbixPwd)

$y += 140

# ============================================
# STATUS / LOG OUTPUT
# ============================================
$groupStatus = New-Object System.Windows.Forms.GroupBox
$groupStatus.Text = "Status / Protokoll"
$groupStatus.Location = New-Object System.Drawing.Point(15, $y)
$groupStatus.Size = New-Object System.Drawing.Size(555, 180)
$form.Controls.Add($groupStatus)

$textStatus = New-Object System.Windows.Forms.RichTextBox
$textStatus.Location = New-Object System.Drawing.Point(10, 20)
$textStatus.Size = New-Object System.Drawing.Size(535, 150)
$textStatus.ReadOnly = $true
$textStatus.Font = New-Object System.Drawing.Font("Courier New", 9)
$textStatus.BackColor = [System.Drawing.Color]::WhiteSmoke
$groupStatus.Controls.Add($textStatus)

$y += 200

# ============================================
# BUTTONS
# ============================================
$buttonInstall = New-Object System.Windows.Forms.Button
$buttonInstall.Text = "[>] Installation starten"
$buttonInstall.Location = New-Object System.Drawing.Point(15, $y)
$buttonInstall.Size = New-Object System.Drawing.Size(180, 40)
$buttonInstall.BackColor = [System.Drawing.Color]::DodgerBlue
$buttonInstall.ForeColor = [System.Drawing.Color]::White
$buttonInstall.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($buttonInstall)

$buttonClear = New-Object System.Windows.Forms.Button
$buttonClear.Text = "Loeschen"
$buttonClear.Location = New-Object System.Drawing.Point(210, $y)
$buttonClear.Size = New-Object System.Drawing.Size(100, 40)
$buttonClear.BackColor = [System.Drawing.Color]::LightGray
$form.Controls.Add($buttonClear)

$buttonExit = New-Object System.Windows.Forms.Button
$buttonExit.Text = "Beenden"
$buttonExit.Location = New-Object System.Drawing.Point(470, $y)
$buttonExit.Size = New-Object System.Drawing.Size(100, 40)
$form.Controls.Add($buttonExit)

# ============================================
# FUNCTIONS
# ============================================

function Add-Log {
    param([string]$Message)
    $textStatus.AppendText("$Message`n")
    $textStatus.SelectionStart = $textStatus.Text.Length
    $textStatus.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
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

function Validate-Input {
    if ([string]::IsNullOrWhiteSpace($textDomainPwd.Text)) {
        [System.Windows.Forms.MessageBox]::Show("Domain-Passwort erforderlich!", "Eingabe-Fehler", "OK", "Warning")
        return $false
    }
    
    if ([string]::IsNullOrWhiteSpace($textComputerName.Text)) {
        [System.Windows.Forms.MessageBox]::Show("Computername erforderlich!", "Eingabe-Fehler", "OK", "Warning")
        return $false
    }
    
    if ([string]::IsNullOrWhiteSpace($textZabbixServer.Text)) {
        [System.Windows.Forms.MessageBox]::Show("Zabbix Server erforderlich!", "Eingabe-Fehler", "OK", "Warning")
        return $false
    }
    
    return $true
}

# ============================================
# EVENT HANDLERS
# ============================================

$buttonInstall.add_Click({
    if (-not (Validate-Input)) {
        return
    }

    $textStatus.Clear()
    $buttonInstall.Enabled = $false
    $textComputerName.Enabled = $false
    $textDomainPwd.Enabled = $false
    $textZabbixServer.Enabled = $false

    Add-Log "============================================================"
    Add-Log "ZABBIX AGENT INSTALLATION STARTEN"
    Add-Log "============================================================"
    Add-Log ""

    $computerInput = $textComputerName.Text.Trim()
    $computers = @($computerInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_.Length -gt 0 })

    if ($computers.Count -eq 0) {
        Add-Log "[ERROR] Keine gueltigen Computernamen gefunden"
        $buttonInstall.Enabled = $true
        $textComputerName.Enabled = $true
        $textDomainPwd.Enabled = $true
        $textZabbixServer.Enabled = $true
        return
    }

    $zabbixServer = $textZabbixServer.Text.Trim()
    $domainPwd = $textDomainPwd.Text
    $zabbixPwd = if ([string]::IsNullOrWhiteSpace($textZabbixPwd.Text)) { "zabbix" } else { $textZabbixPwd.Text }

    Add-Log "[INFO] Anzahl Computer: $($computers.Count)"
    Add-Log "[INFO] Computer: $($computers -join ', ')"
    Add-Log "[INFO] Zabbix Server: $zabbixServer"
    Add-Log ""

    $computerIndex = 0

    foreach ($computer in $computers) {
        $computerIndex++
        $session = $null

        Add-Log ""
        Add-Log "============================================================"
        Add-Log "COMPUTER $computerIndex / $($computers.Count): $computer"
        Add-Log "============================================================"
        Add-Log ""

        try {
            $secPwd = ConvertTo-SecureString $domainPwd -AsPlainText -Force
            $cred = New-Object System.Management.Automation.PSCredential("de401850\admin.dt", $secPwd)

            Add-Log "[0] Precheck DNS/WinRM..."
            $precheck = Test-RemoteWinRMPrereq -ComputerName $computer
            if (-not $precheck.DnsOk) {
                throw "Precheck fehlgeschlagen: DNS-Aufloesung nicht moeglich"
            }
            Add-Log "[OK] DNS: $($precheck.ResolvedIP)"

            if (-not $precheck.Port5985) {
                throw "Precheck fehlgeschlagen: WinRM Port 5985 nicht erreichbar"
            }
            Add-Log "[OK] WinRM Port 5985 erreichbar"

            Add-Log "[1] Verbinde zu $computer..."
            $session = New-PSSession -ComputerName $computer -Credential $cred -ErrorAction Stop
            Add-Log "[OK] Verbindung erfolgreich"

            Add-Log ""
            Add-Log "[2] Raeume alte Installation auf..."
            Invoke-Command -Session $session -ScriptBlock {
                Get-Service -Name "*zabbix*" -ErrorAction SilentlyContinue |
                    ForEach-Object { Stop-Service -Name $_.Name -Force -ErrorAction SilentlyContinue }

                $zabbixInstalls = Get-ChildItem -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue |
                    Where-Object { $_.GetValue("DisplayName") -like "*Zabbix*" }

                if ($zabbixInstalls.Count -gt 0) {
                    foreach ($install in $zabbixInstalls) {
                        & msiexec.exe /x $install.PSChildName /qn | Out-Null
                    }
                    Start-Sleep -Seconds 5
                }

                Remove-Item "C:\Temp\zabbix_*" -Force -Recurse -ErrorAction SilentlyContinue
            }
            Add-Log "[OK] Aufgeraeumt"

            Add-Log ""
            Add-Log "[3] Kopiere MSI..."
            Copy-Item -Path "\\bsserver\GROUPS\Ordner-Transfer\Installation\zabbix_agent.msi" -Destination "\\$computer\C`$\Temp\zabbix_agent.msi" -Force
            Add-Log "[OK] MSI kopiert"

            Add-Log ""
            Add-Log "[4] Installiere Zabbix Agent..."
            $result = Invoke-Command -Session $session -ScriptBlock {
                param([string]$ZabbixServer)
                $msi = "C:\Temp\zabbix_agent.msi"
                $args = @("/i", "`"$msi`"", "/qn", "/norestart", "SERVER=$ZabbixServer", "SERVERACTIVE=$ZabbixServer")
                $proc = Start-Process -FilePath "msiexec.exe" -ArgumentList $args -Wait -PassThru -NoNewWindow
                return @{ ExitCode = $proc.ExitCode }
            } -ArgumentList $zabbixServer

            if ($result.ExitCode -eq 0) {
                Add-Log "[OK] Installation erfolgreich"
            }
            else {
                Add-Log "[ERROR] Installation fehlgeschlagen (Code: $($result.ExitCode))"
            }

            Add-Log ""
            Add-Log "[4b] Konfiguriere HostnameItem..."
            Invoke-Command -Session $session -ScriptBlock {
                $confPath = "C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf"
                if (Test-Path $confPath) {
                    $conf = Get-Content $confPath
                    if ($conf -match "^Hostname=") {
                        $conf = $conf -replace "^Hostname=.*", ""
                        $conf = $conf | Where-Object { $_.Trim().Length -gt 0 }
                    }
                    if ($conf -notmatch "HostnameItem=") {
                        $conf += "HostnameItem=system.hostname"
                    }
                    Set-Content -Path $confPath -Value $conf -Force
                }
            }
            Add-Log "[OK] HostnameItem konfiguriert"

            Add-Log ""
            Add-Log "[5] Starte Service..."
            $svc = Invoke-Command -Session $session -ScriptBlock {
                Start-Service -Name "*zabbix*" -ErrorAction SilentlyContinue
                Get-Service -Name "*zabbix*" -ErrorAction SilentlyContinue |
                    Select-Object -First 1 | Select-Object Name, Status
            }
            Add-Log "[OK] Service laeuft: $($svc.Name)"

            Add-Log ""
            Add-Log "[6] Registriere Host auf Zabbix Server..."
            $apiURL = "http://$zabbixServer/zabbix/api_jsonrpc.php"
            $loginBody = @{ jsonrpc = "2.0"; method = "user.login"; params = @{ username = "Admin"; password = $zabbixPwd }; id = 1 } | ConvertTo-Json
            $loginResp = Invoke-RestMethod -Uri $apiURL -Method Post -Body $loginBody -ContentType "application/json"

            if ($loginResp.error) {
                Add-Log "[ERROR] API Login fehlgeschlagen"
            }
            else {
                $token = $loginResp.result
                $headers = @{ "Content-Type" = "application/json-rpc"; "Authorization" = "Bearer $token" }
                Add-Log "[OK] API Login erfolgreich"

                $hostParams = @{
                    host = $computer
                    name = $computer
                    groups = @( @{ groupid = 59 } )
                    status = 0
                    templates = @( @{ templateid = 11062 } )
                } | ConvertTo-Json -Depth 10

                $hostBody = @{
                    jsonrpc = "2.0"
                    method = "host.create"
                    params = $hostParams | ConvertFrom-Json
                    id = 1
                } | ConvertTo-Json -Depth 10

                $hostResp = Invoke-RestMethod -Uri $apiURL -Method Post -Body $hostBody -Headers $headers
                if ($hostResp.result.hostids) {
                    Add-Log "[OK] Host erstellt (ID: $($hostResp.result.hostids[0]))"
                }
                else {
                    Add-Log "[ERROR] Host-Erstellung fehlgeschlagen"
                }

                $logoutBody = @{ jsonrpc = "2.0"; method = "user.logout"; params = @(); id = 1 } | ConvertTo-Json
                Invoke-RestMethod -Uri $apiURL -Method Post -Body $logoutBody -Headers $headers | Out-Null
            }

            Add-Log ""
            Add-Log "============================================================"
            Add-Log "INSTALLATION ERFOLGREICH !"
            Add-Log "============================================================"
        }
        catch {
            Add-Log ""
            Add-Log "[ERROR] FEHLER: $_"
        }
        finally {
            if ($session) {
                Remove-PSSession $session -ErrorAction SilentlyContinue
            }
        }
    }

    Add-Log ""
    Add-Log "============================================================"
    Add-Log "BATCH ABGESCHLOSSEN"
    Add-Log "============================================================"

    $buttonInstall.Enabled = $true
    $textComputerName.Enabled = $true
    $textDomainPwd.Enabled = $true
    $textZabbixServer.Enabled = $true
})

$buttonClear.add_Click({
    $textStatus.Clear()
    Add-Log "[STATUS] Log geloescht"
})

$buttonExit.add_Click({ $form.Close() })


# ============================================
# SHOW FORM
# ============================================
$form.ShowDialog() | Out-Null
$form.Dispose()
