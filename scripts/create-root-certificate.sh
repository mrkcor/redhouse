#!/usr/bin/env bash

mkdir /etc/nginx/ssl 2>/dev/null

PATH_SSL="/etc/nginx/ssl"

# Path to the custom Redhouse $(hostname) Root CA certificate.
PATH_ROOT_CNF="${PATH_SSL}/ca.redhouse-vagrant.$(hostname).cnf"
PATH_ROOT_CRT="${PATH_SSL}/ca.redhouse-vagrant.$(hostname).crt"
PATH_ROOT_KEY="${PATH_SSL}/ca.redhouse-vagrant.$(hostname).key"
PATH_ROOT_PEM="/vagrant/ca.redhouse-vagrant.$(hostname).pem"

BASE_CNF="
    [ ca ]
    default_ca = ca_redhouse_$(hostname)

    [ ca_redhouse_$(hostname) ]
    dir           = $PATH_SSL
    certs         = $PATH_SSL
    new_certs_dir = $PATH_SSL

    private_key   = $PATH_ROOT_KEY
    certificate   = $PATH_ROOT_CRT

    default_md    = sha256

    name_opt      = ca_default
    cert_opt      = ca_default
    default_days  = 800
    preserve      = no
    policy        = policy_loose

    [ policy_loose ]
    countryName             = optional
    stateOrProvinceName     = optional
    localityName            = optional
    organizationName        = optional
    organizationalUnitName  = optional
    commonName              = supplied
    emailAddress            = optional

    [ req ]
    prompt              = no
    encrypt_key         = no
    default_bits        = 2048
    distinguished_name  = req_distinguished_name
    string_mask         = utf8only
    default_md          = sha256
    x509_extensions     = v3_ca

    [ v3_ca ]
    authorityKeyIdentifier = keyid,issuer
    basicConstraints       = critical, CA:true, pathlen:0
    keyUsage               = critical, digitalSignature, keyCertSign
    subjectKeyIdentifier   = hash

    [ server_cert ]
    authorityKeyIdentifier = keyid,issuer:always
    basicConstraints       = CA:FALSE
    extendedKeyUsage       = serverAuth
    keyUsage               = critical, digitalSignature, keyEncipherment
    subjectAltName         = @alternate_names
    subjectKeyIdentifier   = hash
"

# Only generate the root certificate when there isn't one already there.
if [ ! -f $PATH_ROOT_CNF ] || [ ! -f $PATH_ROOT_KEY ] || [ ! -f $PATH_ROOT_CRT ]
then
    # Generate an OpenSSL configuration file specifically for this certificate.
    cnf="
        ${BASE_CNF}
        [ req_distinguished_name ]
        O  = Vagrant
        C  = UN
        CN = Redhouse $(hostname) Root CA
    "
    echo "$cnf" > $PATH_ROOT_CNF

    # Finally, generate the private key and certificate.
    openssl genrsa -out "$PATH_ROOT_KEY" 4096 2>/dev/null
    openssl req -config "$PATH_ROOT_CNF" \
        -key "$PATH_ROOT_KEY" \
        -x509 -new -extensions v3_ca -days 3650 -sha256 \
        -out "$PATH_ROOT_CRT" 2>/dev/null

        # Symlink ca to local certificate storage and run update command
        ln --force --symbolic $PATH_ROOT_CRT /usr/local/share/ca-certificates/
        update-ca-certificates

    cat $PATH_ROOT_KEY $PATH_ROOT_CRT > $PATH_ROOT_PEM
fi
