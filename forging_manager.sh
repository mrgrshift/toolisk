#!/bin/bash
#Use this script only in one of your servers.
#This script will control forging status

#Please vote for mrgr delegate!

source configtoolisk.sh


LOCALHOST="127.0.0.1:8000"
LOCAL_HEIGHT="0"
LOCAL_CONSENSUS="0"
REMOTEHOST="$IP_SERVER:8000"
REMOTE_HEIGHT="0"
REMOTE_CONSENSUS="0"
BAD_CONSENSUS="0"
NEXTTURN="0"

localhost_check(){
   while true; do
           STATUS=$(curl -sI --max-time 300 --connect-timeout 10 "http://$LOCALHOST/api/peers" | grep "HTTP" | cut -f2 -d" ")
           if [[ "$STATUS" =~ ^[0-9]+$ ]]; then
             if [ "$STATUS" -eq "200" ]; then
                break
             fi
           else
              echo -e "${RED}Your localhost is not responding.${OFF}"
              echo "Waiting.. forging in your remote server"
		#Disable local
	      RESPONSE=$(curl -s -k -H "Content-Type: application/json" -X POST -d "{\"secret\":\"$SECRET\"}" $URL_LOCAL_DISABLE)
		#Enable remote
	      RESPONSE=$(curl -s -k -H "Content-Type: application/json" -X POST -d "{\"secret\":\"$SECRET\"}" $URL_REMOTE)
              sleep 15
           fi
   done
}

remote_forging(){
    STATUS=$(curl -sI --max-time 300 --connect-timeout 10 "http://$LOCALHOST/api/peers" | grep "HTTP" | cut -f2 -d" ")
    if [[ "$STATUS" =~ ^[0-9]+$ ]]; then
     if [ "$STATUS" -eq "200" ]; then  #If localhost is responding
	RESPONSE=$(curl -s $URL_LOCAL_FORGING_STATUS | jq '.enabled') #true or false
	if [ "$RESPONSE" = "true" ]; then #If remote is enable, proceed to disable
	    while true; do
		#Disable local
	        curl -s -k -H "Content-Type: application/json" -X POST -d "{\"secret\":\"$SECRET\"}" $URL_LOCAL_DISABLE
		RESPONSE=$(curl -s $URL_LOCAL_FORGING_STATUS | jq '.enabled') #true or false
		if [ "$RESPONSE" = "false" ]; then #It should not be forging in local
		   break;
		fi
	    done
	fi
     fi
    fi

    STATUS=$(curl -sI --max-time 300 --connect-timeout 10 "http://$REMOTEHOST/api/peers" | grep "HTTP" | cut -f2 -d" ")
    if [[ "$STATUS" =~ ^[0-9]+$ ]]; then
     if [ "$STATUS" -eq "200" ]; then  #If remotehost is responding
        RESPONSE=$(curl -s $URL_REMOTE_FORGING_STATUS | jq '.enabled') #true or false
        if [ "$RESPONSE" = "false" ]; then #If remote is disabled, proceed to enable
	    while true; do
	        #Enable remote
	        curl -s -k -H "Content-Type: application/json" -X POST -d "{\"secret\":\"$SECRET\"}" $URL_REMOTE
	        RESPONSE=$(curl -s $URL_REMOTE_FORGING_STATUS | jq '.enabled') #true or false
	        if [ "$RESPONSE" = "true" ]; then #Remote forging = true
	           break;
	        fi
	    done
        fi
     fi
    fi
}

