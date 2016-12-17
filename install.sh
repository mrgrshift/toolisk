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

if [ -f "$1" ]; then
	case $1 in
	"main")
		echo "You are installing this script for mainnet"
		VERSION="lisk-main"
	;;
	"test")
		echo "You are installing this script for testnet"
		VERSION="lisk-test"
	;;
        "--alerts-off")
                echo "You are installing this script for mainnet"
                VERSION="lisk-main"
		ALERTS_OFF="true"
        ;;
	*)
                echo "You are installing this script for mainnet"
                VERSION="lisk-main"
        ;;
	esac
else
	echo "You are installing this script for mainnet"
	echo "If you want to change this script to testnet please stop this installation and start again with:"
	echo "bash install.sh test"
	VERSION="lisk-main"
fi


if [ -f "configtoolisk.sh" ]; then
	read -p "**A previous installation was detected, do you want to proceed anyway (y/n)?" -n 1 -r
	if [[  $REPLY =~ ^[Nn]$ ]]
	   then
		OK=0
	fi
fi

if [[  $OK -eq 1 ]]
   then

if [ "$ALERTS_OFF" != "true" ]; then
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
fi

        read -p "How many servers are you using (1 or 2)?" -n 1 -r
        if [[  $REPLY =~ ^[12]$ ]]
           then
                echo
		if [ "$REPLY" -eq "2" ]; then
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
		   echo
		else
		   echo
		   echo -e "${YELLOW}WARNING!${OFF} This scripts works better with 2 servers. You can continue installing it and this script will do his best for you with one server"
		   echo
		fi

           else
                echo " "
		echo "Please run the installer again and select only the numer 1 or numer 2"
		exit 1
           fi


	read -p "Is https enabled in your localhost (y/n)?" -n 1 -r
            if [[  $REPLY =~ ^[Yy]$ ]]
               then
                  HTTP_LOCAL="https"
               else
                  HTTP_LOCAL="http"
               fi
	echo
	echo -n "In which port are you running $VERSION $HTTP_LOCAL: "
        	read LOCAL_PORT


echo " "
echo " "
echo "Now enter the information of your delegate."
echo -n "Delegate name: "
	read DELEGATE_NAME
echo -n "Delegate address: "
        read DELEGATE_ADDRESS

