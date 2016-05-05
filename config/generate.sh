#!/bin/bash

set -euo pipefail

REPO_HOME=$(git rev-parse --show-toplevel)
KONTROL_URL=${1:-http://127.0.0.1:3000/kite}

KONTROL_DIR="${REPO_HOME}/generated/private_keys/kontrol"
KLOUD_DIR="${REPO_HOME}/generated/private_keys/kloud"
KITE_DIR="${REPO_HOME}/generated/kite_home/koding"

if [[ ! -f "${KONTROL_DIR}/kontrol.pem" ]]; then
	mkdir -p "${KONTROL_DIR}"
	openssl genrsa -out "${KONTROL_DIR}/kontrol.pem" 2048 &>/dev/null
	openssl rsa -in "${KONTROL_DIR}/kontrol.pem" -outform PEM -pubout -out "${KONTROL_DIR}/kontrol.pub" &>/dev/null
	echo "generated ${KONTROL_DIR}/kontrol.pem"
	echo "generated ${KONTROL_DIR}/kontrol.pub"
fi

if [[ ! -f "${KLOUD_DIR}/kloud.pem" ]]; then
	mkdir -p "${KLOUD_DIR}"
	ssh-keygen -q -N "" -t rsa -C hello@koding.com -f "${KLOUD_DIR}/kloud.pem"
	mv "${KLOUD_DIR}"/kloud{.pem,}.pub
	echo "generated ${KLOUD_DIR}/kloud.pem"
	echo "generated ${KLOUD_DIR}/kloud.pub"
fi


if [[ ! -f "${KITE_DIR}/kite.key" ]]; then
	mkdir -p "${KITE_DIR}"
	go run "${REPO_HOME}/go/src/koding/kites/kloud/scripts/kitekey/main.go" \
		-pem "${KONTROL_DIR}/kontrol.pem" \
		-pub "${KONTROL_DIR}/kontrol.pub" \
		-kontrolurl "${KONTROL_URL}" \
		-username koding \
		-file "${KITE_DIR}/kite.key"
	echo "generated ${KITE_DIR}/kite.key"
fi
