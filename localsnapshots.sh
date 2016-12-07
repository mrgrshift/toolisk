#!/bin/bash
#This script will download available snapshots to your localhost to prevent latency when a snapshot is needed

mkdir -p snapshots/
rm -rf snapshots/*

declare -A SNAPSHOTS
#DECLARE YOUR SNAPSHOTS FOR LISK TESTNET:
#	SNAPSHOTS["testnet"]="https://testnet-snapshot.lisknode.io/blockchain.db.gz"

#DECLARE YOUR SNAPSHOTS FOR LISK MAINNET:
	SNAPSHOTS["redsn0w2"]="https://snap.lsknode.org/blockchain.db.gz"
        SNAPSHOTS["official"]="https://downloads.lisk.io/lisk/main/blockchain.db.gz"    ## Official
        SNAPSHOTS["isabella"]="https://snapshot.liskwallet.net/blockchain.db.gz"        ## isabella
        SNAPSHOTS["Gr33nDrag0n"]="https://snapshot.lisknode.io/blockchain.db.gz"        ## Gr33nDrag0n
        SNAPSHOTS["MrV"]="https://lisktools.io/backups/blockchain.db.gz"                ## MrV
        SNAPSHOTS["punkrock"]="https://snapshot.punkrock.me/blockchain.db.gz"           ## punkrock
        SNAPSHOTS["redsn0w"]="https://snapshot.lsknode.org/blockchain.db.gz"            ## redsn0w

initialize_snapshots(){ #initialize snapshot list
	for SNAP in ${!SNAPSHOTS[@]}
	do
		  echo "Check and download snapshot $SNAP : ${SNAPSHOTS[$SNAP]}"
		  curl -O --max-time 300 --connect-timeout 10 GET "${SNAPSHOTS[$SNAP]}" > snapshots/"$SNAP".blockchain.db.gz
		  SNAPSTATUS=$(curl -sI --max-time 300 --connect-timeout 10 "${SNAPSHOTS[$SNAP]}" | grep "HTTP" | cut -f2 -d" ")
		  SNAPLENGTH=$(curl -sI --max-time 300 --connect-timeout 10 "${SNAPSHOTS[$SNAP]}" | grep "Length" | cut -f2 -d" ")
		  SNAPLENGTH="${SNAPLENGTH//[$'\t\r\n ']}"
		if [[ "$SNAPSTATUS" =~ ^[0-9]+$ ]]; then
		  if [ "$SNAPSTATUS" -eq "200" ]
		  then
			  TIME=$(curl -sI --max-time 300 --connect-timeout 10 "${SNAPSHOTS[$SNAP]}" | grep Last-Modified | cut -f2 -d:)
			  TIMESTAMP=$(date -d "$TIME" +"%s")
			  SNAPSHOTS["$SNAP.timestamp"]="$TIMESTAMP"
		   else
			SNAPSHOTS["$SNAP.timestamp"]="0"
		   fi
		fi
	done
}

check_updates(){
        for SNAP in ${!SNAPSHOTS[@]}
        do
		if [[ "${SNAPSHOTS[$SNAP]}" =~ ^[0-9]+$ ]]; then
			NAME=$(echo "$SNAP" | cut -f1 -d.)
                          TIME=$(curl -sI --max-time 300 --connect-timeout 10 "${SNAPSHOTS[$NAME]}" | grep Last-Modified | cut -f2 -d:)
                          TIMESTAMP=$(date -d "$TIME" +"%s")
			if [ "${SNAPSHOTS[$SNAP]}" -ne "$TIMESTAMP" ]; then
				echo "Download new snapshot from $NAME"
		                  curl -O --max-time 300 --connect-timeout 10 GET "${SNAPSHOTS[$NAME]}" > snapshots/"$NAME".blockchain.db.gz
		                  SNAPSTATUS=$(curl -sI --max-time 300 --connect-timeout 10 "${SNAPSHOTS[$NAME]}" | grep "HTTP" | cut -f2 -d" ")
		                  SNAPLENGTH=$(curl -sI --max-time 300 --connect-timeout 10 "${SNAPSHOTS[$NAME]}" | grep "Length" | cut -f2 -d" ")
		                  SNAPLENGTH="${SNAPLENGTH//[$'\t\r\n ']}"
				if [[ "$SNAPSTATUS" =~ ^[0-9]+$ ]]; then
		                  if [ "$SNAPSTATUS" -eq "200" ]
		                  then
		                          TIME=$(curl -sI --max-time 300 --connect-timeout 10 "${SNAPSHOTS[$NAME]}" | grep Last-Modified | cut -f2 -d:)
		                          TIMESTAMP=$(date -d "$TIME" +"%s")
		                          SNAPSHOTS["$SNAP"]="$TIMESTAMP"
		                   else
                		        SNAPSHOTS["$SNAP"]="0"
		                   fi
				fi
			fi
		fi
	done
}


initialize_snapshots

while true; do
	TIME=$(date +"%H:%M") #add for your local time: -d '6 hours ago')
	echo "$TIME start new checkup"
	check_updates
	echo "--------------------------end of checkup"
	sleep 3600 #every 60 minutes
done
