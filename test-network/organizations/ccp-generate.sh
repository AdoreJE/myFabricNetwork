#!/bin/bash

function one_line_pem {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
}

function json_ccp {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        organizations/ccp-template.json
}

function yaml_ccp {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        organizations/ccp-template.yaml | sed -e $'s/\\\\n/\\\n          /g'
}

ORG=sales1
P0PORT=7051
CAPORT=7054
PEERPEM=organizations/peerOrganizations/sales1.example.com/tlsca/tlsca.sales1.example.com-cert.pem
CAPEM=organizations/peerOrganizations/sales1.example.com/ca/ca.sales1.example.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/sales1.example.com/connection-sales1.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/sales1.example.com/connection-sales1.yaml

ORG=sales2
P0PORT=9051
CAPORT=8054
PEERPEM=organizations/peerOrganizations/sales2.example.com/tlsca/tlsca.sales2.example.com-cert.pem
CAPEM=organizations/peerOrganizations/sales2.example.com/ca/ca.sales2.example.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/sales2.example.com/connection-sales2.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/sales2.example.com/connection-sales2.yaml

ORG=customer
P0PORT=11051
CAPORT=9054
PEERPEM=organizations/peerOrganizations/customer.example.com/tlsca/tlsca.customer.example.com-cert.pem
CAPEM=organizations/peerOrganizations/customer.example.com/ca/ca.customer.example.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/customer.example.com/connection-customer.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/customer.example.com/connection-customer.yaml
