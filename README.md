# Zabbix Agent 2 - Remote Installation & Registrierung

PowerShell-Scripte für automatisierte Installation und Registrierung von Zabbix Agent 2 auf Windows-Clients mit zentraler Konfigurationsverwaltung.

---

## 📋 Features

✅ **Zwei Installations-Modi**
- **GUI-Version** (`Zabbix-GUI.ps1`) - Benutzerfreundliche Windows Forms Oberfläche
- **Console-Version** (`Zabbix-COMPLETE.ps1`) - Vollautomatische Batch-Installation

✅ **Zentrale Konfiguration**
- Alle Umgebungsvariablen in separater Config-Datei (`Zabbix-Config.psd1`)
- Einfache Anpassung für verschiedene Umgebungen (Dev/Staging/Production)
- Keine hartcodierten Werte in den Scripts

✅ **Automatisierte Prozesse**
- Remote-Installation via WinRM/PSRemoting
- Automatische Zabbix Server API-Registrierung
- Service-Konfiguration und Start
- WinRM Vorprüfung (DNS + Port 5985)

---

## 🚀 Schnellstart

### 1. Konfiguration erstellen

Kopiere die Beispiel-Config und passe sie an:

```powershell
Copy-Item Zabbix-Config.psd1.example Zabbix-Config.psd1
notepad Zabbix-Config.psd1
```

**Zabbix-Config.psd1 - Beispiel:**
```powershell
@{
    # Netzwerk / Server
    ZabbixServer = "10.56.131.163"
    MsiPath = "\\server\share\zabbix_agent.msi"

    # Zabbix API
    ZabbixApiUser = "Admin"
    ZabbixApiPassword = "zabbix"

    # Domain / Remote Admin
    Domain = "DEINEDOMAIN"
    DomainAdminUser = "admin.benutzer"
    DomainPassword = "GeheimesPasswort"
}
```

### 2a. GUI-Installation (empfohlen)

```powershell
.\Zabbix-GUI.ps1
```

**Features:**
- Vorausgefüllte Felder aus Config
- Komma-separierte Liste für Batch-Installation (z.B. `PC001,PC002,PC003`)
- Live-Fortschrittsanzeige
- Fehlerbehandlung mit detailliertem Log

### 2b. Console-Installation

```powershell
.\Zabbix-COMPLETE.ps1
```

**Interaktive Eingabe:**
- Computername wird abgefragt
- Credentials aus Config oder manuelle Eingabe
- Automatische API-Registrierung

---

## 📁 Dateistruktur

```
Zabbix-Agent-2---Remote-Installation-Registrierung/
├── Zabbix-GUI.ps1                    # GUI-Frontend (Windows Forms)
├── Zabbix-COMPLETE.ps1               # Console-Script
├── Zabbix-Config.psd1.example        # Beispiel-Konfiguration
└── Zabbix-Config.psd1                # Deine Config (nicht in Git!)
```

**Wichtig:** `Zabbix-Config.psd1` mit echten Passwörtern **nicht** ins Repository committen!

---

## ⚙️ Konfigurationsparameter

| Parameter | Beschreibung | Beispiel | Standard |
|-----------|-------------|----------|----------|
| `ZabbixServer` | IP/Hostname des Zabbix Servers | `"10.56.131.163"` | - |
| `MsiPath` | UNC-Pfad zur MSI-Datei | `"\\server\share\zabbix_agent.msi"` | - |
| `ZabbixApiUser` | Zabbix API Benutzername | `"Admin"` | `"Admin"` |
| `ZabbixApiPassword` | Zabbix API Passwort | `"zabbix"` | - |
| `Domain` | Windows Domain | `"CONTOSO"` | - |
| `DomainAdminUser` | Domain Admin Benutzername | `"admin.dt"` | - |
| `DomainPassword` | Domain Admin Passwort | `"*****"` | - |

### Zusätzliche Parameter (im Script, nicht in Config)

Diese Parameter können direkt im Script angepasst werden:

| Parameter | Beschreibung | Aktueller Wert | Ort |
|-----------|-------------|----------------|-----|
| `HostGroup` | Zabbix Host-Gruppe für neue Clients | `"Windows clients"` | GUI: ~405, Console: ~315 |
| `Template` | Zabbix Template für neue Clients | `"Windows by Zabbix agent active Client PC"` | GUI: ~406, Console: ~316 |

---

## 🔧 Voraussetzungen

### Auf dem Remote-Client:
- **Windows 7/Server 2008 R2 oder höher**
- **PowerShell 5.1+**
- **WinRM aktiviert** (PSRemoting)

### Client vorbereiten (falls WinRM nicht aktiv):

Auf dem **Ziel-Client** (lokal als Administrator):

```powershell
Enable-PSRemoting -Force
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force
Restart-Service WinRM
```

Oder Firewall-Regel manuell:
```powershell
New-NetFirewallRule -DisplayName "WinRM HTTP" -Direction Inbound -LocalPort 5985 -Protocol TCP -Action Allow
```

