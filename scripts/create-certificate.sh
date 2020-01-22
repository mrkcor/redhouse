#!/usr/bin/env bash

mkdir /etc/nginx/ssl 2>/dev/null

PATH_SSL="/etc/nginx/ssl"

# Path to the custom Redhouse $(hostname) Root CA certificate.
PATH_ROOT_CRT="${PATH_SSL}/ca.redhouse-vagrant.$(hostname).crt"
PATH_ROOT_KEY="${PATH_SSL}/ca.redhouse-vagrant.$(hostname).key"

# Path to the custom site certificate.
PATH_CNF="${PATH_SSL}/${1}.cnf"
PATH_CRT="${PATH_SSL}/${1}.crt"
PATH_CSR="${PATH_SSL}/${1}.csr"
PATH_KEY="${PATH_SSL}/${1}.key"

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
    default_days  = 1825
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

# Only generate a certificate if there isn't one already there.
if [ ! -f $PATH_CNF ] || [ ! -f $PATH_KEY ] || [ ! -f $PATH_CRT ]
then
    # Uncomment the global 'copy_extentions' OpenSSL option to ensure the SANs are copied into the certificate.
    sed -i '/copy_extensions\ =\ copy/s/^#\ //g' /etc/ssl/openssl.cnf

    # Generate an OpenSSL configuration file specifically for this certificate.
    cnf="
        ${BASE_CNF}
        [ req_distinguished_name ]
        O  = Vagrant
        C  = UN
        CN = $1

        [ alternate_names ]
        DNS.1 = $1
        DNS.2 = *.$1
    "
    echo "$cnf" > $PATH_CNF

    # Finally, generate the private key and certificate signed with the Redhouse $(hostname) Root CA.
    openssl genrsa -out "$PATH_KEY" 2048 2>/dev/null
    openssl req -config "$PATH_CNF" \
        -key "$PATH_KEY" \
        -new -sha256 -out "$PATH_CSR" 2>/dev/null
    openssl x509 -req -extfile "$PATH_CNF" \
        -extensions server_cert -days 1825 -sha256 \
        -in "$PATH_CSR" \
        -CA "$PATH_ROOT_CRT" -CAkey "$PATH_ROOT_KEY" -CAcreateserial \
        -out "$PATH_CRT" 2>/dev/null
fi
