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
echo -n "How you identify this server?: "
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
echo "BLOCKHEIGHT_LOG=~/toolisk/logs/blockheight.log" >> $init
echo "CONSENSUS_LOG=~/toolisk/logs/consensus.log" >> $init
echo "MANAGER_LOG=~/toolisk/logs/manager.log" >> $init
echo "USERTOOL=\"$USER\"" >> $init
echo "SERVER_NAME=\"$SERVER_NAME\""
echo "cd /home/$USER/lisk-main/" >> $init

chmod u+x blockheight.sh
chmod u+x consensus.sh
chmod u+x manager.sh

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
echo " "
read -p "Do you want to proceed (y/n)?" -n 1 -r
        if [[  $REPLY =~ ^[Yy]$ ]]
           then
                echo " "
                           #custom_shutdown
                           echo "echo \"#!/bin/sh -e\" >  /etc/init.d/custom_shutdown | sudo tee -a /etc/init.d/custom_shutdown > /dev/null" > temp.sh
                           echo "echo \"cd $(pwd)\" >>  /etc/init.d/custom_shutdown | sudo tee -a /etc/init.d/custom_shutdown > /dev/null" >> temp.sh
		           echo "echo \"bash $(pwd)/reboot.sh >> $(pwd)/reboot.log\" >>  /etc/init.d/custom_shutdown | sudo tee -a /etc/init.d/custom_shutdown > /dev/null" >> temp.sh
                           echo "echo \"exit 0\" >>  /etc/init.d/custom_shutdown | sudo tee -a /etc/init.d/custom_shutdown > /dev/null" >> temp.sh
                                sudo bash temp.sh
                                rm temp.sh
                                sudo chmod a+x /etc/init.d/custom_shutdown > logs/install.log
                                sudo ln -sf /etc/init.d/custom_shutdown /etc/rc0.d/K04custom_shutdown >> logs/install.log
                                sudo ln -sf /etc/init.d/custom_shutdown /etc/rc6.d/K04custom_shutdown >> logs/install.log
                                sudo chmod a+x /etc/rc0.d/K04custom_shutdown /etc/rc6.d/K04custom_shutdown >> logs/install.log

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
			   echo "bash /home/$USER/lisk-main/lisk.sh reload >> /home/$USER/toolisk/startup.log" >> startup.sh
				sudo chmod u+x startup.sh
			   echo "#!/bin/bash" > temp.sh
                           echo "sudo rm /etc/rc.local" >> temp.sh
			   echo "echo \"#!/bin/sh -e\" > /etc/rc.local | sudo tee -a /etc/rc.local > /dev/null" >> temp.sh
			   echo "echo \"/bin/su $USER -c \\\"cd $(pwd); /usr/bin/screen -dmS startup_lisk bash -c $(pwd)/startup.sh'; exec bash'\\\" > $(pwd)/startup.log\" | sudo tee -a /etc/rc.local > /dev/null" >> temp.sh
			   echo "sleep 10" >> temp.sh
                           echo "echo \"/bin/su $USER -c \\\"cd $(pwd); bash -c $(pwd)/startTool.sh'; exec bash'\\\" >> $(pwd)/startTool.log\" | sudo tee -a /etc/rc.local > /dev/null" >> temp.sh
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
				sudo chmod +x /etc/rc.local
				sudo systemctl enable rc-local >> logs/install.log
				sudo systemctl start rc-local.service >> logs/install.log
				#enabling postgres at startup
				echo "Enabling postgres at startup" >> logs/install.log
				sudo systemctl enable postgresql >> logs/install.log
				sudo update-rc.d postgresql enable >> logs/install.log
				sudo service postgresql start >> logs/install.log
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
