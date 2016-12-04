#!/bin/bash
source configtoolisk.sh

	TIME=$(date +"%H:%M") #add for your local time: -d '6 hours ago')
	#star process.sh
	screen -dmS blockheight bash -c '/home/$USERTOOL/toolisk/blockheight.sh; exec bash'
	echo "$TIME blockheight.sh started. You can view the process here: screen -r blockheight" > /home/$USERTOOL/toolisk/logs/startTool.log
        screen -dmS consensus bash -c '/home/$USERTOOL/toolisk/consensus.sh; exec bash'
        echo "$TIME consensus.sh started. You can view the process here: screen -r consensus" >> /home/$USERTOOL/toolisk/logs/startTool.log

	#email alert
	startup_log=$(cat /home/$USERTOOL/toolisk/logs/startup.log)
	start_log=$(cat /home/$USERTOOL/toolisk/logs/startTool.log)
        MG_SUBJECT="$SERVER_NAME re-started."
        MG_TEXT="$SERVER_NAME re-started. Startup log:"$'\r\n'"$startup_log"$'\r\n'"blockheight script & consensus script log:"$'\r\n'"$start_log"
        curl -s --user "api:$API_KEY" $MAILGUN -F from="$MG_FROM" -F to="$MG_TO" -F subject="$MG_SUBJECT" -F text="$MG_TEXT"

