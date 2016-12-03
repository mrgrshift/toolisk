#!/bin/bash
source configtoolisk.sh


echo "Start process.. Looking for Inadequate broadhash" > $CONSENSUS_LOG
while true; do
   TIME=$(date +"%H:%M") #add for your local time: -d '6 hours ago')
   LASTLINE=$(tail logs/lisk.log -n 2| grep 'Inadequate')
   if [ -n "$LASTLINE" ]
        then
                echo "Inadequate broadhash $TIME"
                echo "Inadequate broadhash $TIME" >> $CONSENSUS_LOG

                echo "$LASTLINE" >> $CONSENSUS_LOG
		RESPONSE=$(curl -s -k -H "Content-Type: application/json" -X POST -d "{\"secret\":\"$SECRET\"}" $URL_REMOTE)
                curl -s -k -H "Content-Type: application/json" -X POST -d "{\"secret\":\"$SECRET\"}" $URL_LOCAL_DISABLE >> $CONSENSUS_LOG
                echo $RESPONSE | grep "true" > /dev/null
                if [ $? = 0 ]; then
                   echo -e "${GREEN}Forging enabled successfully in remote server${OFF}"
                   echo "Forging enabled successfully in remote server" >> $CONSENSUS_LOG
                   MG_SUBJECT="$DELEGATE_NAME Inadequate broadhash inadequate - Forging enabled in remote server"
                   MG_TEXT="$DELEGATE_NAME broadhash inadequate - Forging enabled in remote server $URL_REMOTE. Error: $LASTLINE"
                else
                   echo -e "${RED}ERROR in switching Forging - Forging not enabled!${OFF}"
                   MG_SUBJECT="$DELEGATE_NAME broadhash inadequate - Forging not enabled!"
                   MG_TEXT="$DELEGATE_NAME broadhash inadequate. ERROR in switching Forging: $RESPONSE - Forging not enabled!. Error $LASTLINE"
                fi

                curl -s --user "api:$API_KEY" $MAILGUN -F from="$MG_FROM" -F to="$MG_TO" -F subject="$MG_SUBJECT" -F text="$MG_TEXT"

            echo
            echo "Switching to Server $IP_SERVER to try and forge"
	    bash lisk.sh reload
            sleep 20
        fi

	ACTUAL_BROADHASH_CONSENSUS=$(tac logs/lisk.log | awk '/ %/ {p=1; split($0, a, " %"); $0=a[1]};
                /Broadhash consensus now /   {p=0; split($0, a, "Broadhash consensus now ");  $0=a[2]; print; exit};
                p' | tac)
    echo "Last time consensus checked: $TIME - $ACTUAL_BROADHASH_CONSENSUS %"
    echo "Last time consensus checked: $TIME - $ACTUAL_BROADHASH_CONSENSUS %" >> $CONSENSUS_LOG
    sleep 10
done

