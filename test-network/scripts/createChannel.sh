#!/bin/bash

CHANNEL_NAME="$1"
DELAY="$2"
MAX_RETRY="$3"
VERBOSE="$4"
: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${MAX_RETRY:="5"}
: ${VERBOSE:="false"}

# import utils
. scripts/envVar.sh

if [ ! -d "channel-artifacts" ]; then
	mkdir channel-artifacts
fi

createChannelTx() {
	set -x
	echo $CHANNEL_NAME
	if [ $1 -eq 1 ]; then
		configtxgen -profile Channel1 -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}1.tx -channelID ${CHANNEL_NAME}1
	elif [ $1 -eq 2 ]; then
		configtxgen -profile Channel2 -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}2.tx -channelID ${CHANNEL_NAME}2
	fi
	res=$?
	set +x
	if [ $res -ne 0 ]; then
		echo "Failed to generate channel configuration transaction..."
		exit 1
	fi
	echo

}

createAncorPeerTx() {

	for org in Sales1 Sales2 Customer; do

	echo "#######    Generating anchor peer update transaction for ${org}Org  ##########"
	set -x
	if [ ${org} == 'Sales1' ]; then
		configtxgen -profile Channel1 -outputAnchorPeersUpdate ./channel-artifacts/${org}MSPanchors.tx -channelID ${CHANNEL_NAME}1 -asOrg ${org}Org
	elif [ ${org} == 'Sales2' ]; then
		configtxgen -profile Channel2 -outputAnchorPeersUpdate ./channel-artifacts/${org}MSPanchors.tx -channelID ${CHANNEL_NAME}2 -asOrg ${org}Org
	elif [ ${org} == 'Customer' ]; then
		configtxgen -profile Channel1 -outputAnchorPeersUpdate ./channel-artifacts/${org}MSPanchorsChannel1.tx -channelID ${CHANNEL_NAME}1 -asOrg ${org}Org
		configtxgen -profile Channel2 -outputAnchorPeersUpdate ./channel-artifacts/${org}MSPanchorsChannel2.tx -channelID ${CHANNEL_NAME}2 -asOrg ${org}Org
	fi
	res=$?
	set +x
	if [ $res -ne 0 ]; then
		echo "Failed to generate anchor peer update transaction for ${org}Org..."
		exit 1
	fi
	echo
	done
}

createChannel() {
	if [ $1 -eq 1 ]; then
		setGlobals sales1 0
		MY_CHANNEL_NAME=${CHANNEL_NAME}1
	elif [ $1 -eq 2 ]; then
		setGlobals sales2 0
		MY_CHANNEL_NAME=${CHANNEL_NAME}2
	fi
	# Poll in case the raft leader is not set yet
	local rc=1
	local COUNTER=1
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
		sleep $DELAY
		set -x
		peer channel create -o localhost:7050 -c ${MY_CHANNEL_NAME} --ordererTLSHostnameOverride raft1.example.com -f ./channel-artifacts/${MY_CHANNEL_NAME}.tx --outputBlock ./channel-artifacts/${MY_CHANNEL_NAME}.block --tls --cafile $ORDERER_CA >&log.txt
		res=$?
		set +x
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "Channel creation failed"
	echo
	echo "===================== Channel '$MY_CHANNEL_NAME' created ===================== "
	echo

}

# queryCommitted ORG
joinChannel() {
	ORG=$1
	for var in 0 1; do
		setGlobals $ORG $var
		if [ $ORG == 'sales1' ]; then
			MY_CHANNEL_NAME=${CHANNEL_NAME}1
		elif [ $ORG == 'sales2' ]; then
			MY_CHANNEL_NAME=${CHANNEL_NAME}2
		elif [ $ORG == 'customer' ] && [ $var -eq 0 ]; then
			MY_CHANNEL_NAME=${CHANNEL_NAME}1
		elif [ $ORG == 'customer' ] && [ $var -eq 1 ]; then
			MY_CHANNEL_NAME=${CHANNEL_NAME}2
		fi
		echo $MY_CHANNEL_NAME
		local rc=1
		local COUNTER=1
		## Sometimes Join takes time, hence retry
		while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
		sleep $DELAY
		set -x
		peer channel join -b ./channel-artifacts/$MY_CHANNEL_NAME.block >&log.txt
		res=$?
		set +x
			let rc=$res
			COUNTER=$(expr $COUNTER + 1)
		done
		cat log.txt
		echo
		verifyResult $res "After $MAX_RETRY attempts, peer${var}.${ORG} has failed to join channel '$MY_CHANNEL_NAME' "
	done
}

updateAnchorPeers() {
	ORG=$1
	if [ $ORG == 'sales1' ]; then
		MY_CHANNEL_NAME=${CHANNEL_NAME}1
		ANCHOR_CHANNEL=""
	elif [ $ORG == 'sales2' ]; then
		MY_CHANNEL_NAME=${CHANNEL_NAME}2
		ANCHOR_CHANNEL=""
	elif [ $ORG == 'customer' ] && [ $2 -eq 0 ]; then
		MY_CHANNEL_NAME=${CHANNEL_NAME}1
		ANCHOR_CHANNEL='Channel1'
	elif [ $ORG == 'customer' ] && [ $2 -eq 1 ]; then
		MY_CHANNEL_NAME=${CHANNEL_NAME}2
		ANCHOR_CHANNEL='Channel2'
	fi
	
	setGlobals $ORG $2
	local rc=1
	local COUNTER=1
	## Sometimes Join takes time, hence retry
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    set -x
		peer channel update -o localhost:7050 --ordererTLSHostnameOverride raft1.example.com -c $MY_CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors${ANCHOR_CHANNEL}.tx --tls --cafile $ORDERER_CA >&log.txt
    res=$?
    set +x
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "Anchor peer update failed"
	echo "===================== Anchor peers updated for org '$CORE_PEER_LOCALMSPID' on channel '$MY_CHANNEL_NAME' ===================== "
	sleep $DELAY
	echo
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
    echo
    exit 1
  fi
}

FABRIC_CFG_PATH=${PWD}/configtx

## Create channeltx
echo "### Generating channel create transaction '${CHANNEL_NAME}1.tx' ###"
createChannelTx 1

echo "### Generating channel create transaction '${CHANNEL_NAME}2.tx' ###"
createChannelTx 2

## Create anchorpeertx
echo "### Generating anchor peer update transactions ###"
createAncorPeerTx

FABRIC_CFG_PATH=$PWD/../config/

## Create channel
echo "Creating channel "${CHANNEL_NAME}1
createChannel 1
echo "Creating channel "${CHANNEL_NAME}2
createChannel 2

## Join all the peers to the channel
echo "Join Sales1 peers to the channel..."
joinChannel sales1 
echo "Join Sales2 peers to the channel..."
joinChannel sales2
echo "Join Customer peers to the channel..."
joinChannel customer

## Set the anchor peers for each org in the channel
echo "Updating anchor peers for sales1..."
updateAnchorPeers sales1 0
echo "Updating anchor peers for sales2..."
updateAnchorPeers sales2 0
echo "Updating anchor peers for customer..."
updateAnchorPeers customer 0
updateAnchorPeers customer 1

echo
echo "========= Channel successfully joined =========== "
echo

exit 0
