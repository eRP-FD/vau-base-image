# Base image

## Intro
Dieses Image ist als gehärtete Basis für die VAU-Docker-Images zu verwenden und enthält die Härtungsschritte.

## Dependencies
* Haben Sie Zugang zu de.icr.io/erp_dev/ubuntu-focal:20230624, oder laden Sie das ubuntu-focal-Image und benenne es passend zum base image in der Docker-Datei.

## Dockerfile
Das Docker-Image wird:
 - die erforderliche Software installieren - eine Liste der installierten Software finden Sie im folgenden Abschnitt
 - die erforderlichen Konfigurationsdateien hinzufügen
 - Sicherheitshärtungsschritte durchführen

## Software

### 1. [Gramine](https://grapheneproject.io)
Gramine wird in Form eines Debian-Pakets installiert, das von den Maintainern bereitgestellt wird:
https://github.com/gramineproject/gramine/releases
### 2. [Auditd](https://man7.org/linux/man-pages/man8/auditd.8.html)
Zu Zwecken der Sicherheitshärtung wird der Linux Audit-Daemon installiert. Er ist für das Schreiben von Audit-Aufzeichnungen auf die Festplatte zuständig.
Während des Starts werden die Regeln in /etc/audit/audit.rules von auditctl gelesen und in den Kernel geladen.
Regeln können [here](files/etc/auditd/rules.d) gefunden werden.
###  3. [AppArmor](https://wiki.debian.org/AppArmor)
AppArmor ist ein Framework für die obligatorische Zugriffskontrolle. Wenn es aktiviert ist, schränkt AppArmor Programme gemäß einer Reihe von Regeln ein
die festlegen, auf welche Dateien ein bestimmtes Programm zugreifen kann.
Dieser proaktive Ansatz hilft, das System vor bekannten und unbekannten Schwachstellen zu schützen.
Profile können [here](files/etc/apparmor.d/) gefunden werden.
### 4. [AIDE](https://aide.github.io)
AIDE (Advanced Intrusion Detection Environment) ist ein Programm zur Überprüfung der Integrität von Dateien und Verzeichnissen.
Es erstellt eine Datenbank mit den regular expression rules, die es in der/den Konfigurationsdatei(en) findet. Sobald diese Datenbank
initialisiert ist, kann sie zur Überprüfung der Integrität der Dateien verwendet werden.
Konfiguration kann [here](files/etc/aide/aide.conf) gefunden werden.
### 5. [chrony](https://chrony.tuxfamily.org)
chrony ist eine vielseitige Implementierung des Network Time Protocol (NTP). Es kann die Systemuhr mit NTP-Servern synchronisieren.
Da ein und dasselbe Image in mehreren Umgebungen verwendet wird, sind in der Konfiguration sowohl Test- als auch Produktionszeitserver aufgeführt.
### 6. [Logdna](https://www.logdna.com)
LogDNA ist ein zentralisiertes Log-Management-Tool, mit dem Teams in jeder Phase des Softwareentwicklungszyklus kontinuierliches Feedback erhalten.
Wird zum Sammeln und Prüfen von Protokollen verwendet.
### 7. [Sysdig](https://sysdig.com) (draios-agent)
Sysdig ist eine Open-Source-Lösung zur Erforschung auf Systemebene. Es erfasst den Systemzustand und die Aktivität einer laufenden Linux-Instanz und speichert, filtert und analysiert diesen.
Es wird für die Überwachung verwendet.
Während der Installation benötigt sysdig die Kernel-Header. Außerdem werden während der Laufzeit mehrere Python-Pakete
benötigt (python3-lib2to3, python3-distutils, etc)
### 8. [HAProxy](http://www.haproxy.org)
HAProxy ist eine kostenlose, sehr schnelle und zuverlässige Lösung, die Hochverfügbarkeit, Lastausgleich und Proxying für TCP
und HTTP-basierte Anwendungen anbietet.
Wird für das Balancing und die Überprüfung von Backend-Verbindungen zu Redis und Postgressql verwendet.
### 9. [Hashicorp Vault](https://www.vaultproject.io)
Vault sichert, speichert und kontrolliert den Zugang zu Token, Passwörtern, Zertifikaten, API-Schlüsseln und anderen Geheimnissen im modernen Computing.
Der Client wird verwendet, um sich nach dem Booten mit dem Hashicorp Vault-Server zu verbinden, um Secrets abzurufen.


## Build
### CI Build
Das Image wird von Jenkins erstellt und in die Registry übertragen

### Manual build
Das Image kann lokal mit docker build erstellt werden, sofern die oben genannten Abhängigkeiten erfüllt sind

## Howto: changes, updates

Das Image ist an eine Ubuntu Focal-Version geknüpft und muss jedes Mal aktualisiert werden, wenn ein neues aktualisiertes Tag veröffentlicht wird.
Das Dockerfile enthält Informationen darüber, welche CIS-Benchmark-Abschnitte welche Änderungen erforderlich machen.

## Howto: benchmark evaluation

Sie müssen die Datei "CIS_Ubuntu_Linux_20.04_LTS_Benchmark_v1.1.0-xccdf_eRP_custom.xml" verwenden, die den angepassten CIS Ubuntu 20.04 Benchmark enthält.
Die XML-Datei enthält ein neues Profil "E-Rezept VAU Benchmark", das auf dem Profil "Server - Level 2" basiert und für E-Rezept angepasst wurde.


Zur Ausführung verwenden Sie den installierten und konfigurierten CIS Assessor (IBM-Lizenz) im Docker-Container:

```
./Assessor-CLI.sh --vulnerability-definitions
./Assessor-CLI.sh --no-timestamp -html -txt --report-prefix="vulnscan" --oval-definitions=/opt/vulnerabilities/com.ubuntu.focal.cve.oval.xml
./Assessor-CLI.sh --no-timestamp -html -txt --report-prefix="hardening" -D ignore.platform.mismatch=true --benchmark=/opt/benchmarks/CIS_Ubuntu_Linux_20.04_LTS_Benchmark_v1.1.0-xccdf_eRP_custom.xml -p "E-Rezept VAU Benchmark"
```

Der Bericht sollte *no failed tests* anzeigen.
 