local_forging(){
    STATUS=$(curl -sI --max-time 300 --connect-timeout 10 "http://$REMOTEHOST/api/peers" | grep "HTTP" | cut -f2 -d" ")
    if [[ "$STATUS" =~ ^[0-9]+$ ]]; then
     if [ "$STATUS" -eq "200" ]; then  #If remotehost is responding
        RESPONSE=$(curl -s $URL_REMOTE_FORGING_STATUS | jq '.enabled') #true or false
        if [ "$RESPONSE" = "true" ]; then #If remote is enabled, proceed to disable
	    while true; do
	        #Disable remote
	        curl -s -k -H "Content-Type: application/json" -X POST -d "{\"secret\":\"$SECRET\"}" $URL_REMOTE_DISABLE
	        RESPONSE=$(curl -s $URL_REMOTE_FORGING_STATUS | jq '.enabled') #true or false
	        if [ "$RESPONSE" = "false" ]; then #It should not be forging in remote
	           break;
	        fi
	    done
        fi
     fi
    fi

    STATUS=$(curl -sI --max-time 300 --connect-timeout 10 "http://$LOCALHOST/api/peers" | grep "HTTP" | cut -f2 -d" ")
    if [[ "$STATUS" =~ ^[0-9]+$ ]]; then
     if [ "$STATUS" -eq "200" ]; then  #If localhost is responding
        RESPONSE=$(curl -s $URL_LOCAL_FORGING_STATUS | jq '.enabled') #true or false
        if [ "$RESPONSE" = "false" ]; then #If localhost is disabled, proceed to enable
	    while true; do
	        #Enable local
	        curl -s -k -H "Content-Type: application/json" -X POST -d "{\"secret\":\"$SECRET\"}" $URL_LOCAL
	        RESPONSE=$(curl -s $URL_LOCAL_FORGING_STATUS | jq '.enabled') #true or false
	        if [ "$RESPONSE" = "true" ]; then #Local forging = true
	           break;
	        fi
	    done
        fi
     fi
    fi
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


get_own_height(){
	local_count="0"
        LOCAL_HEIGHT=$(curl -s http://$LOCALHOST/api/loader/status/sync | jq '.height')
        while [ -z "$LOCAL_HEIGHT" ]
        do
    	   sleep 1
    	   LOCAL_HEIGHT=$(curl -s http://$LOCALHOST/api/loader/status/sync | jq '.height')
                ((local_count+=1))
                if [ "$local_count" -gt "5" ]; then
                        #If after 5 seconds the remote server does not respond
                        echo "Localhost is not responding to get local_height"
                        echo "Localhost is not responding to get local_height" >> $BLOCKHEIGHT_LOG
                        LOCAL_HEIGHT="0"
                        break
                fi
                sleep 1
                LOCAL_HEIGHT=$(curl -s http://$LOCALHOST/api/loader/status/sync | jq '.height')
        done

        REMOTE_HEIGHT=$(curl -s http://$REMOTEHOST/api/loader/status/sync | jq '.height')
	local_count="0"
        while [ -z "$REMOTE_HEIGHT" ]
        do
                sleep 1
                REMOTE_HEIGHT=$(curl -s http://$REMOTEHOST/api/loader/status/sync | jq '.height')
		((local_count+=1))
		if [ "$local_count" -gt "5" ]; then
			#If after 5 seconds the remote server does not respond
			echo "Remote server not responding to get remote_height"
			REMOTE_HEIGHT="0"
			break
		fi
        done
}

validate_heights(){
    if ! [[ "$HEIGHT" =~ ^[0-9]+$ ]];
        then
            echo  "LOCALHOST is off?"
            HEIGHT="0"
        fi
    if ! [ -z "$LOCAL_HEIGHT" ]
    then
    if ! [[ "$LOCAL_HEIGHT" =~ ^[0-9]+$ ]];
        then
            echo  "LOCALHOST is off?"
            LOCAL_HEIGHT="0"
        fi
    else
            LOCAL_HEIGHT="0"
    fi
    if ! [ -z "$REMOTE_HEIGHT" ]
    then
    if ! [[ "$REMOTE_HEIGHT" =~ ^[0-9]+$ ]];
        then
            echo "$IP_SERVER is off?"
            REMOTE_HEIGHT="0"
        fi
    else
            REMOTE_HEIGHT="0"
    fi
}

get_nextturn(){
    STATUS=$(curl -sI --max-time 300 --connect-timeout 10 "http://$LOCALHOST/api/peers" | grep "HTTP" | cut -f2 -d" ")
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

get_remote_consensus(){
    STATUS=$(curl -sI --max-time 300 --connect-timeout 10 "http://$REMOTEHOST/api/peers" | grep "HTTP" | cut -f2 -d" ")
    REMOTE_CONSENSUS="0"
    if [[ "$STATUS" =~ ^[0-9]+$ ]]; then
     if [ "$STATUS" -eq "200" ]; then  #If localhost is responding
        REMOTE_CONSENSUS=$(curl -s http://$REMOTEHOST/api/loader/status/sync | jq '.consensus')
     fi
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

counter_check="0"
check_github_updates(){
    ((counter_check+=1))
    if [ "$counter_check" -gt "1" ]; then  #Verification period = 10000 every 7s =~19Hours. every 10s =~27Hours
        need_update=$([ $(git rev-parse HEAD) = $(git ls-remote $(git rev-parse --abbrev-ref @{u} | sed 's/\// /g') | cut -f1) ] && echo "false" || echo "true")
        if [ "$need_update" = "true" ]
        then
            MG_SUBJECT="There's new version of toolisk"
            MG_TEXT="Please update toolisk tool with the following commands:"$'\r\n'"cd ~/toolisk/"$'\r\n'"git checkout ."$'\r\n'"git pull"
            curl -s --user "api:$API_KEY" $MAILGUN -F from="$MG_FROM" -F to="$MG_TO" -F subject="$MG_SUBJECT" -F text="$MG_TEXT"
	    counter_check="0"
        fi
    fi
}


forging_test(){
	echo "This test will enable forging and disable it into your remote server. This to ensure your delegate node is capable to do this commands."

        read -p "Do you want to continue (y/n)?" -n 1 -r
        if [[  $REPLY =~ ^[Yy]$ ]]
           then
		echo " "
		echo -n "... "
		R1=$(curl -s -k -H "Content-Type: application/json" -X POST -d "{\"secret\":\"$SECRET\"}" $URL_REMOTE)
		RESPONSE=$(curl -s $URL_REMOTE_FORGING_STATUS | jq '.enabled') #true or false
        	if [ "$RESPONSE" = "true" ]; then
		  echo -e "${GREEN}Forging enabled successfully in remote server.${OFF}"
		  echo -n "... "
		  R1=$(curl -s -k -H "Content-Type: application/json" -X POST -d "{\"secret\":\"$SECRET\"}" $URL_REMOTE_DISABLE)
		  RESPONSE=$(curl -s $URL_REMOTE_FORGING_STATUS | jq '.enabled') #true or false
		   if [ "$RESPONSE" = "false" ]; then
			echo -e "${GREEN}Forging disabled successfully in remote server.${OFF}"
			echo " "
			echo " "
			echo "***Your installation is perfect!"
		   else
			echo -e "${RED}Error:${OFF} $R1"
			echo "Error in disabling forging, please disable forging manually to prevent future errors."
			echo " "
			echo " "
			echo "***Your installation is good, you can use failover."
		   fi
		else
		   echo " "
		   echo -e "${RED}Error:${OFF} $R1"
		   echo -e "${RED}***Something is wrong, please run again bash install.sh and make sure you have entered the right information.${OFF}"
		fi
           else
                echo " "
                echo "Tests for failover has been stopped."
           fi
}


if [ "$1" != "test"  ]; then
echo "Starting forging manager"
while true; do
	localhost_check
        top_height
        get_own_height
        validate_heights
	get_broadhash
	get_nextturn
	get_remote_consensus

        if [ "$ACTUAL_BROADHASH_CONSENSUS" -lt "51" ]
        then
                ((BAD_CONSENSUS+=1))
        else
                BAD_CONSENSUS="0"
        fi

        forgning=""
	TIME=$(date +"%H:%M") #for your local time add:  -d '6 hours ago')
   if ! [ -z "$IP_SERVER" ]; then
        diff=$(( $HEIGHT - $LOCAL_HEIGHT ))
        if [ "$diff" -eq "-1" ] || [ "$diff" -eq "1" ]; then
                diff="0"
        fi
        diff2=$(( $HEIGHT - $REMOTE_HEIGHT ))
        if [ "$diff2" -eq "-1" ] || [ "$diff2" -eq "1" ]; then
                diff2="0"
        fi
        if [ "$diff" -gt "$diff2" ] || ([ "$ACTUAL_BROADHASH_CONSENSUS" -lt "51" ] && [ "$diff2" -lt "4" ])
        then
                #enable remote forging
		remote_forging
                forging="remote"
        else
                #enable local forging
		local_forging
                forging="local"
        fi
   else
        #enable local forging
	local_forging
        forging="local"
        echo -e "${YELLOW}Reminder --- Install another server for backup${OFF}"
   fi


        TIME=$(date +"%H:%M") #for your local time add:  -d '6 hours ago')

        echo " "
	if [ "$NEXTTURN" -lt "60" ]; then
	   color=$RED
	else
	   color=$GREEN
	fi
        echo -e "${color}NEXT TURN IN $NEXTTURN s${OFF}         Local  $LOCAL_HEIGHT -- Diff $diff -- Consensus $ACTUAL_BROADHASH_CONSENSUS % ($BAD_CONSENSUS)"
        echo "Top height $HEIGHT        Remote $REMOTE_HEIGHT -- Diff $diff2 -- Consensus $REMOTE_CONSENSUS % -- $TIME ::: forging: $forging"
#        echo "Top $HEIGHT : local $LOCAL_HEIGHT ($ACTUAL_BROADHASH_CONSENSUS %) $BAD_CONSENSUS - remote $REMOTE_HEIGHT -- $TIME ::: forging: $forging -- NEXT TURN IN $NEXTTURN s" >> $MANAGER_LOG

	#Actual status report
	echo "<table>" > $MANAGER_LOG
	echo "<tr><td>Top height </td><td>$HEIGHT</td></tr>" >> $MANAGER_LOG
	echo "<tr><td>Local height </td><td>$LOCAL_HEIGHT</td></tr>" >> $MANAGER_LOG
	echo "<tr><td>Remote height </td><td>$REMOTE_HEIGHT</td></tr>" >> $MANAGER_LOG
	echo "<tr><td>Local consensus </td><td>$ACTUAL_BROADHASH_CONSENSUS %</td></tr>" >> $MANAGER_LOG
	echo "<tr><td>Remote consensus </td><td>$REMOTE_CONSENSUS %</td></tr>" >> $MANAGER_LOG
	echo "<tr><td>Forging </td><td>$forging</td></tr>" >> $MANAGER_LOG
	echo "<tr><td>Next turn in</td><td><b><span id=\"timer\">$NEXTTURN s</span></b></td></tr>" >> $MANAGER_LOG
	RESPONSE=$(curl -s http://$LOCALHOST/api/accounts/delegates?address=$DELEGATE_ADDRESS | jq '.delegates[] | select(.username=="'$DELEGATE_NAME'")')
	PRODUCTIVITY=$(echo $RESPONSE | jq '.productivity')
	PB=$(echo $RESPONSE | jq '.producedblocks')
	MB=$(echo $RESPONSE | jq '.missedblocks')
	RATE=$(echo $RESPONSE | jq '.rate')
	APPR=$(echo $RESPONSE | jq '.approval')
	echo "<tr><td>Productivity</td><td>$PRODUCTIVITY</td></tr>" >> $MANAGER_LOG
	echo "<tr><td>Produced blocks</td><td>$PB</td></tr>" >> $MANAGER_LOG
	echo "<tr><td>Missed blocks</td><td>$MB</td></tr>" >> $MANAGER_LOG
	echo "<tr><td>Rank</td><td>$RATE</td></tr>" >> $MANAGER_LOG
	echo "<tr><td>Approval</td><td>$APPR</td></tr>" >> $MANAGER_LOG
	echo "</table>" >> $MANAGER_LOG
	echo "<script>var nextTurn=$NEXTTURN;</script>" >> $MANAGER_LOG
        sleep 5
done
else
	forging_test
fi

