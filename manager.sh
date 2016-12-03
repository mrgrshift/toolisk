#!/bin/bash
#Use this script only in one of your servers.
#This script will control forging status
source configtoolisk.sh

SRV_REMOTE="$IP_SERVER:$PORT"  # ip or host if set in /etc/hosts
SRV="127.0.0.1:8000"
LOCAL_HEIGHT="0"
REMOTE_HEIGHT="0"
BAD_CONSENSUS="0"

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
}

get_own_height(){
        LOCAL_HEIGHT=$(curl -s http://$SRV/api/loader/status/sync | jq '.height')
        while [ -z "$LOCAL_HEIGHT" ]
        do
                sleep 1
                LOCAL_HEIGHT=$(curl -s http://$SRV/api/loader/status/sync | jq '.height')
        done

        REMOTE_HEIGHT=$(curl -s http://$SRV_REMOTE/api/loader/status/sync | jq '.height')
        while [ -z "$REMOTE_HEIGHT" ]
        do
                sleep 1
                REMOTE_HEIGHT=$(curl -s http://$SRV_REMOTE/api/loader/status/sync | jq '.height')
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

while true; do
        top_height
        get_own_height
        validate_heights
	get_broadhash

        if [ "$ACTUAL_BROADHASH_CONSENSUS" -lt "51" ]
        then
                ((BAD_CONSENSUS+=1))
        else
                BAD_CONSENSUS="0"
        fi

        forgning=""
	TIME=$(date +"%H:%M") #for your local time add:  -d '6 hours ago')
        diff=$(( $HEIGHT - $LOCAL_HEIGHT ))
        diff2=$(( $HEIGHT - $REMOTE_HEIGHT ))
        if [ "$diff" -gt "$diff2" ] && [ "$ACTUAL_BROADHASH_CONSENSUS" -lt "51" ]
        then
                #enable remote forging
                echo "$TIME Enable remote forging -- Local consensus $ACTUAL_BROADHASH_CONSENSUS %" >> $MANAGER_LOG
                RESPONSE=$(curl -s -k -H "Content-Type: application/json" -X POST -d "{\"secret\":\"$SECRET\"}" $URL_REMOTE)
                echo $RESPONSE >> $MANAGER_LOG
                forging="remote"
		echo
                echo "$TIME Disable local forging" >> $MANAGER_LOG
                curl -s -k -H "Content-Type: application/json" -X POST -d "{\"secret\":\"$SECRET\"}" $URL_LOCAL_DISABLE >> $MANAGER_LOG
        else
                #enable local forging
                echo "$TIME Enable local forging-- Local consensus $ACTUAL_BROADHASH_CONSENSUS %" >> $MANAGER_LOG
                RESPONSE=$(curl -s -k -H "Content-Type: application/json" -X POST -d "{\"secret\":\"$SECRET\"}" $URL_LOCAL)
                echo $RESPONSE >> $MANAGER_LOG
                forging="local"
		echo
                echo "$TIME Disable remote forging" >> $MANAGER_LOG
                curl -s -k -H "Content-Type: application/json" -X POST -d "{\"secret\":\"$SECRET\"}" $URL_REMOTE_DISABLE >> $MANAGER_LOG
        fi

        if [ "$BAD_CONSENSUS" -eq "4" ]
        then
                echo "lisk.sh reload"
                bash lisk.sh reload
                sleep 10
        fi

        TIME=$(date +"%H:%M") #for your local time add:  -d '6 hours ago')

        echo " "
        echo "Top $HEIGHT : local $LOCAL_HEIGHT ($ACTUAL_BROADHASH_CONSENSUS %) $BAD_CONSENSUS - remote $REMOTE_HEIGHT -- $TIME ::: forging: $forging"
        echo "Top $HEIGHT : local $LOCAL_HEIGHT ($ACTUAL_BROADHASH_CONSENSUS %) $BAD_CONSENSUS - remote $REMOTE_HEIGHT -- $TIME ::: forging: $forging" >> $MANAGER_LOG
        sleep 7
done


