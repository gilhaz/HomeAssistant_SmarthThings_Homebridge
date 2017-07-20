# HomeAssistant_SmarthThings_Homebridge
My setup process to install and configuration of Hassbian to work with SmartThings and HomeBridge

#### Intgrate to HomeAssistant the following:
- Mosquitto
- Samba
- SmartThings
- HomeBridge
- Harmony-api

### :warning: note  
**only tested on Raspberry Pi 3 with Hassbian after [clean install](https://home-assistant.io/docs/hassbian/installation/) and you already have home assistant up and running.**

## Installation Instructions
### Set up your local and update
```sh
sudo raspi-config
```

### 'apt-get' Update Preperations
```sh
sudo apt-get update
sudo apt-get upgrade -y
```

### Install Avahi (HomeKit Support)
Development headers for the Avahi Apple Bonjour compatibility library
```sh
sudo apt-get install -y libavahi-compat-libdnssd-dev
```

### Install Samba and Mosquitto with 'hassbian-config'
* More info on [hassbian-config](https://github.com/home-assistant/hassbian-scripts)
```sh
sudo hassbian-config install samba
sudo hassbian-config install mosquitto
```
##### Choose username and password in the mosquitto install process and wright them down! They will be use for configure mqtt.
##### If you use the install guide as is, the username is 'user' and password 'password'
> To connect to Samba file sharing from Mac:
> When on the deasktop go to > Go > Connect to Server... or press [cmd] [K]
> Insert: smb://hassbian.local/homeassistant 
> And log in as 'gest'
>
> Mosquitto is install through systemctl, you can use: 
> sudo systemctl ['start'/'stop'/'enable'/'disable'] mosquitto

### configure mosquitto-mqtt in homeAssistant conf
```sh
sudo nano /home/homeassistant/.homeassistant/configuration.yaml
```

#### past this at the end of the file:
```sh
## mosquitto mqtt server
mqtt:
  broker: localhost
  port: 1883
  client_id: home-assistant-1
  username: user
  password: password
```
 
### restart home-assistant
```sh
sudo systemctl restart home-assistant@homeassistant.service
```
> chack you can see the 'mqtt' domain in hass services
> http://localhost:8123/dev-service

### Install node.js 7.x and npm
Adding the NodeSource APT repository for Debian-based distributions repository AND the PGP key for verifying packages
```sh
curl -sL https://deb.nodesource.com/setup_7.x | sudo -E bash -
```
### install Node.js v7.x and npm
```sh
sudo apt-get install -y nodejs
```

### install smartthings-mqtt-bridge (link smartthings devices to hass)
Instructions here: [Smarter-Smart-Things-with-MQTT-and-Home-Assistant](https://home-assistant.io/blog/2016/02/09/Smarter-Smart-Things-with-MQTT-and-Home-Assistant/)
> only the 'SMARTTHINGS DEVICE' and 'SMARTTHINGS APP' parts.
### install smartthings to mqtt bridge (pull devices from SmartThing's 'MQTT Bridge' smartapp)
```sh
sudo npm install -g smartthings-mqtt-bridge
```
### run it once
```sh
sudo smartthings-mqtt-bridge
```
> exit with [ctrl] [c]
### configure smartthings-mqtt-bridge
this file is automaticly create after first start of 'smartthings-mqtt-bridge'
```sh
sudo nano config.yml
```
### config mqtt in smartthings-mqtt-bridge
```sh
host: mqtt://localhost
username: user
password: password
```

### chack the bridge is publish events
##### open 2 terminal windows
##### first:
```sh
sudo smartthings-mqtt-bridge
```
#### second:
```sh
sudo mosquitto_sub -u user -P password -v -t '#'
```
> exit both with [ctrl] [c]
### install homebridge (HomeKit suppoot)
```sh
sudo npm install -g --unsafe-perm homebridge
```
### install homebridge homeassistant support plugin
```sh
sudo npm install -g homebridge-homeassistant
```
### run once
```sh
homebridge
```
> exit with [ctrl] [c]
### Configure smartthings-mqtt-bridge in homebridge
```sh
sudo nano /home/pi/.homebridge/config.json # or .homebridge/config.json
```
### past this:
```sh
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
```
> the ["password": "",] is the password you set for home assistant gui, leave blank if you didn't set one.
### run homebridge and chack you get updates from '[HomeAssistant]'
```sh
homebridge
```
### Install Harmony API
install Forefer (harmony-api dependency)
```sh
sudo npm install forever -g
```
### download harmony api from github
```sh
git clone https://github.com/maddox/harmony-api.git harmony_api
```
### Install Harmony API
```sh
sudo harmony_api/script/bootstrap
```
### config mqtt in harmony api
```sh
sudo nano harmony_api/config/config.json
```
### past this:
```sh
{
  "mqtt_host": "mqtt://localhost",
  "mqtt_options": {
      "port": 1883,
      "username": "user",
      "password": "password",
      "rejectUnauthorized": false
  }
}
```
> Chack harmony api is discovering the hub and publish to mqtt (may take a minute to show)
### open 2 terminal windows
### first:
```sh
sudo harmony_api/script/server
```
### second:
```sh
sudo mosquitto_sub -u user -P password -v -t '#'
```
> look for somthing like 'harmony-api/hubs/...'
> exit both with [ctrl] [c]

### Install pm2
#### install mp2 to manage the autostart on boot for the 'smartthings-mqtt-bridge', 'homebridge' and 'harmony-api' servivces
```sh
sudo npm install pm2 -g
```

### Update stuff for good practice
```sh
sudo apt-get update
```
### Configure pm2 autostart
```sh
sudo pm2 start smartthings-mqtt-bridge
sudo pm2 start harmony_api/app.js --name harmony-api
sudo pm2 ls # check everything is green
pm2 start homebridge
sudo pm2 save
pm2 save
sudo pm2 startup
pm2 startup
```

### Check everything is working
```sh
sudo reboot
sudo mosquitto_sub -u user -P password -v -t '#'
```
> start an activity thru Harmony app
> search for an update like: 'harmony-api/hubs/harmonylrhub/current_activity tv'
> turn on a switch in SmartThings app
> search for an update like: 'smartthings/Living Room Light/switch on'


### Useful commands
```sh
sudo mosquitto_sub -u user -P password -v -t '#'
sudo nano /home/homeassistant/.homeassistant/configuration.yaml
mosquitto_pub -d -u user -P password -t harmony-api/hubs/harmonylrhub/devices/tadiran-ac/command -m off
sudo pm2 start harmonyapi/app.js --name harmony-api
sudo pm2 ls
sudo dd if=/dev/disk2 of=/Users/[USERNAME]/Desktop/hassbian-backup-$(date +%Y%m%d).img
```