RESPONSE=$(curl -s http://localhost:8000/api/accounts/delegates?address=$DELEGATE_ADDRESS | jq '.delegates[] | select(.username=="'$DELEGATE_NAME'")')
v1=$(echo $RESPONSE | jq '.publicKey')
PUBLICKEY="${v1//\"/}"


echo -n "Delegate passphrase: "
	read SECRET
echo -n "How you identify this server? (e.g. Main Server/Backup1): "
        read SERVER_NAME

init=configtoolisk.sh

echo " "
echo "#Config file" > $init
echo "#toolisk variables" >> $init
echo "RED='\033[1;31m'" >> $init
echo "YELLOW='\033[1;33m'">> $init
echo "GREEN='\033[1;32m'" >> $init
echo "CYAN='\033[1;36m'" >> $init
echo "OFF='\033[0m' # No Color" >> $init
echo "VERSION=\"$VERSION\"" >> $init
echo "API_KEY=\"$API_KEY\" #your mailgun API key" >> $init
echo "MG_FROM=\"$MG_FROM\" #Default SMTP Login" >> $init
echo "MAILGUN=\"$MAILGUN/messages\" #API Base URL" >> $init
echo "MG_TO=\"$MG_TO\" #Email to" >> $init
echo "MG_SUBJECT=\"$DELEGATE_NAME in Fork - failover activated successfully\"" >> $init
echo "MG_TEXT=\"Description of the alert\"" >> $init
echo "DELEGATE_NAME=\"$DELEGATE_NAME\"" >> $init
echo "DELEGATE_ADDRESS=\"$DELEGATE_ADDRESS\"" >> $init
echo "OFFSET=\"$scale\"" >> $init
echo "IP_SERVER=\"$IP_SERVER\" #IP of the extra syncronized server" >> $init
echo "HTTP=\"$HTTP\" #http or https if is activated" >> $init
echo "PORT=\"$PORT\"" >> $init
echo "HTTP_LOCAL=\"$HTTP_LOCAL\"" >> $init
echo "LOCAL_PORT=\"$LOCAL_PORT\"" >> $init
echo "SECRET=\"$SECRET\" #Passphrase of DELEGATE_NAME" >> $init
echo "URL_REMOTE=\"\$HTTP://\$IP_SERVER:\$PORT/api/delegates/forging/enable\" #URL according variables HTTP, PORT and IP_SERVER" >> $init
echo "URL_REMOTE_DISABLE=\"\$HTTP://\$IP_SERVER:\$PORT/api/delegates/forging/disable\"" >> $init
echo "URL_LOCAL=\"\$HTTP_LOCAL://127.0.0.1:\$LOCAL_PORT/api/delegates/forging/enable\"" >> $init
echo "URL_LOCAL_DISABLE=\"\$HTTP_LOCAL://127.0.0.1:\$LOCAL_PORT/api/delegates/forging/disable\"" >> $init
echo "BLOCKHEIGHT_LOG=~/toolisk/logs/sync_manager.log" >> $init
echo "MANAGER_LOG=~/toolisk/logs/forging_manager.log" >> $init
echo "LOCAL_SNAPSHOTS=~/toolisk/snapshots/" >> $init
echo "PUBLICKEY=\"$PUBLICKEY\"" >> $init
echo "URL_LOCAL_FORGING_STATUS=\"http://localhost:8000/api/delegates/forging/status?publicKey=\$PUBLICKEY\"" >> $init
echo "URL_REMOTE_FORGING_STATUS=\"http://\$IP_SERVER:8000/api/delegates/forging/status?publicKey=\$PUBLICKEY\"" >> $init
echo "USERTOOL=\"$USER\"" >> $init
echo "SERVER_NAME=\"$SERVER_NAME\""
echo "ALERTS_OFF=\"$ALERTS_OFF\"" >> $init
echo "cd /home/$USER/$VERSION/" >> $init

chmod u+x sync_manager.sh
chmod u+x forging_manager.sh

mkdir -p logs/

echo " "
echo -e "${CYAN}ALL VARIABLES SET${OFF}"
echo " "
   fi




#REBOOT DETECT/STARTUP SCRIPT
echo
echo "=============================================================="
echo "Anti-Reboot configuration"
echo "=============================================================="
echo " "
echo -e "Is important to keep ${CYAN}node app.js${OFF} running, that is why we need to prevent possible reboots or system outages."
echo "This script will send you an email alert when reboot is detected. And will start lisk at your system startup."
echo -e "Before proceeding, be sure to read the information located here: ${CYAN}https://github.com/mrgrshift/restart-script${OFF}"
echo "The following configuration will change your rc.local and create K04custom_shutdown script."
echo "If you are not sure about this please avoid the next question an press 'n'."
echo " "
read -p "Do you want to proceed (y/n)?" -n 1 -r
        if [[  $REPLY =~ ^[Yy]$ ]]
           then
                echo " "
                           #custom_shutdown
                           echo "echo \"#!/bin/sh -e\" >  /etc/init.d/custom_shutdown | sudo tee -a /etc/init.d/custom_shutdown > /dev/null" > temp.sh
                           echo "echo \"cd $(pwd)\" >>  /etc/init.d/custom_shutdown | sudo tee -a /etc/init.d/custom_shutdown > /dev/null" >> temp.sh
		           echo "echo \"bash $(pwd)/reboot.sh >> $(pwd)/logs/reboot.log\" >>  /etc/init.d/custom_shutdown | sudo tee -a /etc/init.d/custom_shutdown > /dev/null" >> temp.sh
                           echo "echo \"exit 0\" >>  /etc/init.d/custom_shutdown | sudo tee -a /etc/init.d/custom_shutdown > /dev/null" >> temp.sh
                                sudo bash temp.sh
                                rm temp.sh
                                sudo chmod a+x /etc/init.d/custom_shutdown > logs/install.log > /dev/null
                                sudo ln -sf /etc/init.d/custom_shutdown /etc/rc0.d/K04custom_shutdown >> logs/install.log > /dev/null
                                sudo ln -sf /etc/init.d/custom_shutdown /etc/rc6.d/K04custom_shutdown >> logs/install.log > /dev/null
                                sudo chmod a+x /etc/rc0.d/K04custom_shutdown /etc/rc6.d/K04custom_shutdown >> logs/install.log > /dev/null

                           echo -n "Configuring... "
			   #reboot.sh
			   echo "#!/bin/sh -e" >  reboot.sh
			   echo "source configtoolisk.sh" >> reboot.sh
			   echo "MG_SUBJECT=\"\$SERVER_NAME rebooting.\"" >> reboot.sh
			   echo "MG_TEXT=\"\$SERVER_NAME rebooting.\"" >> reboot.sh
			   echo "curl -s --user \"api:\$API_KEY\" \$MAILGUN -F from=\"\$MG_FROM\" -F to=\"\$MG_TO\" -F subject=\"\$MG_SUBJECT\" -F text=\"\$MG_TEXT\"" >> reboot.sh
				sudo chmod a+x reboot.sh

			   #startup script
			   echo "#!/bin/bash" > startup.sh
			   echo "export HOME=/home/$USER/lisk-main/" >> startup.sh
			   echo "cd /home/$USER/lisk-main/" >> startup.sh
			   echo "echo \"Starting lisk.sh reload\" > /home/$USER/toolisk/logs/startup.log" >> startup.sh
			   echo "bash /home/$USER/lisk-main/lisk.sh reload >> /home/$USER/toolisk/logs/startup.log" >> startup.sh
				sudo chmod u+x startup.sh
			   echo "#!/bin/bash" > temp.sh
                           echo "sudo rm /etc/rc.local" >> temp.sh
			   echo "echo \"#!/bin/sh -e\" > /etc/rc.local | sudo tee -a /etc/rc.local > /dev/null" >> temp.sh
			   echo "echo \"/bin/su $USER -c \\\"cd $(pwd); /usr/bin/screen -dmS startup_lisk bash -c $(pwd)/startup.sh'; exec bash'\\\" > $(pwd)/logs/rc.log.log\" | sudo tee -a /etc/rc.local > /dev/null" >> temp.sh
			   echo "echo \"sleep 15\" >> /etc/rc.local | sudo tee -a /etc/rc.local > /dev/null" >> temp.sh
                           #echo "echo \"/bin/su $USER -c \\\"cd $(pwd); bash -c $(pwd)/sync_manager.sh'; exec bash'\\\" > $(pwd)/logs/rc.local.log\" | sudo tee -a /etc/rc.local > /dev/null" >> temp.sh
			   echo "echo \"exit 0\" >> /etc/rc.local | sudo tee -a /etc/rc.local > /dev/null" >> temp.sh
				sudo bash temp.sh
			   echo -e "done.";
				rm temp.sh
			   echo "done"

		DISTR=$(cat /etc/lsb-release | grep "DISTRIB_RELEASE")
		        if [  "$DISTR" != "DISTRIB_RELEASE=14.04" ]
		           then
				echo -n "Configuring newer version... "
				echo "echo \"[Unit]\" > /etc/systemd/system/rc-local.service | sudo tee -a /etc/rc.local > /dev/null" > temp.sh
				echo "echo \" Description=/etc/rc.local Compatibility\" >> /etc/systemd/system/rc-local.service | sudo tee -a /etc/rc.local > /dev/null" >> temp.sh
				echo "echo \" ConditionPathExists=/etc/rc.local\" >> /etc/systemd/system/rc-local.service | sudo tee -a /etc/rc.local > /dev/null" >> temp.sh

				echo "echo \"[Service]\" >> /etc/systemd/system/rc-local.service | sudo tee -a /etc/rc.local > /dev/null" >> temp.sh
				echo "echo \" Type=forking\" >> /etc/systemd/system/rc-local.service | sudo tee -a /etc/rc.local > /dev/null" >> temp.sh
				echo "echo \" ExecStart=/etc/rc.local start\" >> /etc/systemd/system/rc-local.service | sudo tee -a /etc/rc.local > /dev/null" >> temp.sh
                                echo "echo \" ExecStop=/etc/init.d/custom_shutdown\" >> /etc/systemd/system/rc-local.service | sudo tee -a /etc/rc.local > /dev/null" >> temp.sh
				echo "echo \" TimeoutSec=0\" >> /etc/systemd/system/rc-local.service | sudo tee -a /etc/rc.local > /dev/null" >> temp.sh
				echo "echo \" StandardOutput=tty\" >> /etc/systemd/system/rc-local.service | sudo tee -a /etc/rc.local > /dev/null" >> temp.sh
				echo "echo \" RemainAfterExit=yes\" >> /etc/systemd/system/rc-local.service | sudo tee -a /etc/rc.local > /dev/null" >> temp.sh
				echo "echo \" SysVStartPriority=99\" >> /etc/systemd/system/rc-local.service | sudo tee -a /etc/rc.local > /dev/null" >> temp.sh

				echo "echo \"[Install]\" >> /etc/systemd/system/rc-local.service | sudo tee -a /etc/rc.local > /dev/null" >> temp.sh
				echo "echo \" WantedBy=multi-user.target\" >> /etc/systemd/system/rc-local.service | sudo tee -a /etc/rc.local > /dev/null" >> temp.sh
				sudo bash temp.sh
				sudo chmod +x /etc/rc.local 2>&1
				sudo systemctl enable rc-local >> logs/install.log > /dev/null 2>&1
				sudo systemctl start rc-local.service >> logs/install.log > /dev/null 2>&1
				echo "done"
				rm temp.sh
			fi

		echo " "
		echo "You have completed the installation."
           else
                echo " "
		echo "The installation is terminated."
		exit 1
           fi


#created by mrgr. Please consider to vote for mrgr delegates
