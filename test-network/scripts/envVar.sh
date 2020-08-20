#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# This is a collection of bash functions used by different scripts

export CORE_PEER_TLS_ENABLED=true
# Orderer CA environment variables
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/example.com/orderers/raft1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export ORDERER2_CA=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer2.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

# Sales1Org environment variables
export PEER0_SALES1_CA=${PWD}/organizations/peerOrganizations/sales1.example.com/peers/peer0.sales1.example.com/tls/ca.crt
export PEER1_SALES1_CA=${PWD}/organizations/peerOrganizations/sales1.example.com/peers/peer1.sales1.example.com/tls/ca.crt

# Sales2Org environment variables
export PEER0_SALES2_CA=${PWD}/organizations/peerOrganizations/sales2.example.com/peers/peer0.sales2.example.com/tls/ca.crt
export PEER1_SALES2_CA=${PWD}/organizations/peerOrganizations/sales2.example.com/peers/peer1.sales2.example.com/tls/ca.crt

# CustomerOrg environment variables
export PEER0_CUSTOMER_CA=${PWD}/organizations/peerOrganizations/customer.example.com/peers/peer0.customer.example.com/tls/ca.crt
export PEER1_CUSTOMER_CA=${PWD}/organizations/peerOrganizations/customer.example.com/peers/peer1.customer.example.com/tls/ca.crt

# Set OrdererOrg.Admin globals
setOrdererGlobals() {
  export CORE_PEER_LOCALMSPID="OrdererMSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/ordererOrganizations/example.com/orderers/raft1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
  export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/ordererOrganizations/example.com/users/Admin@example.com/msp
}

# Set environment variables for the peer org
setGlobals() {
  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  
  echo "Using organization ${USING_ORG}"
  local MYPEER=$2
  
  if [ $USING_ORG == 'sales1' ] && [ $MYPEER -eq 0 ]; then
    export CORE_PEER_LOCALMSPID="Sales1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_SALES1_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/sales1.example.com/users/Admin@sales1.example.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
  elif [ $USING_ORG == 'sales1' ] && [ $MYPEER -eq 1 ]; then
    export CORE_PEER_LOCALMSPID="Sales1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER1_SALES1_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/sales1.example.com/users/Admin@sales1.example.com/msp
    export CORE_PEER_ADDRESS=localhost:8051
  elif [ $USING_ORG == 'sales2' ] && [ $MYPEER -eq 0 ]; then
    export CORE_PEER_LOCALMSPID="Sales2MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_SALES2_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/sales2.example.com/users/Admin@sales2.example.com/msp
    export CORE_PEER_ADDRESS=localhost:9051 
  elif [ $USING_ORG == 'sales2' ] && [ $MYPEER -eq 1 ]; then
    export CORE_PEER_LOCALMSPID="Sales2MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER1_SALES2_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/sales2.example.com/users/Admin@sales2.example.com/msp
    export CORE_PEER_ADDRESS=localhost:10051  
  elif [ $USING_ORG == 'customer' ] && [ $MYPEER -eq 0 ]; then
    export CORE_PEER_LOCALMSPID="CustomerMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_CUSTOMER_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/customer.example.com/users/Admin@customer.example.com/msp
    export CORE_PEER_ADDRESS=localhost:11051
  elif [ $USING_ORG == 'customer' ] && [ $MYPEER -eq 1 ]; then
    export CORE_PEER_LOCALMSPID="CustomerMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER1_CUSTOMER_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/customer.example.com/users/Admin@customer.example.com/msp
    export CORE_PEER_ADDRESS=localhost:12051
  else
    echo "================== ERROR !!! ORG Unknown =================="
  fi

  if [ "$VERBOSE" == "true" ]; then
    env | grep CORE
  fi
}

# parsePeerConnectionParameters $@
# Helper function that sets the peer connection parameters for a chaincode
# operation
parsePeerConnectionParameters() {

  PEER_CONN_PARMS=""
  PEERS=""
  
  while [ "$#" -gt 0 ]; do
    setGlobals $1 $2
    PEER="peer$2.$1"
    ## Set peer adresses
    PEERS="$PEERS $PEER"
    PEER_CONN_PARMS="$PEER_CONN_PARMS --peerAddresses $CORE_PEER_ADDRESS"
    if [ $1 == 'sales1' ]; then
      ## Set path to TLS certificate
      TLSINFO=$(eval echo "--tlsRootCertFiles \$PEER$2_SALES1_CA")
    elif [ $1 == 'sales2' ]; then
      ## Set path to TLS certificate
      TLSINFO=$(eval echo "--tlsRootCertFiles \$PEER$2_SALES2_CA")
    elif [ $1 == 'customer' ]; then
      TLSINFO=$(eval echo "--tlsRootCertFiles \$PEER$2_CUSTOMER_CA")
    fi
    PEER_CONN_PARMS="$PEER_CONN_PARMS $TLSINFO"
    # shift by one to get to the next organization
    shift 2
  done
  # remove leading space for output
  PEERS="$(echo -e "$PEERS" | sed -e 's/^[[:space:]]*//')"
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    echo $'\e[1;31m'!!!!!!!!!!!!!!! $2 !!!!!!!!!!!!!!!!$'\e[0m'
    echo
    exit 1
  fi
}
