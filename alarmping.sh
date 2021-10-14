#!/bin/bash
# Setup required variables
########################################################################################
# ALARMIPS is an array of Alarm device IPs on your LAN, separated by spaces.  Do not remove the () brackets
ALARMIPS=(192.168.100.1)
# ALARMMACS is an array of Alarm device MAC addresses, on your LAN, in quotes, separated by spaces.  Do not remove the () brackets
ALARMMACS=("aa:bb:cc:dd:ee:ff")
# ALARMNAMES is an array of Alarm device names, separated by spaces.  Do not remove the () brackets
ALARMNAMES=(SmartCom)
# NOTE : The order of Alarm IP, MAC and Name should match in each array set.
# LOGLOCATION is the location of your log files
LOGLOCATION="/var/log/alarmmonitor"
# LOGFILENAME is the name of your AlarmPing log
LOGFILENAME=log
# PINGINTERVAL is the period (in seconds) between each check
# NOTE : Each listed device will be checked at each interval.
#        If the device does not respond to a ping, and you have multiple devices
#        You may encounter a situation where the pings take longer to complete than PINGINTERVAL
#        This may cause delays in monitoring
#        Allow up to 10 seconds for a ping to fail
#        PINGINTERVAL should be >= 10 x No. of your devices (i.e. 30 for 3 devices)
PINGINTERVAL=30
########################################################################################
# Do not edit below this section
########################################################################################
LOGFILE="$LOGLOCATION/$LOGFILENAME"
ALARMIPCOUNT=${#ALARMIPS[@]}
ALARMMACCOUNT=${#ALARMMACS[@]}
ALARMNAMECOUNT=${#ALARMNAMES[@]}
OKTOSTART=0
# Verify that we have the same number of IPs and MAC addresses
if [ $ALARMIPCOUNT -ne $ALARMMACCOUNT ]; then
        echo "$ALARMTIME : No. of Alarm IPs does not match No. of Alarm MACs.  Please resolve. Exiting" >> $LOGFILE
        exit 1;
else
        OKTOSTART=1
fi
# Verify that we have the same number of IPs and Names
if [ $ALARMIPCOUNT -ne $ALARMNAMECOUNT ]; then
        echo "$ALARMTIME : No. of Alarm IPs does not match No. of Alarm Names.  Please resolve. Exiting" >> $LOGFILE
        exit 1;
else
        OKTOSTART=1
fi
# Set the alarm count, ping check and start time
ALARMCOUNT=${#ALARMIPS[@]}
CORRECTPINGLINES=0
STARTTIME=`date`
# Double check we are ok to start...
if [ $OKTOSTART -eq 1 ]; then
        echo "$STARTTIME : Alarmping started successfully." >> $LOGFILE
        # Run permanently...
        while true; do
                # For each alarm...
                for ((i=1;i<=${#ALARMIPS[@]};i++));
                do
                        # Loop runs from 1, but array runs from zero, so set an array tracker...
                        LoopVar=`expr $i - 1`
                        # Ping the currently looped IP and check it's reachable...
                        PINGCHECK=`ping -c 1 ${ALARMIPS[$LoopVar]} | grep -i unreachable | wc -l`
                        # If it's not reachable...
                        if [ $PINGCHECK != $CORRECTPINGLINES ]; then
                                # Log the time the alarm was last seen
                                ALARMTIME=`date`
                                if [ -f $LOGLOCATION/lastseen$i ]; then
                                        LASTSEEN=`cat $LOGLOCATION/lastseen$i`
                                else
                                        LASTSEEN="NOT SINCE ALARMPING STARTUP"
                                fi
                                echo "$ALARMTIME : ${ALARMNAMES[$LoopVar]} not connected. Last seen : $LASTSEEN" >> $LOGFILE
                                echo "$ALARMTIME : Attempting to force ${ALARMNAMES[$LoopVar]} reconnection...." >> $LOGFILE
                                # Call the alarm reconnection script
                                /etc/alarmmonitor/reconnect_alarm.php ${ALARMMACS[$LoopVar]}
                                # Forcibly delete the online marker, create/update the offline marker
                                rm -f $LOGLOCATION/online$i
                                touch $LOGLOCATION/offline$i
                        else
                                # Alarm IS reachable
                                LASTSEEN=`date`
                                ALARMTIME=$LASTSEEN
                                # Check if Alarm was previously flagged offline...
                                if [ -f $LOGLOCATION/offline$i ]; then
                                        # Remove offline marker and log re-detection
                                        rm -f $LOGLOCATION/offline$i
                                        echo "$ALARMTIME : ${ALARMNAMES[$LoopVar]} detected : $LASTSEEN" >> $LOGFILE
                                fi
                                # Update last seen and online markers
                                echo $LASTSEEN > $LOGLOCATION/lastseen$i
                                touch $LOGLOCATION/online$i
                        fi
                done
                # Sleep for defined internal
                sleep $PINGINTERVAL
        done
else
        # We really shouldn't see this...
        echo "$STARTTIME : Alarmping failed to start." >> $LOGFILE
fi
