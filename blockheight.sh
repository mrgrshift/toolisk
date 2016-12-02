#!/bin/bash
source configtoolisk.sh

HEIGHT=1
CHECKSRV=1

first_node() {
        ## Get height of first server
        HEIGHT=1
        HEIGHT=`curl -s "http://127.0.0.1:8000/api/peers"| jq '.peers[0].height'`
        if [ -z "$HEIGHT" ]
        then
                HEIGHT=`curl -s "http://127.0.0.1:8000/api/peers"| jq '.peers[0].height'`
        fi
}

loop_nodes() {
        ## Get height of rest of the servers and see if any are higher
        for i in `seq 1 99`;
    do
                CHECKSRV=`curl -s "http://localhost:8000/api/peers"| jq ".peers[$i].height"`
                if [[ ${CHECKSRV+1} && "$CHECKSRV" -gt "$HEIGHT" ]];
                then
                        HEIGHT=$CHECKSRV
                fi
    done
}

rebuild_alert(){
                TIME=$(date +"%H:%M") #add for your local time: -d '6 hours ago')
                #failover script
                curl -s -k -H "Content-Type: application/json" -X POST -d "{\"secret\":\"$SECRET\"}" $URL_LOCAL_DISABLE
                RESPONSE=$(curl -s -k -H "Content-Type: application/json" -X POST -d "{\"secret\":\"$SECRET\"}" $URL_REMOTE)
                echo $RESPONSE | grep "true" > /dev/null
               if [ $? = 0 ]; then
                   echo -e "${GREEN}Forging activated successfully${OFF}"

                   MG_SUBJECT="$DELEGATE_NAME rebuild started Forging enabled successfully"
                   MG_TEXT="$DELEGATE_NAME rebuild started $HEIGHT - Forging enabled successfully $RESPONSE"
                   echo "Forging enabled > $RESPONSE" >> $BLOCKHEIGHT_LOG
                else
                   echo -e "${RED}Forging not enabled!${OFF} - $RESPONSE"
                   echo "Forging NOT enabled! > $RESPONSE" >> $BLOCKHEIGHT_LOG
                   MG_SUBJECT="$DELEGATE_NAME Forging not enabled!"
                   MG_TEXT="$DELEGATE_NAME rebuild started $HEIGHT - Forging not enabled! $RESPONSE"
                fi

                echo "Starting rebuild at $TIME"
                echo "Starting rebuild at $TIME" >> $BLOCKHEIGHT_LOG
                MG_SUBJECT="$DELEGATE_NAME is in $CHECKSRV height, rebuild started"
                MG_TEXT="$DELEGATE_NAME is in $CHECKSRV height, rebuild started"
                curl -s --user "api:$API_KEY" $MAILGUN -F from="$MG_FROM" -F to="$MG_TO" -F subject="$MG_SUBJECT" -F text="$MG_TEXT"
}

post_rebuild(){
                echo "Rebuild ended.."
                echo "Rebuild ended.." >> $BLOCKHEIGHT_LOG

                HEIGHT=`curl -s "http://127.0.0.1:8000/api/loader/status/sync"| jq '.height'`
                if [ -z "$CHECKSRV" ]
                then
                        HEIGHT=`curl -s "http://127.0.0.1:8000/api/loader/status/sync"| jq '.height'`
                fi


                MG_SUBJECT="$DELEGATE_NAME synchronization ended $HEIGHT"
                MG_TEXT="$DELEGATE_NAME synchronization ended $HEIGHT"
                curl -s --user "api:$API_KEY" $MAILGUN -F from="$MG_FROM" -F to="$MG_TO" -F subject="$MG_SUBJECT" -F text="$MG_TEXT"
}


local_height() {
    ## Get height of this server and see if it's greater or within 4 of the highest
        CHECKSRV=`curl -s "http://127.0.0.1:8000/api/loader/status/sync"| jq '.height'`
        if [ -z "$CHECKSRV" ]
        then
                CHECKSRV=`curl -s "http://127.0.0.1:8000/api/loader/status/sync"| jq '.height'`
        fi
        diff=$(( $HEIGHT - $CHECKSRV ))
        if [ "$diff" -gt "4" ]
        then
                TIME=$(date +"%H:%M") #add for your local time: -d '6 hours ago')
                echo "Starting reload at $TIME"
                cd /home/$USERTOOL/lisk-main/
                bash lisk.sh reload
                sleep 60
                echo "Reload finished"
                CHECKSRV=`curl -s "http://127.0.0.1:8000/api/loader/status/sync"| jq '.height'`
                if [ -z "$CHECKSRV" ]
                then
                        CHECKSRV=`curl -s "http://127.0.0.1:8000/api/loader/status/sync"| jq '.height'`
                fi
                diff=$(( $HEIGHT - $CHECKSRV ))
                ## Rebuild if still out of sync after reload
                if [ "$diff" -gt "5" ]
                then
                        rebuild_alert
                        echo "Rebuilding with heights: " "$CHECKSRV" " -- " "$HEIGHT"
                        bash lisk.sh rebuild
                        sleep 900
                        post_rebuild
                fi
        fi
}


echo "Starting log.. " > $BLOCKHEIGHT_LOG
echo "Starting v1"
while true; do
        first_node
        loop_nodes
        local_height
	TIME=$(date +"%H:%M") #add for your local time: -d '6 hours ago')
        echo -e "${GREEN}$CHECKSRV${OFF} -- $HEIGHT -- $TIME"
        echo "$CHECKSRV -- $HEIGHT -- $TIME" >> $BLOCKHEIGHT_LOG
        sleep 10
done

