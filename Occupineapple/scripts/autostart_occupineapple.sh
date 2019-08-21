#!/bin/sh
#2015 - Whistle Master

LOG=/tmp/occupineapple.log
MYPATH='/pineapple/modules/Occupineapple/'

MYMONITOR=''
MYINTERFACE=`uci get occupineapple.autostart.interface`
MYLIST=`uci get occupineapple.autostart.list`

SPEED=`uci get occupineapple.settings.speed`
CHANNEL=`uci get occupineapple.settings.channel`

OPTIONS=''
WPAAES=`uci get occupineapple.settings.wpaAES`
VALIDMAC=`uci get occupineapple.settings.validMAC`
ADHOC=`uci get occupineapple.settings.adHoc`
WEPBIT=`uci get occupineapple.settings.wepBit`
WPATKIP=`uci get occupineapple.settings.wpaTKIP`

killall -9 mdk3
rm ${LOG}

echo -e "Starting Occupineapple..." > ${LOG}

if [ -z "$MYINTERFACE" ]; then
	MYINTERFACE=`iwconfig 2> /dev/null | grep "Mode:Master" | awk '{print $1}' | head -1`
else
	MYFLAG=`iwconfig 2> /dev/null | awk '{print $1}' | grep ${MYINTERFACE}`

	if [ -z "$MYFLAG" ]; then
	    MYINTERFACE=`iwconfig 2> /dev/null | grep "Mode:Master" | awk '{print $1}' | head -1`
	fi
fi

if [ -z "$MYMONITOR" ]; then
	MYMONITOR=`iwconfig 2> /dev/null | grep "Mode:Monitor" | awk '{print $1}' | head -1`

	MYFLAG=`iwconfig 2> /dev/null | awk '{print $1}' | grep ${MYMONITOR}`

	if [ -z "$MYFLAG" ]; then
	    airmon-ng start ${MYINTERFACE}
	    MYMONITOR=`iwconfig 2> /dev/null | grep "Mode:Monitor" | awk '{print $1}' | head -1`
	fi
else
	MYFLAG=`iwconfig 2> /dev/null | awk '{print $1}' | grep ${MYMONITOR}`

	if [ -z "$MYFLAG" ]; then
	    airmon-ng start ${MYINTERFACE}
	    MYMONITOR=`iwconfig 2> /dev/null | grep "Mode:Monitor" | awk '{print $1}' | head -1`
	fi
fi

echo -e "Interface : ${MYINTERFACE}" >> ${LOG}
echo -e "Monitor : ${MYMONITOR}" >> ${LOG}

if [ "$MYLIST" != "--" ] && [ -n "$MYLIST" ]; then
	echo -e "List : ${MYLIST}" >> ${LOG}

  uci set occupineapple.run.list=${MYLIST}
  uci commit occupineapple.run.list

	MYFLAG=`echo ${MYLIST} | awk '{print match($0,".mlist")}'`;

	if [ ${MYFLAG} -gt 0 ];then
		MYLIST="-v ${MYPATH}lists/${MYLIST}"
	else
		MYLIST="-f ${MYPATH}lists/${MYLIST}"
	fi
else
	echo -e "List : random" >> ${LOG}
	MYLIST=

  uci set occupineapple.run.list=${MYLIST}
  uci commit occupineapple.run.list
fi

if [ -n "$SPEED" ]; then
	echo -e "Speed : ${SPEED}" >> ${LOG}
	SPEED="-s ${SPEED}"
else
	echo -e "Speed : default" >> ${LOG}
	SPEED=
fi

if [ -n "$CHANNEL" ]; then
	echo -e "Channel : ${CHANNEL}" >> ${LOG}
	CHANNEL="-c ${CHANNEL}"
else
	echo -e "Channel : default" >> ${LOG}
	CHANNEL=
fi

if [ "$WPAAES" != "0" ]; then OPTIONS="-a"; fi
if [ "$VALIDMAC" != "0" ]; then OPTIONS="${OPTIONS} -m"; fi
if [ "$ADHOC" != "0" ]; then OPTIONS="${OPTIONS} -d"; fi
if [ "$WEPBIT" != "0" ]; then OPTIONS="${OPTIONS} -w"; fi
if [ "$WPATKIP" != "0" ]; then OPTIONS="${OPTIONS} -t"; fi

ifconfig ${MYINTERFACE} down
ifconfig ${MYINTERFACE} up

uci set occupineapple.run.interface=${MYMONITOR}
uci commit occupineapple.run.interface

mdk3 ${MYMONITOR} b ${SPEED} ${CHANNEL} ${OPTIONS} ${MYLIST} >> ${LOG} &
