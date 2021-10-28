# dns-update
Automatically update DNS records in DirectAdmin to the UniFi UDM-Pro's dynamic WAN address without external services.

## Preparation

The UniFi controller and DirectAdmin variables should either be set as shell (environment) variables or provided in a configuration file.

#### UniFi controller
Create a local user for the UniFi controller with read-only access.

Add the following UniFi Controller variables to your shell or the configuration file.
```
# UniFi controller configuration
UI_ADDRESS = https://10.10.0.1
UI_USERNAME='...'
UI_PASSWORD='...'
UI_SITENAME='default'
```

#### DirectAdmin
Create a DirectAdmin login key with `CMD_API_DNS_CONTROL` and `CMD_API_LOGIN_TEST`.

Add the following DirectAdmin variables to your shell or the configuration file.
```
# DirectAdmin configuration
DA_ADDRESS='https://...'
DA_USERNAME='...'
DA_LOGINKEY='...'
DA_DOMAIN='domain.example'
DA_RECORD='sub'
```

## Usage

Simply call the script with the configuration file.
 
```
bash dns-update.sh /path/to/your/dns-update.conf
```

Missing variables from the configuration file are assumed to be set in your shell (locally or as enviroment variables).
If no configuration is provided all variables should be set.

## Automatic trigger via Crontab
Add the following line to your contrab (`sudo crontab -e`) to trigger the DNS update every minute and log the output in syslog.
```
0 1 * * * /home/user/dns-update.sh /home/user/my-dns-update.conf 2>&1 | /usr/bin/logger -t my-dns-update
```
Set the correct path to both the script and configuration.

Scan the log output
```
cat /var/log/syslog | grep my-dns-update
```


Multiple DNS records can be updated via separate configuration files (and crontab rules).
