FROM de.icr.io/erp_dev/ubuntu-jammy:20250714 as base_hardened

SHELL ["/bin/bash", "-c"]

# Kernel headers are required for sysdig agent installation
ENV KERNEL_VERSION=5.19.0-41-generic

# Hardening start
RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends \
  systemd-sysv \
  dbus \
  udev \
  auditd audispd-plugins \
  apparmor \
  aide \
  chrony \
  iptables iptables-persistent \
  tzdata \
  rsyslog \
  gnupg \
  curl \
  wget \
  jq \
  ca-certificates \
  isc-dhcp-client \
  kmod linux-base \
  && rm -rf /var/lib/apt/lists/*

# Trust the GPGs key, configure the apt repository, and update the package list
COPY files/apt-key/ /usr/share/keyrings/
RUN    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/gramine-keyring.gpg] https://packages.gramineproject.io/ jammy main" > /etc/apt/sources.list.d/gramine.list \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/intel-sgx-deb.asc] https://download.01.org/intel-sgx/sgx_repo/ubuntu jammy main" > /etc/apt/sources.list.d/intel-sgx.list \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/draios.gpg] https://download.sysdig.com/stable/deb stable-\$(ARCH)/" > /etc/apt/sources.list.d/draios.list \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com jammy main" > /etc/apt/sources.list.d/hashicorp.list \
    && apt-get update


# Linux headers required for sysdig sysdigcloud-probe.ko
# python3-lib2to3, python3-distutils fix errors in syslog
# libprotobuf-c-dev  - required by gramine
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends \
    linux-headers-${KERNEL_VERSION} \
    linux-modules-${KERNEL_VERSION} \
    linux-image-unsigned-${KERNEL_VERSION} \
    draios-agent \
    python3-lib2to3 \
    python3-distutils \
    libprotobuf-c-dev \
    gramine=1.9 \
    haproxy \
    vault \
    && rm -f linux-*.deb

RUN ls -al /usr/src/

RUN mkdir /var/config/

# install Cloud Logs agent and libyaml as dependency
# go to https://cloud.ibm.com/docs/cloud-logs?topic=cloud-logs-release-notes-agent for latest agent release
RUN curl -sSO https://logs-router-agent-install-packages.s3.us.cloud-object-storage.appdomain.cloud/logs-router-agent-1.4.2.deb
RUN curl -sSO https://logs-router-agent-install-packages.s3.us.cloud-object-storage.appdomain.cloud/logs-router-agent-1.4.2.deb.sha256
RUN sha256sum -c logs-router-agent-1.4.2.deb.sha256
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends libyaml-0-2
RUN dpkg -i logs-router-agent-1.4.2.deb
RUN rm logs-router-agent*
RUN rm /etc/fluent-bit/fluent-bit.conf
RUN ln -s /var/config/fluent-bit.conf /etc/fluent-bit/fluent-bit.conf
RUN ln -s /var/config/fluent-bit-secrets /etc/default/fluent-bit

# Add script files
COPY files/scripts/cpu-stats.sh /usr/local/bin/
COPY files/scripts/create-nic-config.sh /usr/local/bin/

# Add systemd files
COPY files/etc/systemd/system/aide-fim.timer /etc/systemd/system/
COPY files/etc/systemd/system/aide-fim.service /etc/systemd/system/
COPY files/etc/systemd/system/cpu-stats.timer /etc/systemd/system/
COPY files/etc/systemd/system/cpu-stats.service /etc/systemd/system/

# Add apparmor files
COPY files/etc/apparmor.d/usr.sbin.haproxy /etc/apparmor.d/usr.sbin.haproxy
COPY files/etc/apparmor.d/usr.sbin.chronyd /etc/apparmor.d/usr.sbin.chronyd

# Only wait for the bond1 interface to be online
#COPY files/etc/systemd/system/systemd-networkd-wait-online.service /etc/systemd/system/systemd-networkd-wait-online.service

# service that will create NIC config files for different hardware models and generations
COPY files/etc/systemd/system/create-nic-config.service /etc/systemd/system/create-nic-config.service

# Configure bond network
COPY files/etc/systemd/network/10-bond1.netdev /etc/systemd/network/10-bond1.netdev
COPY files/etc/systemd/network/10-bond1.network /etc/systemd/network/10-bond1.network

# Add configuration files
COPY files/etc/chrony/chrony.conf /etc/chrony/
COPY files/etc/aide/aide.conf /etc/aide/aide.conf
RUN mkdir -p /var/log/aide/

RUN systemctl enable apparmor auditd aide-fim.timer chrony cpu-stats.timer rsyslog dragent haproxy systemd-networkd create-nic-config && \
  systemctl mask systemd-timesyncd

# CIS Hardening section 1.1

# Disabling unneeded filesystems
RUN mkdir -p /etc/modprobe.d/ && \
  echo 'install cramfs /bin/true' > /etc/modprobe.d/cramfs.conf && \
  echo 'install udf /bin/true' > /etc/modprobe.d/udf.conf && \
  echo 'install freevxfs /bin/true' > /etc/modprobe.d/freevxfs.conf && \
  echo 'install jffs2 /bin/true' > /etc/modprobe.d/jffs2.conf && \
  echo 'install hfs /bin/true' > /etc/modprobe.d/hfs.conf && \
  echo 'install hfsplus /bin/true' > /etc/modprobe.d/hfsplus.conf && \
  echo 'install udf /bin/true' > /etc/modprobe.d/udf.conf && \
  echo 'install fat /bin/true' > /etc/modprobe.d/fat.conf && \
  echo 'install vfat /bin/true' > /etc/modprobe.d/vfat.conf && \
  echo 'install msdos /bin/true' > /etc/modprobe.d/msdos.conf && \
  echo 'install usb-storage /bin/true' > /etc/modprobe.d/usb_storage.conf

# CIS hardening section 1.4

# Disabling the root account
RUN passwd -l root && \
  usermod --expiredate 1 root

# CIS hardening section 1.5

# Forbidding kernel dumps
RUN echo '* hard core 0' >> /etc/security/limits.d/15-nodump.conf
RUN echo 'fs.suid_dumpable = 0' > /etc/sysctl.d/15-nodump.conf

# CIS Hardening section 3.3

COPY files/etc/sysctl.d/network-settings.conf /etc/sysctl.d/15-hardening-settings.conf

# Secunet recommendation 3.3.2

COPY files/etc/sysctl.d/kernel-extra.conf /etc/sysctl.d/15-kernel-extra.conf

# CIS Hardening section 3.4

RUN mkdir -p /etc/modprobe.d/ && \
  echo 'install dccp /bin/true' > /etc/modprobe.d/dccp.conf && \
  echo 'install sctp /bin/true' > /etc/modprobe.d/sctp.conf && \
  echo 'install rds /bin/true' > /etc/modprobe.d/rds.conf && \
  echo 'install tipc /bin/true' > /etc/modprobe.d/tipc.conf

# CIS Hardening section 3.5

COPY files/etc/iptables/iptables-rules.v4 /etc/iptables/rules.v4
COPY files/etc/iptables/iptables-rules.v6 /etc/iptables/rules.v6

# CIS Hardening section 4.1

RUN sed -i 's/^max_log_file_action.*/max_log_file_action = keep_logs/; s/^space_left_action.*/space_left_action = email/; s/^write_logs.*/write_logs = no/' /etc/audit/auditd.conf

