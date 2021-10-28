# dns-update
Automatically update DNS records in DirectAdmin to the UniFi UDM-Pro's dynamic WAN address without external services.

## Preparation

### UniFi controller
Create a local user for the UniFi controller with read-only access.
### DirectAdmin
Create a DirectAdmin login key with `CMD_API_DNS_CONTROL` and `CMD_API_LOGIN_TEST`.

## Configuration
Modify the UniFi controller and DirectAdmin parameters in `dns-update`.
A configuration file will be added in a new release.

## Setup
Put the files in the right folders:
```
sudo cp dns-update /usr/local/bin
sudo cp dns-update.service /etc/systemd/system
sudo cp dns-update.timer /etc/systemd/system
```

The script `dns-update` is triggered every minute via a systemd service and timer.
Output is handled by syslog with identifier `dns-update`.

Activate the service and timer
```
sudo systemctl enable dns-update.service
sudo systemctl enable dns-update.timer
sudo systemctl start dns-update.timer
```

Check the system logs
```
journalctl -u dns-update
```

## Usage
`dns-update` is triggered by the systemd timer.
Manually trigger the script by starting the systemd service:
```
sudo systemctl start dns-update
```
