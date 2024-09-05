#!/bin/sh

# export the vars below or supply them as args
if [ -n "$3" ]; then
	SERVER=$1
	TOKEN=$2
	QMI_IFACE=$3
fi

if [ -z "$TOKEN" ] || [ "$TOKEN" = "0000000000" ]; then
	echo "invalid TOKEN"
	exit 1
fi

if [ -z "$SERVER" ]; then
	echo "invalid SERVER"
	exit 1
fi

# you can specify 'auto' for this to have the script derive it at runtime
if [ -z "$QMI_IFACE" ]; then
	QMI_IFACE=$(ubus -S call networkmap interfaces | jsonfilter -e '@.interfaces[@.proto="wwan" && @.status=true].device')
	if [ -z "$QMI_IFACE" ]; then
		echo "could not determine qmimux interface"
		exit 1
	fi
fi

uci import reliable </dev/null
uci add reliable globals
uci set reliable.@globals[0].hostname="$SERVER"

cfg=$(uci add reliable push_monitor)
uci batch <<EOI
set reliable.$cfg.interface='$QMI_IFACE'
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
*/5 * * * * /etc/rn/uptime_monitor.sh >/dev/null 2>&1 #uptime_push
EOF
/etc/init.d/cron reload

#ensure rn dir persists
if ! grep -q '^/etc/rn$' /etc/sysupgrade.conf; then
	echo "/etc/rn" >>/etc/sysupgrade.conf
fi

#init
/etc/rn/uptime_monitor.sh
