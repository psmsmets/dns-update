#!/bin/bash

##############################################################################
# Script Name	: dns-update
# Description	: Automatically update DNS records in DirectAdmin to the UniFi
#                 controller's dynamic WAN address without external services.
# Args          : <config_file>
# Author       	: Pieter Smets
# E-mail        : mail@pietersmets.be
##############################################################################

#
# Some usefull links to create this script
#
# https://ubntwiki.com/products/software/unifi-controller/api
# https://gist.github.com/jcconnell/0ee6c9d5b25c572863e8ffa0a144e54b

# Set script name
SCRIPT="dns-update"

#-------------------------------------------------------------------------------
#
# Function definitions
#
#-------------------------------------------------------------------------------

function badUsage {
#
# Message to display when bad usage.
#
    local message="$1"
    local txt=(
"Automatically update DNS records in DirectAdmin to the UniFi controller's "
"dynamic WAN address without external services."
"Usage: $SCRIPT <config_file>"
    )

    [[ $message ]] && printf "\n$message\n"

    printf "%s\n" "${txt[@]}"
    exit -1
}


function parse_config { # parse_config file.cfg var_name1 var_name2
#
# This function will read key=value pairs from a configfile.
#
# After invoking 'readconfig somefile.cfg my_var',
# you can 'echo "$my_var"' in your script.
#
# ONLY those keys you give as args to the function will be evaluated.
# This is a safeguard against unexpected items in the file.
#
# ref: https://stackoverflow.com/a/20815951
#
# The config-file could look like this:
#-------------------------------------------------------------------------------
# This is my config-file
# ----------------------
# Everything that is not a key=value pair will be ignored. Including this line.
# DO NOT use comments after a key-value pair!
# They will be assigend to your key otherwise.
#
# singlequotes = 'are supported'
# doublequotes = "are supported"
# but          = they are optional
#
# this=works
#
# # key = value this will be ignored
#
#-------------------------------------------------------------------------------
    shopt -s extglob # needed the "one of these"-match below
    local configfile="${1?No configuration file given}"
    local keylist="${@:2}"    # positional parameters 2 and following
    local lhs rhs

    if [[ ! -f "$configfile" ]]; then
        >&2 echo "\"$configfile\" is not a file!"
        exit 1
    fi
    if [[ ! -r "$configfile" ]]; then
        >&2 echo "\"$configfile\" is not readable!"
        exit 1
    fi

    keylist="${keylist// /|}" # this will generate a regex 'one of these'

    # lhs : "left hand side" : Everything left of the '='
    # rhs : "right hand side": Everything right of the '='
    #
    # "lhs" will hold the name of the key you want to read.
    # The value of "rhs" will be assigned to that key.
    while IFS='= ' read -r lhs rhs
    do
        # IF lhs in keylist
        # AND rhs not empty
        if [[ "$lhs" =~ ^($keylist)$ ]] && [[ -n $rhs ]]; then
            rhs="${rhs%\"*}"     # Del opening string quotes
            rhs="${rhs#\"*}"     # Del closing string quotes
            rhs="${rhs%\'*}"     # Del opening string quotes
            rhs="${rhs#\'*}"     # Del closing string quotes
            eval $lhs=\"$rhs\"   # The magic happens here
        fi
    # tr used as a safeguard against dos line endings
    done < $configfile
    # done <<< $( tr -d '\r' < $configfile )

    shopt -u extglob # Switching it back off after use
}


function check_config { # check_config var1 var2 ...
#
# Check if the provided variables are set.
#
    local var
    for var in "${@}";
    do
        if [ -z "${!var}" ]; then
            echo "Error: variable $var is empty!"
            exit -1
        fi
    done
}


#
# UI curl alias with cookie
#
UI_COOKIE=$(mktemp)
alias ui_curl="/usr/bin/curl -s -S --cookie ${UI_COOKIE} --cookie-jar ${UI_COOKIE} --insecure"


function ui_login {
#
# Login to the configured UI controller
#
    ui_curl \
        -H "Content-Type: application/json" \
        -X POST \
        -d "{\"password\":\"$UI_PASSWORD\",\"username\":\"$UI_USERNAME\"}" \
        $UI_ADDRESS:443/api/auth/login > /dev/null
}


function ui_logout {
#
# Logout from the configured UI controller
#
   ui_curl ${UI_API}/logout > /dev/null
}


function ui_wan_address {
#
# Echo the configured UI controller's WAN ip address.
#
    ui_login
    response=$(ui_curl ${UI_SITE_API}/stat/sysinfo --compressed)
    ip_addrs=$(echo $response | jq -r ".data[0].ip_addrs[0]")
    echo $ip_addrs
    ui_logout
}


function da_dns_address {
#
# Echo the DNS A record value from your default nameserver.
#
    /usr/bin/dig ${DA_RECORD}.${DA_DOMAIN} +short
}


function da_dns_update {
#
# This function will update DNS A record in DirectAdmin to the new ip address
#
    local new_ip=$1

    /usr/bin/curl \
        --request "POST" \
        --user "${da_user}:${da_token}" \
        -d domain=${DA_DOMAIN} \
        -d action=edit \
        -d type=A \
        -d arecs0=name%3D${DA_RECORD} \
        -d name=${DA_RECORD} \
        -d value=${new_ip} \
        -d json=yes \
        "${DA_ADDRESS}/CMD_API_DNS_CONTROL"
}


#-------------------------------------------------------------------------------
# 
# Parse configuration file
#
#-------------------------------------------------------------------------------

#
# Check input arguments
#
if (($# > 1 )); then
    badUsage "Illegal number of arguments"
fi

#
# Set UI and DA variables from configuration file and check if all are set.
#
if (($# == 1 )); then
    parse_config $1 UI_ADDRESS UI_SITENAME UI_PASSWORD UI_SITENAME
    parse_config $1 DA_ADDRESS DA_USERNAME DA_LOGINKEY DA_DOMAIN DA_RECORD
fi
check_config UI_ADDRESS UI_SITENAME UI_PASSWORD UI_SITENAME
check_config DA_ADDRESS DA_USERNAME DA_LOGINKEY DA_DOMAIN DA_RECORD

#
# Construct derived variables
#
UI_API="${UI_ADDRESS}/proxy/network/api"
UI_SITE_API="${UI_API}/s/${UI_SITENAME}"
DA_SUBDOMAIN="${DA_RECORD}.${DA_DOMAIN}"


#-------------------------------------------------------------------------------
# 
# DNS ip update sequence
#
#-------------------------------------------------------------------------------

IP_UDM=$(ui_wan_address)
IP_DNS=$(da_dns_address)

if [ $IP_UDM != $IP_DNS ]; then
    echo "Update DNS ip address for ${DA_RECORD}.${DA_DOMAIN} -A to ${IP_UDM}. "
    da_dns_update $IP_UDM
else
    echo "No update needed for ${DA_RECORD}.${DA_DOMAIN} -A ${IP_DNS}."
fi

exit 0
