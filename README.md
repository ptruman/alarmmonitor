# alarmmonitor
Bash script to monitor wireless devices IP connectivity on a Unifi network, and force reconnection if they lose IP but remain associated to an Access Point.

# Overview / My Use Case
I use a [Texecom](https://www.texe.com/) alarm system in my house, which is connected to the Internet (and Texecom Cloud) via IP.  The alarm uses a Texecom "SmartCom" device for it's connectivity, which can be wired or wirelessly connected. Due to building issues, mine is connected wirelessly.  I also fitted a ComWIFI communicator in the panel so I can monitor and administer the panel without interfering wth the Texecom Cloud monitoring.  Every so often, signal issues mean the devices can remain 'associated' to the Wireless Access Point (WAP), but not retain a full IP connection (i.e. won't ping)

I also run a Unifi network in my house, which has an API, meaning I can force wireless devices to disconnect/reconnect - which typically resolves the issue. 

If I was away from home, and the devices had a WiFi blip, I would lose reporting, or (if at home) potentially lose admin access - and have to login to my controller and manually kick the device.

This script is the result of wanting to be lazy 😃

You could in theory use this script to monitor any wireless device connectivity on a Unifi WLAN.

# Requirements
You will need:
* A [Unifi](https://ui.com) Dream Machine network controller (UDM Pro or UDM Base)
* One or more Unifi Wireless Access Points (UDM Base contains it's own WAP)
* A [Texecom Premier Elite](https://www.texe.com/uk/products/series/control-panels/premier-elite-series/) series alarm panel with an IP based [Texecom Premier Elite series communicator](https://www.texe.com/uk/products/series/communicators/premier-elite-series/) (i.e. SmartCom 4G, SmartCom, ComIP or ComWIFI)<br/>***OR***<br/>a WiFi device you want to monitor...
* A Linux box with a Bash shell and Perl 7.3 or higher

# Instructions
1. On your Unifi controller
   1. Create a "Limited Admin" user and make a note of the username and password you assign
2. On your Linux box
   1. Create a folder such as */etc/alarmmonitor*
   2. Create a log folder such as /var/log/alarmmonitor
   3. Copy the **alarmping.sh** and **reconnect_alarm.php** scripts into the */etc/alarmmonitor* folder
   4. Check both scripts are readable/executable via whatever account you wish to run the monitor under (esp. if you are going to wrap it as a service
   5. Check that **reconnect_alarm.php** is not readable by anyone you don't want being able to see your new Controller credentials
   6. Check that the log folder you created in (3) above is read/writeable by the same account
   7. Edit the **alarmping.sh** script
      1. Add the IP or IPs for your alarm devices in **ALARMIPS**<br/>
      i.e. `ALARMIPS=(192.168.100.1)* or *ALARMIPS=(192.168.100.1 192.168.100.2*)`
      2. Add the MAC address or addresses for your alarm devices in **ALARMMACS**<br/>
      i.e. `ALARMMACS=(xx:xx:xx:xx:xx:xx)* or *ALARMMACS=(xx:xx:xx:xx:xx:xx yy:yy:yy:yy:yy:yy)`
      3. Add the "nice names" for your alarm devices in **ALARMNAMES**<br/>
      i.e. `ALARMNAMES=(SmartCom)* or *ALARMNAMES=(SmartCom ComWIFI)`
      4. Set **LOGLOCATION** to the location you set in (3)<br/>
      i.e. `LOGLOCATION=/var/log/alarmmonitor`
      5. If you don't want the actual log *file* to be called **log** change update LOGFILENAME
      6. If you have only 1-3 devices to monitor, leave **PINGINTERVAL** at *30*.  If you have *more* than 3, set PINGINTERVAL to 10 * X (where X is the number of devices) - so for 4 devices, you would have..<br/>
      `PINGINTERVAL=40`
   7. Edit the **reconnect_alarm.php** script
      1. Update **controller_url** to include your Unifi controller IP, i.e.<br/>
      `$controller_url = "https://192.168.1.1:443";`
      2. Update **$controller_user** to be the username you specified in (1.1)
      3. Update **$controller_password** to be the username you specified in (1.1)
      4. Unless you are running a controller for multiple sites, leave *site_id* as *default*
      5. Update **$controller_version** to match the Network Controller version shown on your Unifi Controller home screen
   9. Execute the script in the background OR wrap it as a service and start it.  If running as a script, run
      1. `/bin/bash /etc/alarmmonitor/alarmping.sh &`
   10. Check you have a logfile, lastseen files and some online (or potentially offline) files

# Normal Operation
The **alarmping.sh** script will ping your defined devices periodically, as defined in PINGINTERVAL.  If it does not get a response, it decides the device is not reachable, and calls the **reconnect_alarm.php** script with the MAC address of the specific device.  That will instruct the Unifi controller to 'disconnect' the MAC address.  The end device will then attempt a reconnection itself, which typically resolves most issues, until another signal drop occurs.

# Logging
* The log file will include timestamped entries - which hopefully will only ever be when the script starts 😃
* If the script detects a drop you should see a message that the name of the relevant device is not connected, and that it is attempting a reconnection.  It also lists the time that the device was last seen.
* You will see files called *online***x** or *offline***x** based on the number of the device as entered in ALARMIPS - for a quick and easy view via ls
* The *lastseen***x** files contain the timestamp of the time a device was last seen.
