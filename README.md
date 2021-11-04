# dns-update
Automatically update DNS A-records in DirectAdmin to the UniFi UDM-Pro's dynamic WAN address without external services.

The dynamic WAN address is obtained via the UniFi's controller API and compared with the nameserver A-record value. 
Only if the values do not match the DNS A-record is updated via the DirectAdmin's API. 
Make sure that the DNS TTL (Time To Live) of the A-record is short (e.g., `TTL=60`) to minimize lagging cache when your ip address is changed. 

## Preparation
Configure the UniFi controller and DirectAdmin accordingly. 
All related variables should either be defined as shell (environment) variables or provided in a configuration file.

### UniFi controller
Create a local user for the UniFi controller with read-only access.

1. Add user
1. Set role to `Limited Admin`
1. Set account type to `Local Access Only`
1. Complete the first name, last name, local username and local password fields. All other fields can be left blank.
1. In application permission, set the Unifi Network  to `View Only`. All other applications can either be `View Only` or `None`.


Add the UniFi Controller variables to your shell or the configuration file.
```
# UniFi controller configuration
UI_ADDRESS = https://url_or_ip_of_your_controller
UI_USERNAME = '...'
UI_PASSWORD = '...'
UI_SITENAME = default
```

### DirectAdmin
Create a DirectAdmin api-only login key.

1. Login to DirectAdmin
1. Go to _password management > Login Keys_ (`/user/login-keys`)
1. Create a new login key
  * Type = key
  * Name = dnsupdate
  * Value =your own key or generate a random key by clicking the dices (don't forget to copy the value!)
  * Expires = never
  * Clear = unchecked
  * HTM = unchecked
  * Commands = 
    - `CMD_API_DNS_CONTROL`
    - `CMD_API_LOGIN_TEST`
  * Password = your DirectAdmin password 

Add the DirectAdmin variables to your shell or the configuration file.
```
# DirectAdmin configuration
DA_ADDRESS    = https://root_url_to_your_directadmin
DA_USERNAME   = username
DA_LOGINKEY   = SOMETHING_VERY_LONG
DA_DOMAIN     = example.com
DA_RECORD     = sub
DA_NAMESERVER = optional nameserver to query
```

## Usage
Execute the script with a configuration file
```
bash dns-update.sh /path/to/your/dns-update.conf
```

Missing variables from the configuration file are assumed to be set in your shell (locally or as enviroment variables).
```
DA_DOMAIN=example.com; DA_RECORD=sub; bash dns-update.sh /path/to/your/dns-update.conf
```

If no configuration is provided all variables should be set.

## Automatic trigger via Crontab
Trigger the DNS A-record update every 5-minutes using crontab (`sudo crontab -e`) and log the output in syslog.
```
*/5 * * * * /home/user/dns-update.sh /home/user/my-dns-update.conf 2>&1 | /usr/bin/logger -t my-dns-update
```
Make sure that the correct path to both the script and configuration are set.

Scan the syslog output
```
cat /var/log/syslog | grep my-dns-update
```

Multiple DNS records can be updated via separate configuration files (and crontab rules).
