#!/bin/bash
source configtoolisk.sh

echo "Start consensus watcher" > $CONSENSUS_LOG
while true; do
   TIME=$(date +"%H:%M") #add for your local time: -d '6 hours ago')
   LASTLINE=$(tail ~/lisk-main/logs/lisk.log -n 2| grep 'Inadequate')
   if [ -n "$LASTLINE" ]
        then
                echo "Inadequate broadhash $TIME"
                echo "Inadequate broadhash $TIME" >> $CONSENSUS_LOG

                echo "$LASTLINE" >> $CONSENSUS_LOG
                curl -s -k -H "Content-Type: application/json" -X POST -d "{\"secret\":\"$SECRET\"}" $URL_LOCAL_DISABLE >> $CONSENSUS_LOG
                RESPONSE=$(curl -s -k -H "Content-Type: application/json" -X POST -d "{\"secret\":\"$SECRET\"}" $URL_REMOTE)
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
            sleep 3
        fi
    LASTLINE=$(tail ~/lisk-main/logs/lisk.log -n 2| grep 'consensus')
    echo "Last time consensus checked: $TIME - $LASTLINE"
    sleep 10
done

