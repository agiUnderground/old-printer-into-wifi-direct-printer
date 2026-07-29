# old-printer-into-wifi-direct-printer
Upgrade your old printer into "Wi-Fi Direct" printer. 

You need:
* `Old printer`
* `Linux computer`*
* `Wi-Fi dongle with AP mode support`

  \* ubuntu-based, systemd(or anything else; customize deps/code/configs using llms).  


  
Service will create additional net namespace, it will move AP-capable wifi interface there, then it will start all needed sub-services.

Make sure you wifi interface is NOT managed by a network manager(if you use network manager) `sudo nmcli device set wlp0 managed no`.

1. Install dependencies `./install-dependencies.sh`.
2. Check a `phy` index of the wifi device you will use for this project `iw dev` and replace it if needed in `start.sh`
3. Create a dir for the configs, for example `/opt/wifi-printer/`
4. In `config/airprint.service` file replace `value` with a name of you printer, for example `rp=printers/value` -> `rp=printers/hp-LaserJet-1010`. To find a name of your printer `sudo ip netns exec printer lpstat -p` or just `lpstat -p`.
5. Change `wpa_passphrase` in `config/hostapd.conf`, it's your wifi password.
6. Copy `config` dir content into `/opt/wifi-printer/config/`
7. Copy start/stop scripts `sudo cp start.sh stop.sh /opt/wifi-printer/`
8. Make sure start/stop scripts are executable `sudo chmod +x ...`
9. Install a systemd service `sudo cp printer.service /etc/systemd/system/`
10. Enable service `sudo systemctl daemon-reload` `sudo systemctl enable printer.service`
11. Generate a QR code `./gen-qr.sh` (which includes wifi AP ssid and credentials), print it(qr.png) and stick it on a printer.

How it works:
* You scan a QR code with you phone.
* It will ask you to connect to a wifi network "printer", click "join".
* Your phone automatically gets an ip address in the isolated wifi subnet(no internet) thanks to dhcp.
* Choose a document you want to print. Click "share" -> "print'. Phone will automatically detect a printer. Press a print confirmation button.
* Done.  

Issues:
* Use default `cupsd.conf` is custom one fails.
* If you phone can not find a printer you could try `sudo ip netns exec printer cupsctl --share-printers --remote-any`.
* Make sure cups generated all necessary ssl certificates.
* Fix a file system permissions if needed.
