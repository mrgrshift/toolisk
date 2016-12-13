#!/bin/bash
#If you are not doing good with this scripts
#Please take a look at this other awesome scripts: https://github.com/mrv777/LiskScripts

#This script will manage you block synchronization


source configtoolisk.sh

HEIGHT="0"		#Highest height
LOCAL_HEIGHT="0"	#Local height
BAD_CONSENSUS="0"
LOCALHOST="127.0.0.1:8000"
REMOTEHOST="$IP_SERVER:8000"
NEXTTURN="0"


localhost_check(){
   l_count="0"
   while true; do
	   STATUS=$(curl -sI --max-time 300 --connect-timeout 10 "http://$LOCALHOST/api/peers" | grep "HTTP" | cut -f2 -d" ")
	   if [[ "$STATUS" =~ ^[0-9]+$ ]]; then
	     if [ "$STATUS" -eq "200" ]; then
		break
	     fi
	   else
		echo -e "${RED}Your localhost is not responding.${OFF}"
		echo "Your localhost is not responding.." >> $BLOCKHEIGHT_LOG
		if [ "$l_count" -gt "3" ]; then
		   #If localhost not respond in 1 minute do reload
                   echo "reload.."
		   echo "reload.." >> $BLOCKHEIGHT_LOG
		   bash lisk.sh reload
		   sleep 15
		else
	           echo "Waiting..$l_count"
		   echo "Waiting..$l_count" >> $BLOCKHEIGHT_LOG
	           sleep 15
		   ((l_count+=1))
		fi
	   fi
   done
}

