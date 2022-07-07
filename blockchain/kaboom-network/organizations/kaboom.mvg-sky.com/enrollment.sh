#!/bin/bash

function enroll() {
  infoln "Enrolling the CA admin"
  mkdir -p "${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com"

  export FABRIC_CA_CLIENT_HOME="${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com"

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 --caname ca.kaboom.mvg-sky.com --tls.certfiles "${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com/fabric-ca/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-kaboom-mvg-sky-com.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-kaboom-mvg-sky-com.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-kaboom-mvg-sky-com.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-kaboom-mvg-sky-com.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com/msp/config.yaml"

  mkdir -p "${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com/msp/tlscacerts"
  cp "${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com/fabric-ca/ca-cert.pem" "${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com/msp/tlscacerts/ca.crt"

  mkdir -p "${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com/tlsca"
  cp "${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com/fabric-ca/ca-cert.pem" "${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com/tlsca/tlsca.kaboom.mvg-sky.com-cert.pem"

  mkdir -p "${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com/ca"
  cp "${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com/fabric-ca/ca-cert.pem" "${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com/ca/ca.kaboom.mvg-sky.com-cert.pem"

  # ======================== ENROLL ADMIN=============================
  infoln "Registering the org admin"
  set -x
  fabric-ca-client register --caname ca.kaboom.mvg-sky.com --id.name org1admin --id.secret org1adminpw --id.type admin --tls.certfiles "${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com/fabric-ca/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the org admin msp"
  set -x
  fabric-ca-client enroll -u https://org1admin:org1adminpw@localhost:7054 --caname ca.kaboom.mvg-sky.com -M "${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com/users/Admin@kaboom.mvg-sky.com/msp" --tls.certfiles "${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com/fabric-ca/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com/msp/config.yaml" "${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com/users/Admin@kaboom.mvg-sky.com/msp/config.yaml"
  # ===================================================================

  # ========================== ENROLL USER=============================
  infoln "Registering user"
  set -x
  fabric-ca-client register --caname ca.kaboom.mvg-sky.com --id.name user1 --id.secret user1pw --id.type client --tls.certfiles "${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com/fabric-ca/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the user msp"
  set -x
  fabric-ca-client enroll -u https://user1:user1pw@localhost:7054 --caname ca.kaboom.mvg-sky.com -M "${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com/users/User1@kaboom.mvg-sky.com/msp" --tls.certfiles "${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com/fabric-ca/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com/msp/config.yaml" "${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com/users/User1@kaboom.mvg-sky.com/msp/config.yaml"
  # ===================================================================

  # ========================== ENROLL PEERS============================
    enrollPeer 0
    enrollPeer 1
    enrollPeer 2
  # ===================================================================
}

function enrollPeer() {
  local PEER="${1}"

  infoln "Registering peer${PEER}"
  set -x
  fabric-ca-client register --caname ca.kaboom.mvg-sky.com --id.name peer${PEER} --id.secret peer${PEER}pw --id.type peer --tls.certfiles "${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com/fabric-ca/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the peer${PEER} msp"
  set -x
  fabric-ca-client enroll -u https://peer${PEER}:peer${PEER}pw@localhost:7054 --caname ca.kaboom.mvg-sky.com -M "${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com/peers/peer${PEER}.kaboom.mvg-sky.com/msp" --csr.hosts peer${PEER}.kaboom.mvg-sky.com --tls.certfiles "${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com/fabric-ca/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com/msp/config.yaml" "${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com/peers/peer${PEER}.kaboom.mvg-sky.com/msp/config.yaml"

  infoln "Generating the peer${PEER}-tls certificates"
  set -x
  fabric-ca-client enroll -u https://peer${PEER}:peer${PEER}pw@localhost:7054 --caname ca.kaboom.mvg-sky.com -M "${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com/peers/peer${PEER}.kaboom.mvg-sky.com/tls" --enrollment.profile tls --csr.hosts peer${PEER}.kaboom.mvg-sky.com --csr.hosts localhost --tls.certfiles "${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com/fabric-ca/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com/peers/peer${PEER}.kaboom.mvg-sky.com/tls/tlscacerts/"* "${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com/peers/peer${PEER}.kaboom.mvg-sky.com/tls/ca.crt"
  cp "${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com/peers/peer${PEER}.kaboom.mvg-sky.com/tls/signcerts/"* "${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com/peers/peer${PEER}.kaboom.mvg-sky.com/tls/server.crt"
  cp "${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com/peers/peer${PEER}.kaboom.mvg-sky.com/tls/keystore/"* "${PWD}/dist/organizations/peerOrganizations/kaboom.mvg-sky.com/peers/peer${PEER}.kaboom.mvg-sky.com/tls/server.key"
}
