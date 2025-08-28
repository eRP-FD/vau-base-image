# File structure

## apt-key folder
Contains gpg keys that are needed for apt package verification.

Please see more details [here](apt-key/README.md)

## etc folder
The structure under files folder is meant to emulate the root "/etc" folder on the server.
Contains different configuration files to be copied into the /etc folder in the image

- /etc/aide - the [AIDE](https://aide.github.io) configuration file 
- /etc/apparmor.d/ - [AppArmor](https://wiki.debian.org/AppArmor)  profile for chrony and haproxy - security hardening
- /etc/auditd/rules.d/ - auditd rules - security hardening
- /etc/chrony/chrony.conf - [chrony](https://chrony.tuxfamily.org) configuration files, containing the NTP servers
- /etc/iptables - contains iptables firewall rules - security hardening
- /etc/sysctl.d/ - contains system settings for  security hardening
- /etc/systemd/network - systemd networkd - network interfaces definition and settings
- /etc/systemd/system - systemd service definition files
  - aide-fim.service - start [AIDE](https://aide.github.io) File Integrity Monitoring Service
  - aide-fim.timer - [AIDE](https://aide.github.io) File Integrity Monitoring regular timer - define how often the state of the file integrity is checked
  - systemd-networkd-wait-online.service - rewrite the default systemd service to only check active network interfaces
  
## gpg folder

Contains gpg keys that are needed for gpg file verification. More info [here](gpg/README.md).

## sgx folder

Please read [here](sgx/README.md).
