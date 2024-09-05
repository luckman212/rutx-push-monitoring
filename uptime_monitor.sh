#!/bin/sh

h=$(uci -q get reliable.@globals[0].hostname)
fw_name=$(uci -q get system.system.hostname)

n=0
while uci -q get reliable.@push_monitor[$n] >/dev/null; do
  if [ $(uci -q get reliable.@push_monitor[$n].enabled) = 1 ]; then
    interface=$(uci -q get reliable.@push_monitor[$n].interface)
    token=$(uci -q get reliable.@push_monitor[$n].token)
    report_latency=$(uci get reliable.@push_monitor[$n].report_latency)
	if [ "$interface" = "auto" ]; then
	  interface=$(grep -m1 qmimux /var/run/qmux/mob1s1a1.up)
	  if [ -z "$interface" ]; then
	    exit 1
	  fi
	fi
    echo "processing $interface"
    if [ $report_latency = 1 ]; then
      echo "pinging $h via $interface"
      t=$(/bin/ping -c3 -W5 -s256 -I $interface -q $h | awk -F/ '/ms$/{ print int($4) }')
      [ -n "$t" ] && echo "result: $t"
    else
      unset lat
    fi
    api="https://$h/api/push/$token"
    echo "sending push to $api via interface $interface"
    /usr/bin/curl -so /dev/null \
      --interface $interface \
      --max-time 10 \
      --retry 2 \
      --retry-delay 5 \
      "$api?status=up&msg=$fw_name%20UP&ping=$t"
  fi
let n++
done
echo "done"
