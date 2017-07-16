#!/bin/bash
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~~                                                          ~~"
echo "~~ Home Assistant - SmartThings HomeBridge Installer Script ~~"
echo "~~                                                          ~~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run with sudo."
   echo "Please use: \"sudo ${0} ${*}\"" 1>&2
   exit 1
fi

echo
echo  "Please take a moment to setup your first MQTT user"

echo -n "~~~~~~~~~~~~~~~~~~~~~~< MQTT Username >~~~~~~~~~~~~~~~~~~~~~~~

	~ Choose a UserName for Mosquitto MQTT.

Enter Username > "
read -r mqtt_username

echo
echo -n "~~~~~~~~~~~~~~~~~~~~~~< MQTT Password >~~~~~~~~~~~~~~~~~~~~~~~

	~ Choose a password for Mosquitto MQTT.

Enter Password > "
read -s mqtt_password

echo
echo -n "~~~~~~~~~~~~~~~~~~~~~< MQTT Broker IP >~~~~~~~~~~~~~~~~~~~~~~~

	~ Enter the MQTT host IP.
	~ Examples: '192.168.x.x' or 'hassbian.local' or localhost

Enter Broker > "
read -r mqtt_broker

echo
echo "~~~~~~~~~~~~~~~~~~~~~< Running apt-get preparation.."
echo "(this my take a while)"
sudo apt-get update
sudo apt-get upgrade -y

echo
echo "~~~~~~~~~~~~~~~~~~~~~< Install Avahi (HomeKit Support)"
sudo apt-get install -y libavahi-compat-libdnssd-dev

echo
echo "~~~~~~~~~~~~~~~~~~~~~< Install 'hassbian-config' Scripts"
echo "Insralling Samba.."
sudo hassbian-config install samba
echo "Insralling Mosquitto.."
sudo hassbian-config install mosquitto
expect "Username: "
send "$mqtt_username"
expect "Password: "
send "$mqtt_password"
cat >> /home/homeassistant/.homeassistant/configuration.yaml <<EOF

## MQTT server (pull devices from SmartThing's 'MQTT Bridge' smartapp)
mqtt:
  broker: $mqtt_broker
  port: 1883
  client_id: home-assistant-1
  username: $mqtt_username
  password: $mqtt_password
EOF

echo
echo "~~~~~~~~~~~~~~~~~~~~~< Installig node.js 7.x and npm.."
curl -sL https://deb.nodesource.com/setup_7.x | sudo -E bash -
sudo apt-get install -y nodejs

echo
echo "~~~~~~~~~~~~~~~~~~~~~< Installig SmartThings to MQTT bridge.."
echo "(Pull devices from SmartThing's 'MQTT Bridge' SmartApp)"
sudo npm install -g smartthings-mqtt-bridge

echo
echo "Configuring smartthings-mqtt-bridge's config.yml.."
cat >> /home/pi/config.yml <<EOF
---
mqtt:
    # Specify your MQTT Broker's hostname or IP address here
    host: mqtt://$mqtt_broker
    # Preface for the topics $PREFACE/$DEVICE_NAME/$PROPERTY
    preface: smartthings

    # Suffix for the state topics $PREFACE/$DEVICE_NAME/$PROPERTY/$STATE_SUFFIX
    # state_suffix: state
    # Suffix for the command topics $PREFACE/$DEVICE_NAME/$PROPERTY/$COMMAND_SUFFIX
    # command_suffix: cmd

    # Other optional settings from https://www.npmjs.com/package/mqtt#mqttclientstreambuilder-options
    username: $mqtt_username
    password: $mqtt_password

# Port number to listen on
port: 8080
EOF


echo
echo "~~~~~~~~~~~~~~~~~~~~~< Installing HomeBridge.."
echo "(HomeKit suppoot)"
sudo npm install -g --unsafe-perm homebridge

echo
echo "~~~~~~~~~~~~~~~~~~~~~< Installing HomeBridge HomeAssistant support plugin.."
sudo npm install -g homebridge-homeassistant

echo
echo "Configureing 'smartthings-mqtt-bridge' in HomeBridge.."
cat >> /home/pi/.homebridge/config.json <<EOF
{
   "bridge":{
      "name":"Homebridge",
      "username":"CC:22:3D:E3:CE:30",
      "port":51826,
      "pin":"031-45-154"
   },
   "platforms":[
      {
         "platform":"HomeAssistant",
         "name":"HomeAssistant",
         "host":"http://localhost:8123",
         "password": "",
         "supported_types":[
            "binary_sensor",
            "climate",
            "cover",
            "device_tracker",
            "fan",
            "group",
            "input_boolean",
            "light",
            "lock",
            "media_player",
            "scene",
            "sensor",
            "switch"
         ],
         "logging":true
      }
   ]
}
EOF

echo
echo "~~~~~~~~~~~~~~~~~~~~~< Install Harmony API"
echo "Better server for speed up harmony devices responce"
sudo npm install forever -g
git clone https://github.com/maddox/harmony-api.git harmony_api
sudo harmony_api/script/bootstrap
cat >> /home/pi/harmony_api/config/config.json <<EOF
{
  "mqtt_host": "mqtt://$mqtt_broker",
  "mqtt_options": {
      "port": 1883,
      "username": "$mqtt_username",
      "password": "$mqtt_password",
      "rejectUnauthorized": false
  }
}
EOF

echo
echo "~~~~~~~~~~~~~~~~~~~~~< Install pm2"
sudo npm install pm2 -g

echo
echo "~~~~~~~~~~~~~~~~~~~~~< Updete stuff for good practice"
sudo apt-get update

echo
echo "~~~~~~~~~~~~~~~~~~~~~< Cofigure PM2 autostart on boot"
echo "for the services: smartthings-mqtt-bridge / homebridge / harmony-api"
sudo pm2 start smartthings-mqtt-bridge
sudo pm2 start homebridge
sudo pm2 start harmony_api/app.js --name harmony-api
sudo pm2 ls
sudo pm2 save
sudo pm2 startup

echo
echo "Done."
echo
echo "Rebooting.."
sudo reboot
