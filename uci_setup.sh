#!/bin/sh

SERVER=$1
TOKEN=$2

[ -n "$TOKEN" ] || exit 1

uci import reliable </dev/null
uci add reliable globals
uci set reliable.@globals[0].hostname="$SERVER"

cfg=$(uci add reliable push_monitor)
uci batch <<EOI
set reliable.$cfg.interface='wwan0'
set reliable.$cfg.token='$TOKEN'
set reliable.$cfg.report_latency=1
set reliable.$cfg.enabled=1
EOI

cfg=$(uci add reliable push_monitor)
uci batch <<EOI
set reliable.$cfg.interface='eth1'
set reliable.$cfg.token='none'
set reliable.$cfg.report_latency=0
set reliable.$cfg.enabled=0
EOI

uci commit

#set up cron
sed -i "/#uptime_push$/d" /etc/crontabs/root
cat <<EOF >>/etc/crontabs/root
*/5 * * * * /etc/rn/uptime_monitor >/dev/null 2>/dev/null #uptime_push
EOF
/etc/init.d/cron reload

#ensure rn dir persists
if ! grep -q '^/etc/rn$' /etc/sysupgrade.conf; then
	echo "/etc/rn" >>/etc/sysupgrade.conf
fi
