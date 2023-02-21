# Base image

## Intro
This image is to be used as a hardened base for the VAU docker images and contains the hardening steps.

## Dependencies
* Have access to de.icr.io/erp_dev/ubuntu-focal:20221130, or pull the ubuntu focal image and retag it to match the name
of the base image in the Dockerfile

## Dockerfile
The docker image will:
 - install required software - for a list of the software installed please see the section below
 - add required configuration files
 - run security hardening steps

## Software

### 1. [Gramine](https://grapheneproject.io)
Gramine is installed form a debian package, which is provided from the maintainers:
https://github.com/gramineproject/gramine/releases
### 2. [Auditd](https://man7.org/linux/man-pages/man8/auditd.8.html)
For security hardening purposes, the Linux Audit daemon is installed. It's responsible for writing audit records to the disk.
During startup, the rules in /etc/audit/audit.rules are read by auditctl and loaded into the kernel.
Rules can be found [here](files/etc/auditd/rules.d).
###  3. [AppArmor](https://wiki.debian.org/AppArmor)
AppArmor is a Mandatory Access Control framework. When enabled, AppArmor confines programs according to a set of rules
that specify what files a given program can access.
This proactive approach helps protect the system against both known and unknown vulnerabilities.
Profiles can be found [here](files/etc/apparmor.d/).
### 4. [AIDE](https://aide.github.io)
AIDE (Advanced Intrusion Detection Environment) is a file and directory integrity checker.
It creates a database from the regular expression rules that it finds from the config file(s). Once this database is
initialized it can be used to verify the integrity of the files.
Config can be found [here](files/etc/aide/aide.conf).
### 5. [chrony](https://chrony.tuxfamily.org)
chrony is a versatile implementation of the Network Time Protocol (NTP). It can synchronise the system clock with NTP servers.
As the same image is used in multiple environments, the configuration lists both test and production time servers.
### 6. [Logdna](https://www.logdna.com)
LogDNA is a centralized log management tool that enables teams to gain continuous feedback at every stage of the software
development lifecycle.
Used for log collecting and inspecting.
### 7. [Sysdig](https://sysdig.com) (draios-agent)
Sysdig is open source, system-level exploration. Capture system state and activity from a running Linux instance, then save,
filter, and analyze.
Used for monitoring.
During install, sysdig needs the kernel headers. Also, during runtime, multiple python packages are
reqired (python3-lib2to3, python3-distutils, etc)
### 8. [HAProxy](http://www.haproxy.org)
HAProxy is a free, very fast and reliable solution offering high availability, load balancing, and proxying for TCP
and HTTP-based applications.
Used for balancing and healtchecking backend connections to redis and postgressql
### 9. [Hashicorp Vault](https://www.vaultproject.io)
Vault secures, stores, and tightly controls access to tokens, passwords, certificates, API keys, and other secrets in modern computing.
the client is used to connect to the Hashicorp Vault server after boot, to retrieve secrets.


## Build
### CI Build
The image is build and pushed into the registry by Jenkins

### Manual build
The image can be build locally, using docker build, as long as the dependecies above are met

## Howto: changes, updates

The image is pinned on a Ubuntu Focal version and needs to be updated every time a new updated tag is released.
The Dockerfile contains information on which CIS Benchmark sections impose which changes.

## Howto: benchmark evaluation

You must use the file "CIS_Ubuntu_Linux_20.04_LTS_Benchmark_v1.1.0-xccdf_eRP_custom.xml", which contains the customized CIS Ubuntu 20.04 benchmark.
The XML contains a new profile "E-Rezept VAU Benchmark" based on the "Server - Level 2" profile and customized for E-Rezept.


To run use the CIS Assessor installed and configured (IBM license) in the docker container:

```
./Assessor-CLI.sh --vulnerability-definitions
./Assessor-CLI.sh --no-timestamp -html -txt --report-prefix="vulnscan" --oval-definitions=/opt/vulnerabilities/com.ubuntu.focal.cve.oval.xml
./Assessor-CLI.sh --no-timestamp -html -txt --report-prefix="hardening" -D ignore.platform.mismatch=true --benchmark=/opt/benchmarks/CIS_Ubuntu_Linux_20.04_LTS_Benchmark_v1.1.0-xccdf_eRP_custom.xml -p "E-Rezept VAU Benchmark"
```

The report should show *no failed tests*.
