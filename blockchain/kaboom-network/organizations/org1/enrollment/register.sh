#!/bin/bash

function registerForOrg1() {
  infoln "Enrolling the CA admin"
  mkdir -p .dist/organizations/peer-organizations/org1.example.com/

  export FABRIC_CA_CLIENT_HOME=${PWD}/.dist/organizations/peer-organizations/org1.example.com/

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 --caname ca-org1 --tls.certfiles "${PWD}/.dist/organizations/peer-organizations/org1.example.com/fabric-ca/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-org1.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-org1.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-org1.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-org1.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/.dist/organizations/peer-organizations/org1.example.com/msp/config.yaml"

  mkdir -p "${PWD}/.dist/organizations/peer-organizations/org1.example.com/msp/tlscacerts"
  cp "${PWD}/.dist/organizations/peer-organizations/org1.example.com/fabric-ca/ca-cert.pem" "${PWD}/.dist/organizations/peer-organizations/org1.example.com/msp/tlscacerts/ca.crt"

  mkdir -p "${PWD}/.dist/organizations/peer-organizations/org1.example.com/tlsca"
  cp "${PWD}/.dist/organizations/peer-organizations/org1.example.com/fabric-ca/ca-cert.pem" "${PWD}/.dist/organizations/peer-organizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem"

  mkdir -p "${PWD}/.dist/organizations/peer-organizations/org1.example.com/ca"
  cp "${PWD}/.dist/organizations/peer-organizations/org1.example.com/fabric-ca/ca-cert.pem" "${PWD}/.dist/organizations/peer-organizations/org1.example.com/ca/ca.org1.example.com-cert.pem"

  infoln "Registering peer0"
  set -x
  fabric-ca-client register --caname ca-org1 --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles "${PWD}/.dist/organizations/peer-organizations/org1.example.com/fabric-ca/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering user"
  set -x
  fabric-ca-client register --caname ca-org1 --id.name user1 --id.secret user1pw --id.type client --tls.certfiles "${PWD}/.dist/organizations/peer-organizations/org1.example.com/fabric-ca/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering the org admin"
  set -x
  fabric-ca-client register --caname ca-org1 --id.name org1admin --id.secret org1adminpw --id.type admin --tls.certfiles "${PWD}/.dist/organizations/peer-organizations/org1.example.com/fabric-ca/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the peer0 msp"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-org1 -M "${PWD}/.dist/organizations/peer-organizations/org1.example.com/peers/peer0.org1.example.com/msp" --csr.hosts peer0.org1.example.com --tls.certfiles "${PWD}/.dist/organizations/peer-organizations/org1.example.com/fabric-ca/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/.dist/organizations/peer-organizations/org1.example.com/msp/config.yaml" "${PWD}/.dist/organizations/peer-organizations/org1.example.com/peers/peer0.org1.example.com/msp/config.yaml"

  infoln "Generating the peer0-tls certificates"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-org1 -M "${PWD}/.dist/organizations/peer-organizations/org1.example.com/peers/peer0.org1.example.com/tls" --enrollment.profile tls --csr.hosts peer0.org1.example.com --csr.hosts localhost --tls.certfiles "${PWD}/.dist/organizations/peer-organizations/org1.example.com/fabric-ca/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/.dist/organizations/peer-organizations/org1.example.com/peers/peer0.org1.example.com/tls/tlscacerts/"* "${PWD}/.dist/organizations/peer-organizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
  cp "${PWD}/.dist/organizations/peer-organizations/org1.example.com/peers/peer0.org1.example.com/tls/signcerts/"* "${PWD}/.dist/organizations/peer-organizations/org1.example.com/peers/peer0.org1.example.com/tls/server.crt"
  cp "${PWD}/.dist/organizations/peer-organizations/org1.example.com/peers/peer0.org1.example.com/tls/keystore/"* "${PWD}/.dist/organizations/peer-organizations/org1.example.com/peers/peer0.org1.example.com/tls/server.key"

  infoln "Generating the user msp"
  set -x
  fabric-ca-client enroll -u https://user1:user1pw@localhost:7054 --caname ca-org1 -M "${PWD}/.dist/organizations/peer-organizations/org1.example.com/users/User1@org1.example.com/msp" --tls.certfiles "${PWD}/.dist/organizations/peer-organizations/org1.example.com/fabric-ca/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/.dist/organizations/peer-organizations/org1.example.com/msp/config.yaml" "${PWD}/.dist/organizations/peer-organizations/org1.example.com/users/User1@org1.example.com/msp/config.yaml"

  infoln "Generating the org admin msp"
  set -x
  fabric-ca-client enroll -u https://org1admin:org1adminpw@localhost:7054 --caname ca-org1 -M "${PWD}/.dist/organizations/peer-organizations/org1.example.com/users/Admin@org1.example.com/msp" --tls.certfiles "${PWD}/.dist/organizations/peer-organizations/org1.example.com/fabric-ca/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/.dist/organizations/peer-organizations/org1.example.com/msp/config.yaml" "${PWD}/.dist/organizations/peer-organizations/org1.example.com/users/Admin@org1.example.com/msp/config.yaml"
}