top_height(){
	## Get height of your 100 peers and save the highest value
	## Thanks to wannabe_RoteBaron for this improvement
	local_count="0"
	HEIGHT=$(curl -s http://$LOCALHOST/api/peers | jq '.peers[].height' | sort -nu | tail -n1)
	## Make sure height is not empty, if it is empty try the call until it is not empty
	while [ -z "$HEIGHT" ]
	do
    	   sleep 1
    	   HEIGHT=$(curl -s http://$LOCALHOST/api/peers | jq '.peers[].height' | sort -nu | tail -n1)
                ((local_count+=1))
                if [ "$local_count" -gt "5" ]; then
                        #If after 5 seconds the remote server does not respond
                        echo "Localhost is not responding to get top_height"
                        echo "Localhost is not responding to get top_height" >> $BLOCKHEIGHT_LOG
                        HEIGHT="0"
                        break
                fi
	done

        if ! [[ "$HEIGHT" =~ ^[0-9]+$ ]];
            then
                echo "$SERVER_NAME is off?"
		echo "$SERVER_NAME is off?" >> $BLOCKHEIGHT_LOG
                HEIGHT="0"
            fi
}

get_remote_height(){
  REMOTE_HEIGHT="0"
  if ! [ -z "$IP_SERVER" ] #If you have remote server configured
  then
        REMOTE_HEIGHT=`curl -s "http://$REMOTEHOST/api/loader/status/sync"| jq '.height'`
	local_count="0"
        while [ -z "$REMOTE_HEIGHT" ]
        do
                sleep 1
                REMOTE_HEIGHT=`curl -s "http://$REMOTEHOST/api/loader/status/sync"| jq '.height'`
                ((local_count+=1))
                if [ "$local_count" -gt "5" ]; then
                        #If after 5 seconds the remote server does not respond
                        echo "Remote server is not responding"
			echo "Remote server is not responding" >> $BLOCKHEIGHT_LOG
                        REMOTE_HEIGHT="0"
                        break
                fi
        done

        if ! [[ "$REMOTE_HEIGHT" =~ ^[0-9]+$ ]];
            then
                echo "$IP_SERVER is off?"
		echo "$IP_SERVER is off?" >> $BLOCKHEIGHT_LOG
                REMOTE_HEIGHT="0"
            fi
   fi
}

get_local_height(){
	local_count="0"
	LOCAL_HEIGHT=`curl -s "http://$LOCALHOST/api/loader/status/sync"| jq '.height'`
	while [ -z "$LOCAL_HEIGHT" ]
	do
	    	sleep 1
		LOCAL_HEIGHT=`curl -s "http://$LOCALHOST/api/loader/status/sync"| jq '.height'`
                ((local_count+=1))
                if [ "$local_count" -gt "5" ]; then
                        #If after 5 seconds the remote server does not respond
                        echo "Localhost is not responding"
                        echo "Localhost is not responding" >> $BLOCKHEIGHT_LOG
                        LOCAL_HEIGHT="0"
                        break
                fi
	done

        if ! [[ "$LOCAL_HEIGHT" =~ ^[0-9]+$ ]];
            then
                echo "$SERVER_NAME is off?"
                LOCAL_HEIGHT="0"
            fi
}

get_nextturn(){
    STATUS=$(curl -sI --max-time 300 --connect-timeout 10 "http://$LOCALHOST/api/peers" | grep "HTTP" | cut -f2 -d" ")
    NEXTTURN="1000"
    if [[ "$STATUS" =~ ^[0-9]+$ ]]; then
     if [ "$STATUS" -eq "200" ]; then  #If localhost is responding
        RESPONSE=$(curl -s http://$LOCALHOST/api/delegates/getNextForgers?limit=101 | jq '.delegates')
        i="0"
        while [ "$i" -lt "101" ]; do
           v1=$(echo $RESPONSE | jq '.['$i']')
           PK="${v1//\"/}"
           if [ "$PK" == "$PUBLICKEY" ]; then
                NEXTTURN=$(( $i * 10 ))
                break
           fi
           ((i+=1))
        done
     fi
    fi
}

get_broadhash(){
	ACTUAL_BROADHASH_CONSENSUS=$(tac logs/lisk.log | awk '/ %/ {p=1; split($0, a, " %"); $0=a[1]};
                /Broadhash consensus now /   {p=0; split($0, a, "Broadhash consensus now ");  $0=a[2]; print; exit};
                p' | tac)

    if ! [ -z "$ACTUAL_BROADHASH_CONSENSUS" ]; then
      if ! [[ "$ACTUAL_BROADHASH_CONSENSUS" =~ ^[0-9]+$ ]]; then
            ACTUAL_BROADHASH_CONSENSUS="0"
      fi
    else
            ACTUAL_BROADHASH_CONSENSUS="0"
    fi
}

find_newest_snap_rebuild(){
   #Add local snapshots availability
   LOCAL_FILE=$(ls -S "$LOCAL_SNAPSHOTS" | head -1)
   if [ -z "$LOCAL_FILE"  ]; then
	SNAPSHOTS=(
	  https://downloads.lisk.io/lisk/main/blockchain.db.gz		## Official
	  https://snapshot.liskwallet.net/blockchain.db.gz		## isabella
	  https://snapshot.lisknode.io/blockchain.db.gz			## Gr33nDrag0n
	  https://lisktools.io/backups/blockchain.db.gz			## MrV
	  https://snapshot.punkrock.me/blockchain.db.gz			## punkrock
	  https://snapshot.lsknode.org/blockchain.db.gz			## redsn0w
	)
	## Thanks to cc001 and hagie for improvements here
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

	    bash lisk.sh rebuild -u $REPO
   else
	echo "Start to rebuild from local snapshot $LOCAL_SNAPSHOTS/$LOCAL_FILE"
	echo "Start to rebuild from local snapshot $LOCAL_SNAPSHOTS/$LOCAL_FILE" >> $BLOCKHEIGHT_LOG
	bash lisk.sh rebuild -l "$LOCAL_SNAPSHOTS/$LOCAL_FILE"
   fi
}

rebuild_alert(){
                TIME=$(date +"%H:%M") #add for your local time: -d '6 hours ago')
	  if ! [ -z "$IP_SERVER" ]; then
                #failover script
		curl -s -k -H "Content-Type: application/json" -X POST -d "{\"secret\":\"$SECRET\"}" $URL_LOCAL_DISABLE
                RESPONSE=$(curl -s -k -H "Content-Type: application/json" -X POST -d "{\"secret\":\"$SECRET\"}" $URL_REMOTE)
                echo $RESPONSE | grep "true" > /dev/null
               if [ $? = 0 ]; then
                   echo -e "${GREEN}Forging activated successfully${OFF}"
                   echo "Forging enabled > $RESPONSE" >> $BLOCKHEIGHT_LOG
                   MG_SUBJECT="$DELEGATE_NAME in $SERVER_NAME T$NEXTTURN s rebuild started Forging enabled successfully in remote $IP_SERVER"
                   MG_TEXT="$DELEGATE_NAME in $SERVER_NAME rebuild started next turn $NEXTTURN. Highest: $HEIGHT - Local: $LOCAL_HEIGHT ($ACTUAL_BROADHASH_CONSENSUS %) $BAD_CONSENSUS"$'\r\n'"Forging enabled successfully in remote $IP_SERVER"$'\r\n'"Response:"$'\r\n'"$RESPONSE"
                else
                   echo -e "${RED}Forging not enabled${OFF} - $RESPONSE"
                   echo "Forging NOT enabled! > $RESPONSE" >> $BLOCKHEIGHT_LOG
                   MG_SUBJECT="$DELEGATE_NAME in $SERVER_NAME rebuild started T$NEXTTURN -- Forging $RESPONSE"
                   MG_TEXT="$DELEGATE_NAME in $SERVER_NAME rebuild started next turn $NEXTTURN"$'\r\n'"Highest: $HEIGHT - Local: $LOCAL_HEIGHT ($ACTUAL_BROADHASH_CONSENSUS %) $BAD_CONSENSUS"$'\r\n'"Forging not enabled! Response: "$'\r\n'"$RESPONSE"
                fi

                echo "Starting rebuild at $TIME"
                echo "Starting rebuild at $TIME" >> $BLOCKHEIGHT_LOG
	  else
	        MG_SUBJECT="$DELEGATE_NAME in $SERVER_NAME rebuild started T$NEXTTURN-- Your delegate is not forging now"
	        MG_TEXT="$DELEGATE_NAME in $SERVER_NAME rebuild started next turn $NEXTTURN"$'\r\n'"Highest: $HEIGHT - Local: $LOCAL_HEIGHT ($ACTUAL_BROADHASH_CONSENSUS %) $BAD_CONSENSUS"$'\r\n'"Forging not enabled because there's no backup node installed"
	  fi
	if ! [ -z "$ALERTS_OFF" ]; then
	      curl -s --user "api:$API_KEY" $MAILGUN -F from="$MG_FROM" -F to="$MG_TO" -F subject="$MG_SUBJECT" -F text="$MG_TEXT"
	fi
}


post_rebuild(){
                echo "Rebuild ended.."
                echo "Rebuild ended.." >> $BLOCKHEIGHT_LOG
		top_height
		get_local_height
		get_broadhash
		get_nextturn
		BAD_CONSENSUS="0"

	if ! [ -z "$ALERTS_OFF" ]; then
                MG_SUBJECT="$DELEGATE_NAME sync ended $NEXTTURN ($ACTUAL_BROADHASH_CONSENSUS %) Highest: $HEIGHT - Local: $LOCAL_HEIGHT"
                MG_TEXT="$DELEGATE_NAME rebuild synchronization ended. Next turn: $NEXTTURN s Highest: $HEIGHT - rebuild: $LOCAL_HEIGHT ($ACTUAL_BROADHASH_CONSENSUS %)"
                curl -s --user "api:$API_KEY" $MAILGUN -F from="$MG_FROM" -F to="$MG_TO" -F subject="$MG_SUBJECT" -F text="$MG_TEXT"
	fi
}

## Thank you corsaro for this improvement
check_if_rebuild_finish(){
	while true; do
		s1=`curl -k -s "http://$LOCALHOST/api/loader/status/sync"| jq '.height'`
		sleep 30
		s2=`curl -k -s "http://$LOCALHOST/api/loader/status/sync"| jq '.height'`

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
        sleep 15
	localhost_check
        echo "Reload finished --"
}

found_fork_alert(){
	FORK=$1
        TIME=$(date +"%H:%M") #add for your local time: -d '6 hours ago')
	echo "$TIME Found fork: $FORK" >> $BLOCKHEIGHT_LOG
	echo "Found fork: $FORK"
        echo "Starting reload at $TIME"
          if ! [ -z "$IP_SERVER" ]; then
                #failover script
                curl -s -k -H "Content-Type: application/json" -X POST -d "{\"secret\":\"$SECRET\"}" $URL_LOCAL_DISABLE
                RESPONSE=$(curl -s -k -H "Content-Type: application/json" -X POST -d "{\"secret\":\"$SECRET\"}" $URL_REMOTE)
                echo $RESPONSE | grep "true" > /dev/null
               if [ $? = 0 ]; then
                   echo -e "${GREEN}Forging activated successfully${OFF}"

                   MG_SUBJECT="$DELEGATE_NAME reload in $SERVER_NAME found fork.$NEXTTURN Started Forging enabled successfully in $IP_SERVER"
                   MG_TEXT="$DELEGATE_NAME reload started in $SERVER_NAME -- Next turn $NEXTTURN s. "$'\r\n'"Found fork: $FORK "$'\r\n'"Forging enabled successfully in $IP_SERVER Response: "$'\r\n'"$RESPONSE"
                   echo "Forging enabled in $IP_SERVER > $RESPONSE" >> $BLOCKHEIGHT_LOG
                else
                   echo -e "${RED}Forging not enabled!${OFF} - $RESPONSE"
                   echo "Forging NOT enabled! > $RESPONSE" >> $BLOCKHEIGHT_LOG
                   MG_SUBJECT="$DELEGATE_NAME reload in $SERVER_NAME found fork.$NEXTTURN Forging $RESPONSE"
                   MG_TEXT="$DELEGATE_NAME reload started in $SERVER_NAME -- Next turn $NEXTTURN s."$'\r\n'"Found fork: "$'\r\n'"$FORK "$'\r\n\r\n'"Forging not enabled. Response:"$'\r\n'"$RESPONSE"
                fi
		if ! [ -z "$ALERTS_OFF" ]; then
                   curl -s --user "api:$API_KEY" $MAILGUN -F from="$MG_FROM" -F to="$MG_TO" -F subject="$MG_SUBJECT" -F text="$MG_TEXT"
		fi
	   fi
	echo "Starting reload $TIME" >> $BLOCKHEIGHT_LOG
	bash lisk.sh reload
	sleep 15
	localhost_check
}

local_height() {
    ## Get height of this server and see if it's greater or within 4 of the highest
	get_local_height
        get_broadhash
	get_nextturn

	is_forked=`tail logs/lisk.log -n 20 | grep "Fork"`
	if [ -n "$is_forked" ] && [ "$NEXTTURN" -gt "30" ]
	then
		echo "Found fork: $is_forked -- turn $NEXTTURN s"
		echo "Found fork: $is_forked -- turn $NEXTTURN s" >> $BLOCKHEIGHT_LOG
		found_fork_alert "$is_forked"
	fi

        diff=$(( $HEIGHT - $LOCAL_HEIGHT ))
        if [ "$diff" -gt "3" ] && [ "$NEXTTURN" -gt "30" ]
        then
		echo "Top height $HEIGHT - Local height $LOCAL_HEIGHT = difference $diff .. reload -- turn $NEXTTURN s"
		echo "Top height $HEIGHT - Local height $LOCAL_HEIGHT = difference $diff .. reload -- turn $NEXTTURN s" >> $BLOCKHEIGHT_LOG
		start_reload
		get_local_height
                diff=$(( $HEIGHT - $LOCAL_HEIGHT ))
                ## Rebuild if still out of sync after reload
                if [ "$diff" -gt "4" ] && [ "$NEXTTURN" -gt "180" ]
                then
                        rebuild_alert
                        echo "Rebuilding with heights: Highest: $HEIGHT -- Local: $LOCAL_HEIGHT ($ACTUAL_BROADHASH_CONSENSUS %) $BAD_CONSENSUS -- turn $NEXTTURN s"
			echo "Rebuilding with heights: Highest: $HEIGHT -- Local: $LOCAL_HEIGHT ($ACTUAL_BROADHASH_CONSENSUS %) $BAD_CONSENSUS -- turn $NEXTTURN s" >> $BLOCKHEIGHT_LOG
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

        if [ "$BAD_CONSENSUS" -eq "8" ] && [ "$diff" -lt "4" ] && [ "$NEXTTURN" -gt "30" ]
        then
                echo "lisk.sh reload"
                bash lisk.sh reload
                sleep 15
        fi


	get_remote_height
	diff=$(( $HEIGHT - $REMOTE_HEIGHT ))
        if [ "$BAD_CONSENSUS" -gt "30" ] && [ "$diff" -lt "4" ] && [ "$NEXTTURN" -gt "180" ]
        then
		#If the low consensus is repeated many times make rebuild as long as remote server is not rebuilding
                rebuild_alert
                echo "Rebuilding with heights: Highest: $HEIGHT -- Local: $LOCAL_HEIGHT ($ACTUAL_BROADHASH_CONSENSUS %) $BAD_CONSENSUS -- turn $NEXTTURN s"
		echo "Rebuilding with heights: Highest: $HEIGHT -- Local: $LOCAL_HEIGHT ($ACTUAL_BROADHASH_CONSENSUS %) $BAD_CONSENSUS -- turn $NEXTTURN s" >> $BLOCKHEIGHT_LOG
                #bash lisk.sh rebuild
                find_newest_snap_rebuild
                check_if_rebuild_finish
                post_rebuild
        fi

        if [ "$BAD_CONSENSUS" -gt "100" ]; then
                #If the low consensus is repeated many times make rebuild
                rebuild_alert
                echo "Rebuilding with heights: Highest: $HEIGHT -- Local: $LOCAL_HEIGHT ($ACTUAL_BROADHASH_CONSENSUS %) $BAD_CONSENSUS -- turn $NEXTTURN s"
                echo "Rebuilding with heights: Highest: $HEIGHT -- Local: $LOCAL_HEIGHT ($ACTUAL_BROADHASH_CONSENSUS %) $BAD_CONSENSUS -- turn $NEXTTURN s" >> $BLOCKHEIGHT_LOG
                #bash lisk.sh rebuild
                find_newest_snap_rebuild
                check_if_rebuild_finish
                post_rebuild
        fi

}


echo "Starting sync manager log.. " > $BLOCKHEIGHT_LOG
echo "Starting sync manager"
while true; do
	TIME=$(date +"%H:%M") #add for your local time: -d '6 hours ago')
	localhost_check
	top_height
	local_height

	get_broadhash
        echo -e "${GREEN}Highest: $HEIGHT${OFF} -- Local: $LOCAL_HEIGHT ($ACTUAL_BROADHASH_CONSENSUS %) $BAD_CONSENSUS -- $TIME -- NEXT TURN IN $NEXTTURN s"
        echo "Highest: $HEIGHT -- Local: $LOCAL_HEIGHT ($ACTUAL_BROADHASH_CONSENSUS %) $BAD_CONSENSUS -- $TIME -- NEXT TURN IN $NEXTTURN s" >> $BLOCKHEIGHT_LOG
        sleep 4
done