### Auf dem Admin-PC:
- **Netzwerkzugriff** zu Remote-Clients (Port 5985)
- **Domain Admin Credentials** oder lokale Admin-Rechte
- **Zugriff auf MSI-Datei** (SMB-Share)

---

## 📊 Ablauf der Installation

### GUI-Workflow:
1. **Config laden** → Felder vorausfüllen
2. **Computer eingeben** → Einzeln oder Batch (komma-separiert)
3. **Button "Installation starten"** → Batch-Verarbeitung
4. **Live-Status** → Fortschritt für jeden Client
5. **Abschluss** → Erfolgsmeldung oder Fehlerlog

### Technischer Ablauf (beide Modi):
1. **[0] WinRM Precheck** - DNS-Auflösung + Port 5985 Test
2. **[1] Verbindung** - PSSession zum Remote-Client
3. **[2] Cleanup** - Alte Zabbix-Installation entfernen
4. **[3] MSI kopieren** - Agent-MSI auf Remote-Client
5. **[4] Installation** - Silent Install mit msiexec
6. **[4b] Konfiguration** - `HostnameItem=system.hostname` setzen
7. **[5] Service Start** - Zabbix Agent Service aktivieren
8. **[6] API-Registrierung** - Host auf Zabbix Server anlegen

---

## � Zabbix API Integration

Die Scripts verwenden die **Zabbix JSON-RPC API 7.x** für die automatisierte Host-Registrierung.

### API-Versionen

| Version | Authentifizierung | Status |
|---------|------------------|--------|
| 7.0+ | Bearer Token (Authorization Header) | ✅ Unterstützt |
| 6.0 LTS | Bearer Token (ab 6.0.8) | ✅ Unterstützt |
| 5.0 LTS | Session-basiert (Cookie) | ⚠️ Nicht getestet |

### API-Credentials konfigurieren

In `Zabbix-Config.psd1`:

```powershell
@{
    ZabbixServer = "10.56.131.163"
    ZabbixApiUser = "Admin"              # Zabbix Admin-Benutzer
    ZabbixApiPassword = "zabbix"         # Admin-Passwort
    # ...weitere Parameter...
}
```

**Wichtig:** Der API-Benutzername kann auch ein Service-Account sein:
```powershell
ZabbixApiUser = "zabbix_api_user"
ZabbixApiPassword = "SuperSecurePassword"
```

### API-Endpunkt

Die Scripts verbinden sich zum Zabbix API-Endpunkt:

```
http://<ZabbixServer>/zabbix/api_jsonrpc.php
```

**Login-Prozess:**
1. `user.login` → Erhält API Token
2. Token wird in `Authorization: Bearer <token>` Header verwendet
3. `user.logout` → Token wird ungültig gemacht

### Host-Registrierung Details

#### 1️⃣ Standard Host-Gruppe

Die Clients werden in diese Host-Gruppe registriert:

```
"Windows clients"
```

**Anpassen:** Parameter in den Scripts ändern
- **GUI**: Zeile ~405 (Hard-codiert auf `groupid = 59`)
- **Console**: Parameter `$HostGroup = "Windows clients"`

#### 2️⃣ Standard Template

Die Clients nutzen folgendes Zabbix Template:

```
"Windows by Zabbix agent active Client PC"
```

**Anpassen:** Parameter in den Scripts ändern
- **GUI**: Zeile ~406 (Hard-codiert auf `templateid = 11062`)
- **Console**: Parameter `$Template = "Windows by Zabbix agent active Client PC"`

**⚠️ Hinweis:** Die Template-ID und Group-ID müssen in deiner Zabbix-Installation überprüft werden!

#### 3️⃣ Host-Registrierung Ablauf

Der technische Ablauf:

```
[1] Login
    → user.login mit Admin-Credentials

[2] Prüfe existierenden Host
    → Wenn Host lebt → Status auf "monitored" (0)
    → Wenn Host tot → Aktualisiere und rückkehr

[3] Hole Host-Gruppe
    → Suche nach Gruppen-ID
    → Erstelle falls nicht vorhanden

[4] Hole Template
    → Suche nach Template-ID
    → Optional (kann leer sein)

[5] Erstelle Host
    → host.create API-Call
    → Mit Gruppe, Template, Status=0 (monitored)
    → Hostnamen aus Computername

[6] Logout
    → user.logout API-Call
```

### Template-ID und Group-ID ermitteln

Falls die Standard-IDs nicht funktionieren, musst du deine IDs ermitteln:

**Via Zabbix Web UI:**
1. Admin → General
2. Host groups → Name suchen → ID auslesen
3. Templates → Template suchen → ID auslesen

**Via PowerShell/API:**
```powershell
# Host-Gruppen auflisten
$body = @{
    jsonrpc = "2.0"
    method = "hostgroup.get"
    params = @{ output = @("groupid", "name") }
    id = 1
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://<server>/zabbix/api_jsonrpc.php" `
    -Method Post -Body $body -ContentType "application/json"
