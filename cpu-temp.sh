#!/bin/bash
# Output JSON: {cpu, mem_percent, mem_used_gb, mem_total_gb, temp}

read_cpu() {
  read -r _ user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
  total=$((user + nice + system + idle + iowait + irq + softirq + steal))
  active=$((user + nice + system + irq + softirq + steal))
  echo "$total $active"
}

read -r total1 active1 <<< "$(read_cpu)"
sleep 0.5
read -r total2 active2 <<< "$(read_cpu)"

totald=$((total2 - total1))
actived=$((active2 - active1))

if [ "$totald" -gt 0 ]; then
  cpu=$((actived * 100 / totald))
else
  cpu=0
fi

memtotal_kb=$(awk '/^MemTotal:/{print $2}' /proc/meminfo)
memavail_kb=$(awk '/^MemAvailable:/{print $2}' /proc/meminfo)
if [ -z "$memavail_kb" ]; then
  memavail_kb=$(awk '/^MemFree:/{print $2}' /proc/meminfo)
fi

memused_kb=$((memtotal_kb - memavail_kb))
mem_percent=$((memused_kb * 100 / memtotal_kb))
mem_used_gb=$(awk "BEGIN{printf \"%.1f\", $memused_kb/1024/1024}")
mem_total_gb=$(awk "BEGIN{printf \"%.1f\", $memtotal_kb/1024/1024}")

temp=""
for d in /sys/class/hwmon/hwmon*; do
  name=$(cat "$d/name" 2>/dev/null)
  if [ "$name" = "coretemp" ] || [ "$name" = "k10temp" ] || [ "$name" = "zenpower" ]; then
    t=$(cat "$d/temp1_input" 2>/dev/null)
    if [ -n "$t" ] && [ "$t" != "0" ]; then
      temp=$t
      break
    fi
  fi
done

if [ -z "$temp" ]; then
  for d in /sys/class/hwmon/hwmon*; do
    t=$(cat "$d/temp1_input" 2>/dev/null)
    if [ -n "$t" ] && [ "$t" != "0" ]; then
      temp=$t
      break
    fi
  done
fi

if [ -z "$temp" ]; then
  for z in /sys/class/thermal/thermal_zone*; do
    t=$(cat "$z/temp" 2>/dev/null)
    if [ -n "$t" ] && [ "$t" != "0" ]; then
      temp=$t
      break
    fi
  done
fi

if [ -n "$temp" ]; then
  temp_c=$((temp / 1000))
else
  temp_c="null"
fi

echo "{\"cpu\":$cpu,\"mem_percent\":$mem_percent,\"mem_used_gb\":$mem_used_gb,\"mem_total_gb\":$mem_total_gb,\"temp\":$temp_c}"
