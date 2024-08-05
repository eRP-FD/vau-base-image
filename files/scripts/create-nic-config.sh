#!/bin/bash

set -e
set -o pipefail

## find out if we have multiple interfaces connected
if [[ $(ip -br l sh | grep '^en.* UP ' | awk '{ print $1 }' | wc -l) -gt 1 ]]
  then
  ## in case of multiple interfaces connected, create config files for first and last connected interfaces as bond1 slaves
          printf "[Match]\nName=$(ip -br link show | grep '^en.* UP ' | head -n1 | awk '{ print $1 }')\n\n[Network]\nBond=bond1\nPrimarySlave=true\n" > /etc/systemd/network/20-first-nic.network
          printf "[Match]\nName=$(ip -br link show | grep '^en.* UP ' | tail -n1 | awk '{ print $1 }')\n\n[Network]\nBond=bond1\n" > /etc/systemd/network/20-last-nic.network
  else
  ## in case of single interface connected, create config files for connected interface and last disconnected interface as bond1 slaves
          printf "[Match]\nName=$(ip -br link show | grep '^en.* UP ' | head -n1 | awk '{ print $1 }')\n\n[Network]\nBond=bond1\nPrimarySlave=true\n" > /etc/systemd/network/20-first-nic.network
          printf "[Match]\nName=$(ip -br link show | grep '^en.* DOWN ' | tail -n1 | awk '{ print $1 }')\n\n[Network]\nBond=bond1\n" > /etc/systemd/network/20-last-nic.network
fi


## finally, set the MAC address for bond1 as MAC of first connected interface
grep -qF $(cat /sys/class/net/$(ip -br l sh | grep '^en.* UP ' | head -n1 | awk '{ print $1 }')/address) /etc/systemd/network/10-bond1.netdev || sed -i "/^\[NetDev\]/a MACAddress=$(cat /sys/class/net/$(ip -br l sh | grep '^en.* UP ' | head -n1 | awk '{ print $1 }')/address)" /etc/systemd/network/10-bond1.netdev
