#!/bin/zsh

set -euo pipefail

identity_name="ColorControl Local Development"
if security find-certificate -c "${identity_name}" -Z >/dev/null 2>&1; then
    echo "${identity_name} already exists."
    exit 0
fi

keychain_path="$(security default-keychain -d user | tr -d '"' | sed -E 's/^[[:space:]]+//')"
if [[ "${keychain_path}" != /* ]]; then
    keychain_path="$(security list-keychains -d user | tr -d '"' | sed -E 's/^[[:space:]]+//' | awk -v name="${keychain_path}" '$0 ~ ("/" name "$") || $0 == name { print; exit }')"
fi
if [[ -z "${keychain_path}" ]]; then
    print -u2 "Could not resolve the default user Keychain path."
    exit 1
fi
temporary_directory="$(mktemp -d -t colorcontrol-signing)"
trap 'rm -rf "${temporary_directory}"' EXIT
archive_password="$(uuidgen)$(uuidgen)"

openssl req \
    -newkey rsa:2048 \
    -x509 \
    -sha256 \
    -days 3650 \
    -nodes \
    -subj "/CN=${identity_name}" \
    -addext "basicConstraints=critical,CA:FALSE" \
    -addext "keyUsage=critical,digitalSignature" \
    -addext "extendedKeyUsage=codeSigning" \
    -keyout "${temporary_directory}/private-key.pem" \
    -out "${temporary_directory}/certificate.pem" \
    >/dev/null 2>&1

openssl pkcs12 \
    -export \
    -inkey "${temporary_directory}/private-key.pem" \
    -in "${temporary_directory}/certificate.pem" \
    -name "${identity_name}" \
    -passout "pass:${archive_password}" \
    -out "${temporary_directory}/identity.p12"

security import "${temporary_directory}/identity.p12" \
    -k "${keychain_path}" \
    -P "${archive_password}" \
    -T /usr/bin/codesign \
    >/dev/null

echo "Created ${identity_name} in the default user Keychain."
