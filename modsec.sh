#!/bin/bash
#Written by Artem Findir
#Version 25.04.17

### Variables
PAZZ=/etc/httpd/conf/userdata
LOCMATCH="<LocationMatch .*>\n</LocationMatch>"
TAG="<LocationMatch \.\*>"
TAG_C="<\/LocationMatch>"
CWAF=/var/cpanel/cwaf/etc/httpd/custom_user.conf
r=\\e[41m
g=\\e[42m\\e[30m
cc=\\e[0m

### Functions
configs () {
for TYPE in {std,ssl}; do
mkdir -p $PAZZ/$TYPE/2_2/$DEST/ 2>/dev/null; echo "User folder in $TYPE for $DEST checked"
touch $PAZZ/$TYPE/2_2/$DEST/modsec.conf 2>/dev/null; echo "$DEST/modsec.conf in $TYPE checkedd"
if ! [[ -s $PAZZ/$TYPE/2_2/$DEST/modsec.conf ]]; then echo -e $LOCMATCH > $PAZZ/$TYPE/2_2/$DEST/modsec.conf ; echo "LocationMatch added to $DEST/modsec.conf in $TYPE"; fi
done
}

main () {
for TYPE in {std,ssl}; do
if ! sed -ne "/$TAG/,/$TAG_C/p" $PAZZ/$TYPE/2_2/$DEST/modsec.conf | grep "$PATTERN" &>/dev/null; then sed -i "/$TAG/a$PATTERN" $PAZZ/$TYPE/2_2/$DEST/modsec.conf ; echo -e "${g}$PATTERN added to $DEST/modsec.conf in $TYPE${cc}"; else echo -e "${r}$PATTERN is already added to $DEST/modsec.conf in $TYPE${cc}"; fi
done
}

main_on () {
for TYPE in {std,ssl}; do
if sed -ne "/$TAG/,/$TAG_C/p" $PAZZ/$TYPE/2_2/$DEST/modsec.conf | grep "$PATTERN" &>/dev/null; then sed -i "/$PATTERN/d" $PAZZ/$TYPE/2_2/$DEST/modsec.conf ; echo -e "${g}SecRuleEngine enabled in $DEST/modsec.conf in $TYPE${cc}"; else echo -e "${r}SecRuleEngine is already enabled in $DEST/modsec.conf in $TYPE${cc}"; fi
done
}

rebuild () {
grep "std/2_2/$DEST/\*" /etc/httpd/conf/httpd.conf | grep -v \# 1>/dev/null
case $? in 1) /scripts/rebuildhttpdconf && /scripts/restartsrv_httpd; echo "rebuildhttpdconf and restartsrv_httpd DONE" ;; 0) echo "rebuildhttpdconf and restartsrv_httpd are not required" ;; esac
}

choice () {
case $1 in
        [0-9][0-9][0-9][0-9][0-9][0-9])
                PATTERN="SecRuleRemoveById $1"
                main
                rebuild ;;
        off)
                PATTERN="SecRuleEngine Off"
                main
                rebuild ;;
        on)
                PATTERN="SecRuleEngine Off"
                main_on
                rebuild ;;
	*)	echo -e "Please check the arguments\n\nFunction usage: modsec user|domain ruleID|off|on\n";;
esac
}

### For cP username
if [[ $(ls -l /var/cpanel/users | awk '{print $9}' | grep -w $1) ]]; 
then DEST=$1
configs
choice $2

### For domain
elif [[ $(grep -e "^$1" /etc/userdomains) ]];
then OWNER=$(grep -e "^$1" /etc/userdomains | awk -F": " '{print $2}')
DEST=$OWNER/$1
configs
choice $2

#elif [[ $1 == "global" ]] && [[ $2 == [0-9][0-9][0-9][0-9][0-9][0-9] ]]; then PATTERN="SecRuleRemoveById $2" 
#sed -ne "/$TAG_C/,\$p" $CWAF | sed -ne "0,/$TAG/p" | grep "$PATTERN" 1>/dev/null
#case $? in 1) sed -i -e "/$(sed -ne "/$TAG_C/,\$p" $CWAF | head -n1)/a$PATTERN" $CWAF; echo -e "${g}Rule $2 has been whitelisted in CWAF${cc}" ;; 0) echo -e "${r}Rule $2 is already whitelisted in CWAF${cc}" ;; esac

#elif [[ $1 == "comodo" ]] && [[ $2 == [0-9][0-9][0-9][0-9][0-9][0-9] ]]; then PATTERN="SecRuleRemoveById $2"
#sed -ne "/$TAG/,/$TAG_C/p" /var/cpanel/cwaf/etc/httpd/custom_user.conf | sed -ne "0,/$TAG_C/p" | grep "$PATTERN" 1>/dev/null
#case $? in 1) sed -i "/$TAG/a$PATTERN" $CWAF; echo -e "${g}Rule $2 has been whitelisted in CWAF${cc}" ;; 0) echo -e "${r}Rule $2 is already whitelisted in CWAF${cc}" ;; esac

else echo -e "Please check the arguments\n\nFunction usage: modsec user|domain ruleID|off|on\n" 

fi ;
