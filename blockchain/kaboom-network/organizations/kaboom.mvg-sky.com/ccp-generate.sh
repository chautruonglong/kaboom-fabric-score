#!/bin/bash

function one_line_pem {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
}

function json_ccp {
    local PP=$(one_line_pem $6)
    local CP=$(one_line_pem $7)
    sed -e "s/\${P0PORT}/$1/" \
        -e "s/\${P1PORT}/$2/" \
        -e "s/\${P2PORT}/$3/" \
        -e "s/\${CAPORT}/$4/" \
        -e "s/\${LOCAL_MSP}/$5/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        ${PWD}/organizations/kaboom.mvg-sky.com/ccp-template.json
}

function yaml_ccp {
    local PP=$(one_line_pem $6)
    local CP=$(one_line_pem $7)
    sed -e "s/\${P0PORT}/$1/" \
        -e "s/\${P1PORT}/$2/" \
        -e "s/\${P2PORT}/$3/" \
        -e "s/\${CAPORT}/$4/" \
        -e "s/\${LOCAL_MSP}/$5/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        ${PWD}/organizations/kaboom.mvg-sky.com/ccp-template.yaml | sed -e $'s/\\\\n/\\\n          /g'
}

P0PORT=7051
P1PORT=8051
P2PORT=9051
CAPORT=7054
LOCAL_MSP=KaboomMSP
PEERPEM=dist/organizations/peerOrganizations/kaboom.mvg-sky.com/tlsca/tlsca.kaboom.mvg-sky.com-cert.pem
CAPEM=dist/organizations/peerOrganizations/kaboom.mvg-sky.com/ca/ca.kaboom.mvg-sky.com-cert.pem

echo "$(json_ccp $P0PORT $P1PORT $P2PORT $CAPORT $LOCAL_MSP $PEERPEM $CAPEM)" > dist/organizations/peerOrganizations/kaboom.mvg-sky.com/connection.json
echo "$(yaml_ccp $P0PORT $P1PORT $P2PORT $CAPORT $LOCAL_MSP $PEERPEM $CAPEM)" > dist/organizations/peerOrganizations/kaboom.mvg-sky.com/connection.yaml
