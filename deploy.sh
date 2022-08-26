#!/bin/bash

source .env

BRIDGE="$BRIDGE_KVM"

NAME=$1

MAC_PARAM=$2

K8S_IPADDR=$3

MAC=$(echo "$MAC_PARAM" | tr '[:lower:]' '[:upper:]')


./install.sh check "$BRIDGE" "$NAME" "$MAC" "$K8S_IPADDR" &&\

./install.sh dhcp-delete "$BRIDGE" "$NAME" "$MAC" "$K8S_IPADDR";

sleep 3

./install.sh dhcp-apply "$BRIDGE" "$NAME" "$MAC" "$K8S_IPADDR" &&\

sleep 4

./install.sh install "$BRIDGE" "$NAME" "$MAC" "$K8S_IPADDR"