#!/bin/bash



#created by mrgr. Please consider to vote for mrgr delegate




RED='\033[1;31m'
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
OFF='\033[0m' # No Color

NOW=$(date +"%H:%M")
LOCAL_TIME=0
OK=1
echo "----------------------------------------"
echo "Welcome to the antifork installation"
echo -e "Don't forget to vote for ${YELLOW}mrgr${OFF} delegate"
echo "----------------------------------------"
echo "We need to configure some variables."
echo " "

if [ -f "configtoolisk.sh" ]; then
	read -p "**A previous installation was detected, do you want to proceed anyway (y/n)?" -n 1 -r
	if [[  $REPLY =~ ^[Nn]$ ]]
	   then
		OK=0
	fi
fi

if [[  $OK -eq 1 ]]
   then

echo "The following is needed if you want alerts in your email"
echo "Please enter the following information:"
echo -n "Api key: "
	read API_KEY
echo -n "Default SMTP Login:  "
	read MG_FROM
echo -n "API Base URL: "
	read MAILGUN
echo -n "Email to: "
	read MG_TO

        read -p "Is this information correct (y/n)?" -n 1 -r
        if [[  $REPLY =~ ^[Yy]$ ]]
           then
                echo " "
		echo -e "Email information set. Alerts will sent to: $MG_TO"
           else
                echo " "
		echo "Please run the installer again"
		exit 1
           fi

echo " "
echo "Now we are going to configure the failover settings."
echo "Please enter the folling information (of your backup server): "
echo -n "IP: "
	read IP_SERVER
echo -n "Port: "
        read PORT

HTTP="0"
read -p "Is https enabled (y/n)?" -n 1 -r
        if [[  $REPLY =~ ^[Yy]$ ]]
           then
		HTTP="https"
	   else
		HTTP="http"
           fi
echo " "
echo " "
echo "Now enter the information of your delegate."
echo -n "Delegate name: "
	read DELEGATE_NAME
echo -n "Delegate passphrase: "
	read SECRET

init=configtoolisk.sh

echo " "
echo "#Config file" > $init
echo "#toolisk variables" >> $init
echo "RED='\033[1;31m'" >> $init
echo "YELLOW='\033[1;33m'">> $init
echo "GREEN='\033[1;32m'" >> $init
echo "CYAN='\033[1;36m'" >> $init
echo "OFF='\033[0m' # No Color" >> $init
echo "API_KEY=\"$API_KEY\" #your mailgun API key" >> $init
echo "MG_FROM=\"$MG_FROM\" #Default SMTP Login" >> $init
echo "MAILGUN=\"$MAILGUN/messages\" #API Base URL" >> $init
echo "MG_TO=\"$MG_TO\" #Email to" >> $init
echo "MG_SUBJECT=\"$DELEGATE_NAME in Fork - failover activated successfully\"" >> $init
echo "MG_TEXT=\"Description of the alert\"" >> $init
echo "DELEGATE_NAME=\"$DELEGATE_NAME\"" >> $init
echo "OFFSET=\"$scale\"" >> $init
echo "IP_SERVER=\"$IP_SERVER\" #IP of the extra syncronized server" >> $init
echo "HTTP=\"$HTTP\" #http or https if is activated" >> $init
echo "PORT=\"$PORT\"" >> $init
echo "SECRET=\"$SECRET\" #Passphrase of DELEGATE_NAME" >> $init
echo "URL_REMOTE=\"$HTTP://$IP_SERVER:$PORT/api/delegates/forging/enable\" #URL according variables HTTP, PORT and IP_SERVER" >> $init
echo "URL_REMOTE_DISABLE=\"$HTTP://$IP_SERVER:$PORT/api/delegates/forging/disable\"" >> $init
echo "URL_LOCAL=\"$HTTP://127.0.0.1:$PORT/api/delegates/forging/enable\"" >> $init
echo "URL_LOCAL_DISABLE=\"$HTTP://127.0.0.1:$PORT/api/delegates/forging/disable\"" >> $init
echo "BLOCKHEIGHT_LOG=~/toolisk/blockheight.log" >> $init
echo "CONSENSUS_LOG=~/toolisk/consensus.log" >> $init
echo "USERTOOL=\"$USER\"" >> $init

chmod u+x blockheight.sh
chmod u+x consensus.sh

echo " "
echo -e "${CYAN}ALL VARIABLES SET${OFF}"
echo " "
   fi