# If the system can't log anymore, stop the system
RUN echo "admin_space_left_action = halt" >> /etc/audit/auditd.conf

# Monitor privileged files
RUN find / -xdev \( -perm -4000 -o -perm -2000 \) -type f | awk '{print "-a always,exit -F path=" $1 " -F perm=x -F auid!=4294967295 -k privileged" }' >> /etc/audit/rules.d/50-privileged.rules

# Add auditd rules
COPY files/etc/auditd/rules.d/ /etc/audit/rules.d/

# CIS Hardening section 4.2

# Remove syslog configuration and link ours from /var
# Conf file will be downloaded at runtime
RUN mkdir -p /var/config/rsyslog.d/ && \
  rm -r /etc/rsyslog.d && \
  ln -s /var/config/rsyslog.d /etc/rsyslog.d

# CIS Hardening section 4.4

RUN echo "create 0640 root utmp" > /etc/logrotate.conf && \
  sed -i 's/^\(\s*create\)\s[0-9]*/\1 0640/' /etc/logrotate.d/*

# CIS Hardening section 5.5

RUN echo umask 027 > /etc/profile.d/set_umask.sh && \
  sed -i 's/UMASK\s.*/UMASK 027/' /etc/login.defs && \
  echo "readonly TMOUT=300 ; export TMOUT"  > /etc/profile.d/set_timeout.sh

# CIS Hardening section 5.5

RUN echo "# No console allowed for root login" > /etc/securetty

# Custom hardening

# Disable console (to test via XClarity)
RUN echo -e "NAutoVTs=0\nReserveVT=0" >> /etc/systemd/logind.conf && \
  systemctl mask getty-static

# Disable banner
RUN echo > /etc/issue.net && \
  echo > /etc/issue

# Hardening end

# Precompile python caches for aide
RUN python3 -m compileall /usr/lib/python3/dist-packages/graminelibos/

WORKDIR /sgx
# Install packages, respecting their dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    libsgx-epid libsgx-quote-ex libsgx-dcap-ql

# remove compilers (installed as sysdig dependencies) 
RUN dpkg --force-depends -P binutils binutils-common binutils-x86-64-linux-gnu bzip2 cpp cpp-11 cpp-12 dctrl-tools distro-info-data dpkg-dev gcc gcc-11 gcc-11-base gcc-12 gcc-12-base libasan6 libasan8 libatomic1 libbinutils libcc1-0 libctf0 libctf-nobfd0 libdpkg-perl libgcc-11-dev libgcc-12-dev libgdbm6 libgdbm-compat4 libgomp1 libisl23 libitm1 liblsan0 libmpc3 libmpfr6 libperl5.34 libquadmath0 libtsan0 libtsan2 libubsan1 lsb-release lto-disabled-list make patch perl perl-modules-5.34 xz-utils 2>/dev/null

# Add users generated by systemd
RUN useradd -d / -s /usr/sbin/nologin -U -r systemd-timesync
RUN useradd -d / -s /usr/sbin/nologin -U -r systemd-coredump

# Increase wait time for rsyslog service (mitigation for issue ERP-16199) and reverse start order with haproxy
RUN sed -i 's/^Restart=on-failure/Restart=on-failure\nTimeoutStartSec=300/' /lib/systemd/system/rsyslog.service
RUN sed -i 's/^After=network-online.target.*/Before=rsyslog.service\nAfter=network-online.target/' /lib/systemd/system/haproxy.service

# Disable XCC interface added by udev
RUN rm /usr/lib/udev/rules.d/73-special-net-names.rules

# Clean up apt
RUN systemctl mask apt-daily.timer && \
    systemctl mask apt-daily-upgrade.timer && \
    rm /var/log/dpkg.log
