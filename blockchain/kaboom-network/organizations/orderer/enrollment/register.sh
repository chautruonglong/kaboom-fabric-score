#!/bin/bash

function registerForOrdererOrg() {
  infoln "Enrolling the CA admin"
  mkdir -p .dist/organizations/orderer-organizations/example.com

  export FABRIC_CA_CLIENT_HOME=${PWD}/.dist/organizations/orderer-organizations/example.com

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:9054 --caname ca-orderer --tls.certfiles "${PWD}/.dist/organizations/orderer-organizations/example.com/fabric-ca/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/.dist/organizations/orderer-organizations/example.com/msp/config.yaml"

  mkdir -p "${PWD}/.dist/organizations/orderer-organizations/example.com/msp/tlscacerts"
  cp "${PWD}/.dist/organizations/orderer-organizations/example.com/fabric-ca/ca-cert.pem" "${PWD}/.dist/organizations/orderer-organizations/example.com/msp/tlscacerts/tlsca.example.com-cert.pem"

  mkdir -p "${PWD}/.dist/organizations/orderer-organizations/example.com/tlsca"
  cp "${PWD}/.dist/organizations/orderer-organizations/example.com/fabric-ca/ca-cert.pem" "${PWD}/.dist/organizations/orderer-organizations/example.com/tlsca/tlsca.example.com-cert.pem"

  infoln "Registering orderer"
  set -x
  fabric-ca-client register --caname ca-orderer --id.name orderer --id.secret ordererpw --id.type orderer --tls.certfiles "${PWD}/.dist/organizations/orderer-organizations/example.com/fabric-ca/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering the orderer admin"
  set -x
  fabric-ca-client register --caname ca-orderer --id.name ordererAdmin --id.secret ordererAdminpw --id.type admin --tls.certfiles "${PWD}/.dist/organizations/orderer-organizations/example.com/fabric-ca/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the orderer msp"
  set -x
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M "${PWD}/.dist/organizations/orderer-organizations/example.com/orderers/orderer.example.com/msp" --csr.hosts orderer.example.com --csr.hosts localhost --tls.certfiles "${PWD}/.dist/organizations/orderer-organizations/example.com/fabric-ca/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/.dist/organizations/orderer-organizations/example.com/msp/config.yaml" "${PWD}/.dist/organizations/orderer-organizations/example.com/orderers/orderer.example.com/msp/config.yaml"

  infoln "Generating the orderer-tls certificates"
  set -x
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M "${PWD}/.dist/organizations/orderer-organizations/example.com/orderers/orderer.example.com/tls" --enrollment.profile tls --csr.hosts orderer.example.com --csr.hosts localhost --tls.certfiles "${PWD}/.dist/organizations/orderer-organizations/example.com/fabric-ca/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/.dist/organizations/orderer-organizations/example.com/orderers/orderer.example.com/tls/tlscacerts/"* "${PWD}/.dist/organizations/orderer-organizations/example.com/orderers/orderer.example.com/tls/ca.crt"
  cp "${PWD}/.dist/organizations/orderer-organizations/example.com/orderers/orderer.example.com/tls/signcerts/"* "${PWD}/.dist/organizations/orderer-organizations/example.com/orderers/orderer.example.com/tls/server.crt"
  cp "${PWD}/.dist/organizations/orderer-organizations/example.com/orderers/orderer.example.com/tls/keystore/"* "${PWD}/.dist/organizations/orderer-organizations/example.com/orderers/orderer.example.com/tls/server.key"

  mkdir -p "${PWD}/.dist/organizations/orderer-organizations/example.com/orderers/orderer.example.com/msp/tlscacerts"
  cp "${PWD}/.dist/organizations/orderer-organizations/example.com/orderers/orderer.example.com/tls/tlscacerts/"* "${PWD}/.dist/organizations/orderer-organizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"

  infoln "Generating the admin msp"
  set -x
  fabric-ca-client enroll -u https://ordererAdmin:ordererAdminpw@localhost:9054 --caname ca-orderer -M "${PWD}/.dist/organizations/orderer-organizations/example.com/users/Admin@example.com/msp" --tls.certfiles "${PWD}/.dist/organizations/orderer-organizations/example.com/fabric-ca/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/.dist/organizations/orderer-organizations/example.com/msp/config.yaml" "${PWD}/.dist/organizations/orderer-organizations/example.com/users/Admin@example.com/msp/config.yaml"
}
