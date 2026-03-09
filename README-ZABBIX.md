# Zabbix Agent 2 - Remote Installation & Registrierung

## 🎯 Übersicht

Automatisierte Installation und Registrierung von **Zabbix Agent 2** auf Windows-Clients via PowerShell Remoting mit vollständiger API-Integration.

---

## 📋 Voraussetzungen

### Auf dem Server (Management-Computer)
- Windows PowerShell 5.1+
- Admin-Rechte für PSRemoting
- Netzwerk-Zugang zu den Clients

### Auf den Clients (Windows-Computer)
- **WICHTIG:** PowerShell Remoting (WinRM) aktiviert
  - Mit [Zabbix-PrepareClient.ps1](#vorbereitung-winrm-aktivieren) aktivieren

### Zabbix Server
- IP: `10.56.131.163`
- API: `http://10.56.131.163/zabbix/api_jsonrpc.php`
- Admin-Benutzer: `Admin`
- Standard-Passwort: `zabbix`

### MSI Installation
- Pfad: `\\bsserver\GROUPS\Ordner-Transfer\Installation\zabbix_agent.msi`
- Version: Zabbix Agent 2 (64-bit)

---

## 🚀 Schneltstarter

### 1️⃣ Vorbereitung: WinRM auf dem Client aktivieren

**Lokal auf dem Client als Administrator:**

```powershell
# Terminal öffnen als Administrator und ausführen:
powershell -Command "Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force; & 'C:\Temp\Zabbix-PrepareClient.ps1'"
```

Oder direkt im PowerShell Terminal:
```powershell
cd C:\Temp
.\Zabbix-PrepareClient.ps1
```

**Erfolgreiche Ausgabe sieht so aus:**
```
✓ Läuft mit Administrator-Rechten
[1] Prüfe WinRM Status...
[2] Aktiviere PowerShell Remoting...
    ✓ PSRemoting aktiviert
[3] Konfiguriere Windows Firewall...
    ✓ WinRM HTTP Firewall-Regel aktiviert
[4] Starte WinRM Service...
    ✓ WinRM Service läuft bereits
    ✓ WinRM: Automatischer Start aktiviert
[5] Prüfe WinRM Listener...
    ✓ WinRM Listener sind konfiguriert
[6] Konfiguriere vertrauenswürdige Hosts...
    ✓ Vertrauenswürdige Hosts bereits konfiguriert

VORBEREITUNG ABGESCHLOSSEN ✓
Dieser Computer ist jetzt bereit für Remote-Zugriff!
```

---

### 2️⃣ Installation: Agent auf dem Client installieren

**Auf dem Management-Computer:**

```powershell
cd C:\Temp
.\Zabbix-COMPLETE.ps1
```

**Eingabe-Prompts:**
1. **Domain-Credentials:** `de401850\admin.dt` (Windows Domain-Passwort)
2. **Computername:** `DE401850C00034` (Client-Name)
3. **Zabbix API:** Automatisch mit Standard-Passwort `zabbix`

**Erfolgreiche Ausgabe:**
```
[1] Verbinde zu DE401850C00034...
    OK
    IP-Adresse: 10.56.131.127
[2] Räume auf...
    OK
[3] Kopiere MSI...
    OK
[4] Installiere Zabbix Agent...
    OK - Installation erfolgreich
[4b] Konfiguriere HostnameItem...
    OK
[5] Starte Service...
    OK - Service 'Zabbix Agent 2' läuft

[6] Registriere Host auf Zabbix Server...
[6a] API Login...
    ✓ Login erfolgreich
[6b] Prüfe ob Host existiert...
[6c] Suche Host-Gruppe 'Windows clients'...
    ✓ Host-Gruppe gefunden (ID: 59)
[6d] Suche Template 'Windows by Zabbix agent active Client PC'...
    ✓ Template gefunden (ID: 11062)
[6e] Erstelle Host...
    ✓ Host erfolgreich erstellt (ID: 11070)
```

---

## 📁 Script-Dateien

### 1. **Zabbix-COMPLETE.ps1** (Hauptscript)
**Aufgabe:** Vollständige Installation + API-Registrierung

**Was macht es:**
- ✓ Verbindet sich via PSRemoting zum Client
- ✓ Entfernt alte Zabbix-Installationen
- ✓ Kopiert MSI vom Share
- ✓ Installiert Zabbix Agent 2
- ✓ Konfiguriert `HostnameItem=system.hostname`
- ✓ Startet Service `Zabbix Agent 2`
- ✓ Registriert Host auf Zabbix Server via API
- ✓ Weist Gruppe `Windows clients` zu
- ✓ Weist Template `Windows by Zabbix agent active Client PC` zu

**Verwendung:**
```powershell
.\Zabbix-COMPLETE.ps1
```

**Fallback:** Wenn Standard-Passwort nicht funktioniert, wird `zabbix` automatisch getestet und bei Fehler nachgefragt.

---

### 2. **Add-ZabbixHost.ps1** (Nur API-Registrierung)
**Aufgabe:** Host nachträglich auf Zabbix Server registrieren (ohne Installation)

**Verwendung:**
```powershell
.\Add-ZabbixHost.ps1
```

**Eingabe-Prompts:**
- Zabbix Server (Standard: `10.56.131.163`)
- Hostname des Clients
- IP-Adresse des Clients
- Zabbix Passwort (Standard: `zabbix`)

---

### 3. **Zabbix-PrepareClient.ps1** (WinRM Vorbereitung)
**Aufgabe:** PowerShell Remoting auf dem Client aktivieren

**Wird benötigt wenn:**
- `Enable-PSRemoting` noch nicht aktiviert wurde
- Fehlermeldung: "WinRM kann den Vorgang nicht abschließen"

**Ausführung (lokal auf dem Client, als Administrator):**
```powershell
.\Zabbix-PrepareClient.ps1
```

---

## ⚙️ Konfiguration

### Zabbix Server & API
- **Server:** `10.56.131.163`
- **API-URL:** `http://10.56.131.163/zabbix/api_jsonrpc.php`
- **User:** `Admin`
- **Pass:** `zabbix` (Standard)

### Host-Gruppe
- **Name:** `Windows clients`
- **ID:** 59

### Template
- **Name:** `Windows by Zabbix agent active Client PC`
- **ID:** 11062
- **Typ:** Active (Agent meldet sich selbst an)

### Agent-Konfiguration
- **Config-Datei:** `C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf`
- **Hostname:** `HostnameItem=system.hostname` (dynamisch)
- **Server:** `10.56.131.163`
- **Service-Name:** `Zabbix Agent 2`

---

## 🔧 Troubleshooting

### Fehler: "WinRM kann den Vorgang nicht abschließen"
**Lösung:**
1. `Zabbix-PrepareClient.ps1` auf dem Client ausführen
2. Mit `.\Zabbix-COMPLETE.ps1` erneut versuchen

### Fehler: "Standard-Passwort funktioniert nicht"
**Lösung:**
- Script fragt automatisch nach Passwort
- Wenn anders als `zabbix`, Script wird interaktiv

### Host wurde aufgelistet aber Service läuft nicht
**Prüfen:**
```powershell
# Auf dem Client:
Get-Service -Name "*zabbix*" -ErrorAction SilentlyContinue | Format-Table Name, Status, StartType
```

### Logs prüfen
```powershell
# MSI Installation Log:
C:\Temp\zabbix_install.log

# Zabbix Agent Log:
C:\Program Files\Zabbix Agent 2\zabbix_agent2.log
```

---

## 📊 Standard-Einstellungen

| Einstellung | Wert | Beschreibung |
|-----------|------|-------------|
| Host-Gruppe | `Windows clients` | Automatisch erstellt wenn nicht vorhanden |
| Template | `Windows by Zabbix agent active Client PC` | Active Agent Mode |
| Interface | **KEINE** | Agent Active - meldet sich selbst an |
| Hostname | `system.hostname` | Dynamisch vom System |
| Server | `10.56.131.163` | Zabbix Server |
| Port | `10050` | Standard Zabbix Agent Port |

---

## ✅ Verifikation nach Installation

### Auf dem Client überprüfen
```powershell
# Service Status
Get-Service -Name "*zabbix*"

# Config-Datei
type "C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf"

# Logs
Get-Content "C:\Program Files\Zabbix Agent 2\zabbix_agent2.log" -Tail 20
```

### Auf dem Zabbix Server überprüfen
1. Zabbix Web-UI öffnen: `http://10.56.131.163/zabbix`
2. Monitoring → Hosts
3. Im Filter suchen nach dem Hostnamen
4. Status sollte sein:
   - ✓ `Enabled`
   - ✓ Gruppe: `Windows clients`
   - ✓ Template: `Windows by Zabbix agent active Client PC`
   - ✓ **Keine Interfaces** (Agent Active)

---

## 📝 Script-Logik

### Installation Flow
```
1. PSRemoting Verbindung → Client
2. Alte Installation entfernen (WMI Registry)
3. MSI kopieren
4. MSI installieren (msiexec /i /qn)
5. Config modifizieren (HostnameItem=system.hostname)
6. Service starten
```

### API Registrierung Flow
```
1. API Login (Authorization: Bearer {token})
2. Host existiert? (host.get mit Filter)
3. Host-Gruppe suchen/erstellen
4. Template suchen
5. Host erstellen (host.create)
6. API Logout
```

---

## 🔒 Sicherheit

- **Authentication:** Domain-Credentials (de401850\admin.dt)
- **Passwort:** Zabbix Standard `zabbix` mit Test-Fallback
- **Remoting:** WinRM mit TrustedHosts
- **SSL/TLS:** Kann optional konfiguriert werden

---

## 📱 Unterstützte Systeme

- ✓ Windows 10 / 11
- ✓ Windows Server 2016+
- ✓ Domain-Umgebung (de401850)
- ✓ PowerShell 5.1+

---

## 💡 Best Practices

1. **Vor Installation:** `Zabbix-PrepareClient.ps1` lokal auf dem Client ausführen
2. **Batch-Installation:** Script können in Schleife für mehrere Clients gebündelt werden
3. **Logging:** MSI-Log wird in `C:\Temp\zabbix_install.log` gespeichert
4. **Fehlerbehandlung:** Scripts geben detaillierte Fehler aus

---

## 📞 Support-Informationen

**Zabbix Server:**
- URL: `http://10.56.131.163/zabbix`
- API-Benutzer: `Admin`

**MSI Quelle:**
- Path: `\\bsserver\GROUPS\Ordner-Transfer\Installation\zabbix_agent.msi`

**Logs für Debugging:**
- Installation Log: `C:\Temp\zabbix_install.log`
- Agent Log: `C:\Program Files\Zabbix Agent 2\zabbix_agent2.log`

---

**Version:** 1.0 | 6. März 2026