```

**Danach in Scripts anpassen:**

```powershell
# Zabbix-GUI.ps1 Zeile ~405
groups = @( @{ groupid = 59 } )          # Deine Group-ID

# Zabbix-GUI.ps1 Zeile ~406
templates = @( @{ templateid = 11062 } ) # Dein Template-ID
```

### API Error Handling

Die Scripts zeigen detaillierte API-Fehlermeldungen:

```
[ERROR] API Error: Permissions denied. (Code: -32500)
[ERROR] API Error: No permissions to referred object or it does not exist! (Code: -32602)
```

**Häufige Fehler:**

| Fehler | Ursache | Lösung |
|--------|--------|--------|
| "Permission denied" | Admin-User hat keine API-Rechte | Zabbix Admin → Users → Permissions prüfen |
| "No such user" | API-Username falsch | Benutzername in Config korrekt? |
| "Invalid token" | Session abgelaufen | Selten, Token wird direkt nach Login erzeugt |

---

## �🛠️ Troubleshooting

### ❌ Fehler: "WinRM Port 5985 nicht erreichbar"

**Ursache:** PSRemoting nicht aktiviert oder Firewall blockiert

**Lösung:**
```powershell
# Auf dem Ziel-Client (lokal):
Enable-PSRemoting -Force
```

### ❌ Fehler: "MSI Error 1618"

**Ursache:** Eine andere Installation läuft gerade

**Lösung:** Warten und erneut versuchen

### ❌ Fehler: "DNS-Auflösung fehlgeschlagen"

**Ursache:** Computername nicht im DNS oder falsch geschrieben

**Lösung:** 
- Hostname prüfen: `nslookup COMPUTERNAME`
- Stattdessen IP-Adresse verwenden

### ❌ Fehler: "Zabbix API Login fehlgeschlagen"

**Ursache:** Falsche API-Credentials in Config

**Lösung:** 
- `ZabbixApiUser` und `ZabbixApiPassword` in `Zabbix-Config.psd1` prüfen
- Zabbix Web-Login testen

---

## 📝 Beispiele

### Batch-Installation über GUI

1. Config vorbereiten:
```powershell
# Zabbix-Config.psd1
@{
    ZabbixServer = "192.168.1.100"
    Domain = "FIRMA"
    DomainAdminUser = "admin"
    DomainPassword = "SuperSecret123"
    # ...
}
```

2. GUI starten und Computer eingeben:
```
PC-OFFICE-01, PC-OFFICE-02, PC-LABOR-05, PC-LAGER-10
```

3. **Installation starten** → 4 Clients werden parallel installiert

### Console-Installation (Scripting)

```powershell
# Einzelne Installation mit Config
.\Zabbix-COMPLETE.ps1

# Installation ohne Host-Registrierung
.\Zabbix-COMPLETE.ps1 -RegisterHost $false
```

---

## 🔐 Sicherheitshinweise

⚠️ **Passwörter in Config-Datei:**
- `Zabbix-Config.psd1` enthält Klartext-Passwörter
- **Nicht in Git/GitHub hochladen!**
- Alternative: Passwort-Felder leer lassen → Script fragt interaktiv

**Empfehlung für Produktion:**
```powershell
# Zabbix-Config.psd1 (ohne Passwörter)
@{
    ZabbixServer = "10.56.131.163"
    Domain = "FIRMA"
    DomainAdminUser = "admin.zabbix"
    DomainPassword = ""  # Leer lassen → wird abgefragt
    ZabbixApiPassword = ""
}
```

---

## 🤝 Beitragen

Verbesserungsvorschläge und Pull Requests sind willkommen!

1. Repository forken
2. Feature-Branch erstellen (`git checkout -b feature/AmazingFeature`)
3. Änderungen committen (`git commit -m 'Add AmazingFeature'`)
4. Branch pushen (`git push origin feature/AmazingFeature`)
5. Pull Request öffnen

---

## 📜 Lizenz

Dieses Projekt ist Open Source und frei verwendbar.

---

## 👤 Autor

**Daniel Troks**  
GitHub: [@toda2203](https://github.com/toda2203)

---

## 🔄 Changelog

### v2.0 (März 2026)
- ✨ Zentrale Konfigurationsdatei (`Zabbix-Config.psd1`)
- ✨ Automatisches Laden von Credentials
- ✨ GUI-Passwort-Feld vorausgefüllt
- 🐛 Batch-Installation über GUI optimiert
- 📝 Umfassendes README mit Troubleshooting

### v1.0 (Initial Release)
- 🎉 Erste Version mit GUI und Console-Script
- 🔧 Zabbix 7.x API Integration
- 🚀 WinRM-basierte Remote-Installation

---

**Viel Erfolg bei der Zabbix Agent Installation! 🚀**
