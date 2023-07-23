#!/bin/bash
echo $(printf '{"date":"';date '+%s' | tr '\n' '"'; printf ','; for i in {0..15}; do printf "\"cpu${i}\":"; cat /sys/devices/system/cpu/cpufreq/policy${i}/scaling_cur_freq | tr -d '\n'; printf ',';done; printf '"throttle_count":';cat /sys/devices/system/cpu/cpu0/thermal_throttle/package_throttle_count | tr -d '\n'; printf '}\n') >> /var/log/erp/cpu-stats.log
