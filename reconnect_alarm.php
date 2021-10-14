#!/usr/bin/php
<?php
require_once '/etc/alarmmonitor/Unifi-Client.php';
// Update the following line and include your Unifi Controller IP
$controller_url = "https://192.168.1.1:443";
// Update the following line and include the username of the Limited Admin account you created
$controller_user = "username";
// Update the following line and include the password of the Limited Admin account you created
$controller_password = "password";
// Leave site_id unless you run multiple sites.  I do not, YMMV.
$site_id = "default";
// Update this to match the version of the Network controller on your Unifi Controller
$controller_version = "6.2.26";
$alarm_mac = $argv[1];
$unifi_connection = new UniFi_API\Client($controller_user, $controller_password, $controller_url, $site_id, $controller_version, false);
$login            = $unifi_connection->login();
$reconnect        = $unifi_connection->reconnect_sta($alarm_mac);
