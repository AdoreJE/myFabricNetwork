# myFabricNetwork

fabric network 구축하기

블로그 참고 : https://medium.com/@taehyoung46/hyperledger-fabric-네트워크-구축하기-e6d346c995ec

## 전체 구성

4개의 Organizations : OrdererOrg, Sales1Org, Sales2Org, CustomerOrg

각 Org 별 2개의 peer

- OrdererOrg : raft1, raft2
- Sales1Org : peer0, peer1
- Sales2Org : peer0, peer1
- CustomerOrg : peer0, peer1

두개의 channel 생성

- mychannel1 : Sales1Org, CustomerOrg
- mychannel1 : Sales2Org, CustomerOrg

각 채널의 anchor peer

- mychannel1 : peer0.sales1, peer0.customer
- mychannel2 : peer0.sales2, peer1.customer

각 peer 별로 couchdb 연결

- peer0.sales1 : couchdb0 (localhost:5984)
- peer0.sales2 : couchdb2 (localhost:7984)
- peer1.sales1 : couchdb1 (localhost:6984)
- peer1.sales2 : couchdb3 (localhost:8984)
- peer0.customer : couchdb4 (localhost:9984)
- peer1.customer : couchdb5 (localhost:10984)

각 채널로 fabcar chaincode 배포

## 구동

1. clone

```bash
git clone https://github.com/AdoreJE/myFabricNetwork
```

2. network up

```bash
cd myFabricNetwork/test-network
./network.sh up -ca -s couchdb
```

3. create channel

```bash
./network.sh createChannel
```

4. deploy chaincode

```bash
./network.sh deployCC -cci initLedger -ccn fabcar -ccp ../chaincode/go
```

5. 환경변수 설정

```bash
# 모든 peer 에서 공통으로 적용
export CORE_PEER_TLS_ENABLED=true
export FABRIC_CFG_PATH=${PWD}/../config

### peer0.sales1
export CORE_PEER_LOCALMSPID="Sales1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/sales1.example.com/peers/peer0.sales1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/sales1.example.com/users/Admin@sales1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051

#### 다른 peer 의 환경변수는 아래 부록 참고
```

6. smart contract 실행

peer0.sales1에 대한 환경변수를 설정한 경우

```bash
peer chaincode query -C mychannel1 -n fabcar-ch1 -c '{"function":"queryAllCars","Args":[""]}'
```

peer0.sales2에 대한 환경변수를 설정한 경우

```bash
peer chaincode query -C mychannel2 -n fabcar-ch2 -c '{"function":"queryAllCars","Args":[""]}'
```

7. couchdb 확인
   브라우저에서 couchdb0 에 접속

```
localhost:5984/_utils/#login
```

Username : admin

Password : adminpw

mychannel1_fabcar-ch1 확인

## 부록

환경변수

```bash
# 모든 peer 에서 공통으로 적용
export CORE_PEER_TLS_ENABLED=true
export FABRIC_CFG_PATH=${PWD}/../config

### peer0.sales1
export CORE_PEER_LOCALMSPID="Sales1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/sales1.example.com/peers/peer0.sales1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/sales1.example.com/users/Admin@sales1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051

### peer1.sales1
export CORE_PEER_LOCALMSPID="Sales1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/sales1.example.com/peers/peer1.sales1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/sales1.example.com/users/Admin@sales1.example.com/msp
export CORE_PEER_ADDRESS=localhost:8051

### peer0.sales2
export CORE_PEER_LOCALMSPID="Sales2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/sales2.example.com/peers/peer0.sales2.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/sales2.example.com/users/Admin@sales2.example.com/msp
export CORE_PEER_ADDRESS=localhost:9051

### peer1.sales2
export CORE_PEER_LOCALMSPID="Sales2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/sales2.example.com/peers/peer1.sales2.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/sales2.example.com/users/Admin@sales2.example.com/msp
export CORE_PEER_ADDRESS=localhost:10051

### peer0.customer
export CORE_PEER_LOCALMSPID="CustomerMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/customer.example.com/peers/peer0.customer.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/customer.example.com/users/Admin@customer.example.com/msp
export CORE_PEER_ADDRESS=localhost:11051

### peer1.customer
export CORE_PEER_LOCALMSPID="CustomerMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/customer.example.com/peers/peer1.customer.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/customer.example.com/users/Admin@customer.example.com/msp
export CORE_PEER_ADDRESS=localhost:12051
```
