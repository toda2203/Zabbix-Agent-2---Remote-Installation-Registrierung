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
    ZabbixServer = "192.168.1.123"
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
| `ZabbixServer` | IP/Hostname des Zabbix Servers | `"192.168.1.123"` | - |
| `MsiPath` | UNC-Pfad zur MSI-Datei | `"\\server\share\zabbix_agent.msi"` | - |
| `ZabbixApiUser` | Zabbix API Benutzername | `"Admin"` | `"Admin"` |
| `ZabbixApiPassword` | Zabbix API Passwort | `"zabbix"` | - |
| `Domain` | Windows Domain | `"CONTOSO"` | - |
| `DomainAdminUser` | Domain Admin Benutzername | `"admin"` | - |
| `DomainPassword` | Domain Admin Passwort | `"*****"` | - |

### Zusätzliche Parameter (im Script, nicht in Config)

Diese Parameter können direkt im Script angepasst werden:

| Parameter | Beschreibung | Standard Wert | Ort im Script |
|-----------|-------------|---------------|---------------|
| `HostGroup` | Zabbix Host-Gruppe für neue Clients | `"Windows clients"` | Zeile ~378 |
| `Template` | Zabbix Template für neue Clients | `"Windows by Zabbix agent active Client PC"` | Zeile ~379 |

---

## 🔌 Zabbix API Integration

Die Scripts verwenden die **Zabbix JSON-RPC API 7.x** für die automatisierte Host-Registrierung.

### API-Versionen

| Version | Authentifizierung | Status |
|---------|------------------|--------|
| 7.0+ | Bearer Token (Authorization Header) | ✅ Unterstützt |
| 6.0 LTS | Bearer Token (ab 6.0.8) | ✅ Unterstützt |
| 5.0 LTS | Session-basiert (Cookie) | ⚠️ Nicht getestet |

### API-Credentials in Config

In `Zabbix-Config.psd1`:

```powershell
@{
    ZabbixServer = "192.168.1.123"
    ZabbixApiUser = "Admin"              # Zabbix Admin-Benutzer
    ZabbixApiPassword = "zabbix"         # Admin-Passwort
    # ...weitere Parameter...
}
```

### Host-Gruppe (Standard: "Windows clients")

Neue Clients werden in folgende Host-Gruppe aufgenommen:

```
"Windows clients"
```

**Host-Gruppe ID ermitteln (Zabbix Web UI):**
- Admin → General → Host groups → "Windows clients" suchen → GroupID kopieren

**Host-Gruppe ändern:**
- **GUI (Zabbix-GUI.ps1)**, Zeile ~405: `groups = @( @{ groupid = <ID> } )`
- **Console (Zabbix-COMPLETE.ps1)**, Parameter: `$HostGroup = "Neue Host-Gruppe"`

### Template (Standard: "Windows by Zabbix agent active Client PC")

Clients nutzen folgendes Template:

```
"Windows by Zabbix agent active Client PC"
```

**Template ID ermitteln (Zabbix Web UI):**
- Admin → Templates → "Windows by Zabbix agent" suchen → Template ID kopieren

**Template ändern:**
- **GUI (Zabbix-GUI.ps1)**, Zeile ~406: `templates = @( @{ templateid = <ID> } )`
- **Console (Zabbix-COMPLETE.ps1)**, Parameter: `$Template = "Neues Template"`

### API Endpunkt

```
http://<ZabbixServer>/zabbix/api_jsonrpc.php
```

**Login-Prozess (automatisch):**
1. `user.login` API-Call mit Admin-Credentials
2. Erhält Bearer Token
3. Token wird in `Authorization: Bearer <token>` Header verwendet
4. `user.logout` nach Registrierung

### Häufige API-Fehler

| Fehler | Ursache | Lösung |
|--------|--------|--------|
| "Permission denied" | Admin-User hat keine API-Rechte | Zabbix Admin → Users → Permissions prüfen |
| "No such user" | API-Username falsch | `ZabbixApiUser` in Config prüfen |
| "No permissions to referred object" | Host-Gruppe nicht vorhanden | Host-Gruppe und GroupID prüfen |
| "Invalid template" | Template existiert nicht | Template und TemplateID prüfen |

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

## 🛠️ Troubleshooting

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
    ZabbixServer = "192.168.1.123"
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
