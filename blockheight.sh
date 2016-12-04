#!/bin/bash
#The majority of the code is from MrV's repo, thank you, you can take a look here: https://github.com/mrv777/LiskScripts/blob/master/check_height_and_rebuild.sh


source configtoolisk.sh

HEIGHT=1	#Highest height
CHECKSRV=1	#Local height
BAD_CONSENSUS="0"
SRV="127.0.0.1:8000"

top_height(){
	## Get height of your 100 peers and save the highest value
	## Thanks to wannabe_RoteBaron for this improvement
	HEIGHT=$(curl -s http://$SRV/api/peers | jq '.peers[].height' | sort -nu | tail -n1)
	## Make sure height is not empty, if it is empty try the call until it is not empty
	while [ -z "$HEIGHT" ]
	do
    	   sleep 1
    	   HEIGHT=$(curl -s http://$SRV/api/peers | jq '.peers[].height' | sort -nu | tail -n1)
	done

        if ! [[ "$HEIGHT" =~ ^[0-9]+$ ]];
            then
                echo "$SERVER_NAME is off?"
                HEIGHT="0"
            fi
}

get_remote_height(){
        REMOTE_HEIGHT=`curl -s "http://$IP_SERVER:$PORT/api/loader/status/sync"| jq '.height'`
        while [ -z "$REMOTE_HEIGHT" ]
        do
                sleep 1
                REMOTE_HEIGHT=`curl -s "http://$IP_SERVER:$PORT/api/loader/status/sync"| jq '.height'`
        done

        if ! [[ "$REMOTE_HEIGHT" =~ ^[0-9]+$ ]];
            then
                echo "$IP_SERVER is off?"
                REMOTE_HEIGHT="0"
            fi
}

get_local_height(){
	CHECKSRV=`curl -s "http://$SRV/api/loader/status/sync"| jq '.height'`
	while [ -z "$CHECKSRV" ]
	do
	    	sleep 1
		CHECKSRV=`curl -s "http://$SRV/api/loader/status/sync"| jq '.height'`
	done

        if ! [[ "$CHECKSRV" =~ ^[0-9]+$ ]];
            then
                echo "$SERVER_NAME is off?"
                CHECKSRV="0"
            fi
}

get_broadhash(){
	ACTUAL_BROADHASH_CONSENSUS=$(tac logs/lisk.log | awk '/ %/ {p=1; split($0, a, " %"); $0=a[1]};
                /Broadhash consensus now /   {p=0; split($0, a, "Broadhash consensus now ");  $0=a[2]; print; exit};
                p' | tac)

    if ! [ -z "$ACTUAL_BROADHASH_CONSENSUS" ]
    then
    if ! [[ "$ACTUAL_BROADHASH_CONSENSUS" =~ ^[0-9]+$ ]];
        then
            ACTUAL_BROADHASH_CONSENSUS="0"
        fi
    else
            ACTUAL_BROADHASH_CONSENSUS="0"
    fi
}

## Thanks to cc001 and hagie for improvements here
find_newest_snap_rebuild(){

	SNAPSHOTS=(
	  https://downloads.lisk.io/lisk/main/blockchain.db.gz	## Official
	  https://snapshot.liskwallet.net/blockchain.db.gz		## isabella
	  https://snapshot.lisknode.io/blockchain.db.gz			## Gr33nDrag0n
	  https://lisktools.io/backups/blockchain.db.gz			## MrV
	  https://snapshot.punkrock.me/blockchain.db.gz			## punkrock
	  https://snapshot.lsknode.org/blockchain.db.gz			## redsn0w
	)

	BESTSNAP=""
	BESTTIMESTAMP=0
	BESTSNAPLENGTH=0

	for SNAP in ${SNAPSHOTS[@]}
	do
	  echo "$SNAP"
	  SNAPSTATUS=$(curl -sI "$SNAP" | grep "HTTP" | cut -f2 -d" ")
	  SNAPLENGTH=$(curl -sI "$SNAP" | grep "Length" | cut -f2 -d" ")
	  SNAPLENGTH="${SNAPLENGTH//[$'\t\r\n ']}"
	  if [ "$SNAPSTATUS" -eq "200" ]
	  then
		  TIME=$(curl -sI "$SNAP" | grep Last-Modified | cut -f2 -d:)
		  TIMESTAMP=$(date -d "$TIME" +"%s")
		  echo $TIMESTAMP
		  if [ "$TIMESTAMP" -gt "$BESTTIMESTAMP" ] && [ "$SNAPLENGTH" -gt "$BESTSNAPLENGTH" ]; ## Make sure it is the newest and the largest
		  then
			 BESTSNAP=$SNAP
			 BESTTIMESTAMP=$TIMESTAMP
			 BESTSNAPLENGTH=$SNAPLENGTH
		  fi
	   fi
	done

    REPO=${BESTSNAP%/blockchain.db.gz}
	echo "Newest snap: $BESTSNAP | Rebuilding from $REPO"

    ## bash lisk.sh stop ## Trying to figure out why rebuilding from block 0.  Attempting to stop first to make sure the DB shuts down too
    ## sleep 5
    bash lisk.sh rebuild -u $REPO
}

rebuild_alert(){
                TIME=$(date +"%H:%M") #add for your local time: -d '6 hours ago')
                #failover script
                RESPONSE=$(curl -s -k -H "Content-Type: application/json" -X POST -d "{\"secret\":\"$SECRET\"}" $URL_REMOTE)
                curl -s -k -H "Content-Type: application/json" -X POST -d "{\"secret\":\"$SECRET\"}" $URL_LOCAL_DISABLE
                echo $RESPONSE | grep "true" > /dev/null
               if [ $? = 0 ]; then
                   echo -e "${GREEN}Forging activated successfully${OFF}"
                   echo "Forging enabled > $RESPONSE" >> $BLOCKHEIGHT_LOG
                   MG_SUBJECT="$DELEGATE_NAME in $SERVER_NAME rebuild started Forging enabled successfully in remote $IP_SERVER"
                   MG_TEXT="$DELEGATE_NAME in $SERVER_NAME rebuild started Highest: $HEIGHT - Local: $CHECKSRV ($ACTUAL_BROADHASH_CONSENSUS %) $BAD_CONSENSUS"$'\r\n'"Forging enabled successfully in remote $IP_SERVER"$'\r\n'"Response:"$'\r\n'"$RESPONSE"
                else
                   echo -e "${RED}Forging not enabled${OFF} - $RESPONSE"
                   echo "Forging NOT enabled! > $RESPONSE" >> $BLOCKHEIGHT_LOG
                   MG_SUBJECT="$DELEGATE_NAME in $SERVER_NAME rebuild started -- Forging $RESPONSE"
                   MG_TEXT="$DELEGATE_NAME in $SERVER_NAME rebuild started "$'\r\n'"Highest: $HEIGHT - Local: $CHECKSRV ($ACTUAL_BROADHASH_CONSENSUS %) $BAD_CONSENSUS"$'\r\n'"Forging not enabled! Response: "$'\r\n'"$RESPONSE"
                fi

                echo "Starting rebuild at $TIME"
                echo "Starting rebuild at $TIME" >> $BLOCKHEIGHT_LOG
                curl -s --user "api:$API_KEY" $MAILGUN -F from="$MG_FROM" -F to="$MG_TO" -F subject="$MG_SUBJECT" -F text="$MG_TEXT"
}


post_rebuild(){
                echo "Rebuild ended.."
                echo "Rebuild ended.." >> $BLOCKHEIGHT_LOG
		top_height
		get_local_height
		get_broadhash

                MG_SUBJECT="$DELEGATE_NAME rebuild synchronization ended Highest: $HEIGHT - Local: $CHECKSRV ($ACTUAL_BROADHASH_CONSENSUS %)"
                MG_TEXT="$DELEGATE_NAME rebuild synchronization ended Highest: $HEIGHT - rebuild: $CHECKSRV ($ACTUAL_BROADHASH_CONSENSUS %)"
                curl -s --user "api:$API_KEY" $MAILGUN -F from="$MG_FROM" -F to="$MG_TO" -F subject="$MG_SUBJECT" -F text="$MG_TEXT"
}

## Thank you corsaro for this improvement
check_if_rebuild_finish(){
	while true; do
		s1=`curl -k -s "http://127.0.0.1:8000/api/loader/status/sync"| jq '.height'`
		sleep 30
		s2=`curl -k -s "http://127.0.0.1:8000/api/loader/status/sync"| jq '.height'`

		diff=$(( $s2 - $s1 ))
		if [ "$diff" -gt "10" ]
		then
		   echo "$s2 is too greater then $s1"
		   echo "it looks like rebuild not finished yet. we have not to stop"
		else
		   echo "$s1 - $s2"
		   echo "looks like rebuilding finished. we can stop this"
		   break
		fi
	done
}

start_reload(){
	TIME=$(date +"%H:%M") #add for your local time: -d '6 hours ago')
	echo "Starting reload at $TIME"

        bash lisk.sh reload
        sleep 10
        echo "Reload finished"
}

found_fork_alert(){
	FORK=$1
	echo "Found fork: $FORK" >> $BLOCKHEIGHT_LOG
        TIME=$(date +"%H:%M") #add for your local time: -d '6 hours ago')
        echo "Starting reload at $TIME"
                #failover script
                RESPONSE=$(curl -s -k -H "Content-Type: application/json" -X POST -d "{\"secret\":\"$SECRET\"}" $URL_REMOTE)
                curl -s -k -H "Content-Type: application/json" -X POST -d "{\"secret\":\"$SECRET\"}" $URL_LOCAL_DISABLE
                echo $RESPONSE | grep "true" > /dev/null
               if [ $? = 0 ]; then
                   echo -e "${GREEN}Forging activated successfully${OFF}"

                   MG_SUBJECT="$DELEGATE_NAME reload in $SERVER_NAME found fork. Started Forging enabled successfully in $IP_SERVER"
                   MG_TEXT="$DELEGATE_NAME reload started in $SERVER_NAME. "$'\r\n'"Found fork: $FORK "$'\r\n'"Forging enabled successfully in $IP_SERVER Response: "$'\r\n'"$RESPONSE"
                   echo "Forging enabled in $IP_SERVER > $RESPONSE" >> $BLOCKHEIGHT_LOG
                else
                   echo -e "${RED}Forging not enabled!${OFF} - $RESPONSE"
                   echo "Forging NOT enabled! > $RESPONSE" >> $BLOCKHEIGHT_LOG
                   MG_SUBJECT="$DELEGATE_NAME reload in $SERVER_NAME found fork. Forging $RESPONSE"
                   MG_TEXT="$DELEGATE_NAME reload started in $SERVER_NAME."$'\r\n'"Found fork: "$'\r\n'"$FORK "$'\r\n\r\n'"Forging not enabled. Response:"$'\r\n'"$RESPONSE"
                fi

                curl -s --user "api:$API_KEY" $MAILGUN -F from="$MG_FROM" -F to="$MG_TO" -F subject="$MG_SUBJECT" -F text="$MG_TEXT"
	echo "Starting reload $TIME" >> $BLOCKHEIGHT_LOG
	bash lisk.sh reload
	sleep 10
}

local_height() {
    ## Get height of this server and see if it's greater or within 4 of the highest
	get_local_height
        get_broadhash

	is_forked=`tail logs/lisk.log -n 20 | grep "Fork"`
	if [ -n "$is_forked" ]
	then
		echo "Found fork: $is_forked"
		found_fork_alert "$is_forked"
	fi

        diff=$(( $HEIGHT - $CHECKSRV ))
        if [ "$diff" -gt "3" ]
        then
		start_reload
		get_local_height
                diff=$(( $HEIGHT - $CHECKSRV ))
                ## Rebuild if still out of sync after reload
                if [ "$diff" -gt "4" ]
                then
                        rebuild_alert
                        echo "Rebuilding with heights: Highest: $HEIGHT -- Local: $CHECKSRV ($ACTUAL_BROADHASH_CONSENSUS %) $BAD_CONSENSUS"
                        #bash lisk.sh rebuild
			find_newest_snap_rebuild
                        check_if_rebuild_finish
                        post_rebuild
                fi
        fi

        if [ "$ACTUAL_BROADHASH_CONSENSUS" -lt "51" ]
        then
                ((BAD_CONSENSUS+=1))
        else
                BAD_CONSENSUS="0"
        fi

	get_remote_height
	diff=$(( $HEIGHT - $REMOTE_HEIGHT ))
        if [ "$BAD_CONSENSUS" -eq "10" ] && [ "$diff" -lt "4" ]
        then
		#If the low consensus is repeated many times make rebuild
                rebuild_alert
                echo "Rebuilding with heights: Highest: $HEIGHT -- Local: $CHECKSRV ($ACTUAL_BROADHASH_CONSENSUS %) $BAD_CONSENSUS"
                #bash lisk.sh rebuild
                find_newest_snap_rebuild
                check_if_rebuild_finish
                post_rebuild
        fi
}


echo "Starting log.. " > $BLOCKHEIGHT_LOG
echo "Starting toolisk"
while true; do
	TIME=$(date +"%H:%M") #add for your local time: -d '6 hours ago')
	top_height
	if [ "$HEIGHT" -gt "0" ]
	then
	        local_height
	else
		echo "Waiting for rebuild.. $TIME"
	fi

	get_broadhash
        echo -e "${GREEN}Highest: $HEIGHT${OFF} -- Local: $CHECKSRV ($ACTUAL_BROADHASH_CONSENSUS %) $BAD_CONSENSUS -- $TIME"
        echo "Highest: $HEIGHT -- Local: $CHECKSRV ($ACTUAL_BROADHASH_CONSENSUS %) $BAD_CONSENSUS -- $TIME" >> $BLOCKHEIGHT_LOG
        sleep 9
done


