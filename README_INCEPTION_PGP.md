

## -0. Import pgp CowboyAI public keys - these should already be present on the inception_node in /etc/pgp/pgp_CowboyAI@inception_key.pub.asc
https://raymii.org/s/articles/GPG_noninteractive_batch_sign_trust_and_send_gnupg_keys.html
Check below how to export them from the node that has the private keys.
```shell
gpg --list-secret-keys --with-subkey-fingerprint <filename>
gpg --list-public-keys --with-subkey-fingerprint <filename>

gpg --with-fingerprint --show-keys sparkx@twr-z790_encr_public_key.pub.asc
gpg --import sparkx@twr-z790_encr_public_key.pub.asc

gpg –list-keys –fingerprint 8A581CE7| gawk ‘NR==2 {gsub(/ /, “”); printf(“%s:6:\n”, $0)}’ | gpg –import-ownertrust
```

```
gpg --import fake

curl --tlsv1.2 -L https://sks-keyservers.net/sks-keyservers.netCA.pem -O
curl --tlsv1.2 -L https://sks-keyservers.net/sks-keyservers.netCA.pem.asc -O

# Move hkps pool cert to cert store
sudo cp -v sks-keyservers.netCA.pem /etc/ssl/certs/

# Import key for HKPS signature
gpg --recv-key 0x0B7F8B60E3EDFAE3

# Verify HKPS cert
gpg --verify ~/Downloads/opgp/sks-keyservers.netCA.pem.asc /etc/ssl/certs/sks-keyservers.netCA.pem


#!/usr/bin/env bash
rm -rf .gnupg
mkdir -m 0700 .gnupg
touch .gnupg/gpg.conf
chmod 600 .gnupg/gpg.conf
tail -n +4 /usr/share/gnupg2/gpg-conf.skel > .gnupg/gpg.conf

cd .gnupg
# I removed this line since these are created if a list key is done.
# touch .gnupg/{pub,sec}ring.gpg
gpg2 --list-keys


cat >keydetails <<EOF
    %echo Generating a basic OpenPGP key
    Key-Type: RSA
    Key-Length: 2048
    Subkey-Type: RSA
    Subkey-Length: 2048
    Name-Real: User 1
    Name-Comment: User 1
    Name-Email: user@1.com
    Expire-Date: 0
    Passphrase: kljfhslfjkhsaljkhsdflgjkhsd
    # %no-ask-passphrase
    # %no-protection
    %pubring pubring.kbx
    %secring trustdb.gpg
    # Do a commit here, so that we can later print "done" :-)
    %commit
    %echo done
EOF

gpg2 --verbose --batch --gen-key keydetails

# Set trust to 5 for the key so we can encrypt without prompt.
echo -e "5\ny\n" |  gpg2 --command-fd 0 --expert --edit-key user@1.com trust;

# Test that the key was created and the permission the trust was set.
gpg2 --list-keys

# Test the key can encrypt and decrypt.
gpg2 -e -a -r user@1.com keydetails

# Delete the options and decrypt the original to stdout.
rm keydetails
gpg2 -d keydetails.asc
rm keydetails.asc
```

## 0. Create temporary folders structure and configuration files that will not persist after reboot
https://serverfault.com/questions/691120/how-to-generate-gpg-key-without-user-interaction
```shell
## https://www.gnupg.org/documentation/manuals/gnupg/Unattended-GPG-key-generation.html
## https://www.gnupg.org/documentation/manuals/gnupg/Operational-GPG-Commands.html
gpg_tmpdir=$(mktemp -d) && cd $pgp_tmpdir && mkdir -p ./templates && export GNUPGHOME="$gpg_tmpdir"

gpg_root_cowboy_inception_pass=`openssl rand -base64 32`
```
GPG global configuration
```shell
cat > $gpg_tmpdir/gpg.conf << EOF
#SHA512 as digest to sign keys
cert-digest-algo SHA512
#UTF-8 support for compatibility
charset utf-8
cipher-algo AES256
compress-algo ZLIB
#Default preferences for new keys
default-preference-list SHA512 SHA384 SHA256 AES256 AES192 ZLIB BZIP2 ZIP Uncompressed
digest-algo SHA512
disable-cipher-algo 3DES
export-options export-minimal
fixed-list-mode
#Display UID validity
list-options show-uid-validity
verify-options show-uid-validity show-keyserver-urls
#No comments in messages
#no-comments
#No version in output
no-emit-version
#Disable banner
no-greeting
#Disable caching of passphrase for symmetrical ops
no-symkey-cache
#Long key id format
keyid-format 0xlong
#Output ASCII instead of binary
armor
#Enable smartcard
use-agent
#Use AES256, 192, or 128 as cipher
personal-cipher-preferences AES256
#Use SHA512, 384, or 256 as digest
personal-digest-preferences SHA512
#Use ZLIB, BZIP2, ZIP, or no compression
personal-compress-preferences ZLIB BZIP2 ZIP Uncompressed
#Cross-certify subkeys are present and valid
require-cross-certification
#AES256 as cipher for symmetric ops
s2k-cipher-algo AES256
s2k-count 65011712
#SHA512 as digest for symmetric ops
s2k-digest-algo SHA512
s2k-mode 3
weak-digest SHA1
#Display all keys and their fingerprints
with-fingerprint
#Display key origins and updates
with-key-origin

#Disable recipient key ID in messages (breaks Mailvelope) Key ID -> 0x0000000000000000 unable to decrypt
#throw-keyids
#Default key ID to use (helpful with throw-keyids)
#default-key 0xFF00000000000001
#trusted-key 0xFF00000000000001

#Group recipient keys (preferred ID last)
#group keygroup = 0xFF00000000000003 0xFF00000000000002 0xFF00000000000001
#Keyserver URL
#keyserver hkps://keys.openpgp.org
#keyserver hkps://keys.mailvelope.com
#keyserver hkps://keyserver.ubuntu.com:443
#keyserver hkps://pgpkeys.eu
#keyserver hkps://pgp.circl.lu
#keyserver hkp://zkaan2xfbuxia2wpf7ofnkbz6r5zdbbvxbunvp5g2iebopbfc4iqmbad.onion
#Keyserver proxy
#keyserver-options http-proxy=http://127.0.0.1:8118
#keyserver-options http-proxy=socks5-hostname://127.0.0.1:9050
#Enable key retrieval using WKD and DANE
#auto-key-locate wkd,dane,local
#auto-key-retrieve
#Trust delegation mechanism
#trust-model tofu+pgp
#Show expired subkeys
list-options show-unusable-subkeys
#Verbose output
#verbose
EOF
```
Configuration for the GPG_ROOT [S,C] keypair.
```shell
touch $gpg_tmpdir/gnupg/{pub,sec}ring.gpg
cat > $gpg_tmpdir/templates/gpg_root_$inception_fqdn_domain_friendly_name << EOF
# Option allows the creation of keys without any passphrase protection
%no-protection
%no-ask-passphrase

## If no ‘Key-Usage’ is specified and the ‘Key-Type’ is not ‘default’, all allowed usages for that particular algorithm are used
## Ed25519, EDDSA specified Key-Usage not allowed for algo 22 (encrypt)
## To list the supported ECC curves the command gpg --with-colons --list-config curve
Key-Type: default
Key-Curve: Ed25519
Key-Usage: cert,sign

## Subkey generates a secondary key - Only one from this config, we'll do it manually.
## Subkey-Type: default
## Subkey-Curve: Ed25519
## Subkey-Usage: encrypt, sign

## The three parts of a user name. Remember to use UTF-8 encoding here.
## If you don’t give any of them, no user ID is created.
Name-Real: test case
Name-Comment: test comment here
Name-Email: contact@example.com

Expire-Date: 0

## Specifies the preferred keyserver URL for the key.
Keyserver: https://pgp-keyserver.example.com

## Only used with the status lines KEY_CREATED and KEY_NOT_CREATED. string may be up to 100 characters and should not contain spaces.
## It is useful for batch key generation to associate a key parameter block with a status line.
Handle: thisisthehandlefrom gpg_template.txt

%pubring CowboyAI_inception.pub
%secring CowboyAI_inception.sec
# %pubring pubring.kbx
# %secring trustdb.gpg


# Do a commit here, so that we can later print "done" :-)
%commit
%echo done
EOF
```

## 1. Generate  **GPG_ROOT_SC** keypair, public and private keys WITH a password:
This file will be stored OFFLINE on a YubiKey.
Password for it will be written by the user on a piece of paper.
```shell
gpg --quiet --batch --passphrase $gpg_root_cowboy_inception_pass --generate-key $gpg_tmpdir/templates/gpg_root_sc_$inception_fqdn_domain_friendly_name
echo $gpg_root_cowboy_inception_pass > $gpg_tmpdir/templates/gpg_root_sc_$inception_fqdn_domain_friendly_name.pass
```
## 2. Get ROOT key fingerprint
```shell
gpg_root_keyid=`gpg --list-keys --with-colons | awk -F':' '$1=="fpr"{print $10}'`
```
Check the folder structure with:
```shell
tree $gpg_tmpdir
```
List generated keys with:
```shell
gpg --list-keys --with-subkey-fingerprint --keyid-format=long
gpg --list-public-keys
```

## 3. Generate GPG **ROOT [S, E, A]** public and private keys
```shell
gpg --batch --passphrase $gpg_root_cowboy_inception_pass --quick-add-key $gpg_root_keyid ed25519 sign 1y
gpg --batch --passphrase $gpg_root_cowboy_inception_pass --quick-add-key $gpg_root_keyid cv25519 encr 1y
gpg --batch --passphrase $gpg_root_cowboy_inception_pass --quick-add-key $gpg_root_keyid ed25519 auth 1y
```
List generated keys with:
```shell
gpg --list-keys --with-subkey-fingerprint --keyid-format=long
gpg --list-public-keys
gpg -K
```

## 4. Export to file the realm_node's **GPG [S,E,A]** public and private keys
```shell
## Export ALL public keys, including the root key
gpg --armor --export "${gpg_root_keyid}"! > gpg_realm_${inception_fqdn_domain_friendly_name}_key.pub.asc
## Export private subkeys
gpg --armor --export-secret-subkeys --with-subkey-fingerprint > gpg_realm_${inception_fqdn_domain_friendly_name}_key.priv.asc
gpgdump ./gpg_realm_${inception_fqdn_domain_friendly_name}_key.priv.asc

gpg_subkey_auth_keyid=`gpg --list-keys --with-colons | awk -F':' '$1=="fpr"{print $10}'`
```










## X. Create tar archive with the generated files.
```shell
tar czf cowboy_deployment_$inception_fqdn_domain_friendly_name.tar.gz deployment_machine realm_node
tar xzf myfiles.tar.gz - to extract tar
```

## Y. Encrypt the tar archive with pgp CowboyAI public key avoiding the cli popup.
## The encrypted file is created with the same name as the original, but with ".asc" appended to the file name
## This will generate a cowboy_deployment_$inception_fqdn_domain_friendly_name.tar.gz.asc
```shell
gpg --batch --trust-model always --recipient <recipient uid> --pinentry-mode=loopback --passphrase <your passphrase> --encrypt-files *.*
gpg --batch --trust-model always --recipient sparkx --pinentry-mode=loopback --passphrase $gpg_root_cowboy_inception_pass --encrypt-files cowboy_deployment_$inception_fqdn_domain_friendly_name.tar.gz
gpg --batch --trust-model always --recipient sparkx --encrypt-files cowboy_deployment_$inception_fqdn_domain_friendly_name.tar.gz
```

## Z. Transfer the encrypted .asc file on a computer with pgp CowboyAI private keys and decrypt it.
```shell
gpgtar --decrypt cowboy_deployment_$inception_fqdn_domain_friendly_name.tar.gz.asc
```


## Export pgp CowboyAI public keys from the node that has the private keys.
```shell
gpg --armor --export --fingerprint 0x661A327EAD759247 sparkx@twr-z790 > sparkx@twr-z790_encr_public_key.asc
```

## Don't use gpgtar to encrypt, this will open a cli prompt with a interface saying that the key is not trusted requireing manual intervention.
## gnupg: There is no assurance this key belongs to the named user cli interactive
You don't need to expressly declare the secret key in the gpg decrypt command. If the keypair- both Public AND Private keys- are present on the keyring on the host where you're decrypting,
GPG will automagically determine the secret key required for decryption and present a password challenge.
HOWEVER if you wish to try all (non-cached) keys (maybe you're testing a file encrypted with multiple keys),
using the switch --try-all-secrets will cycle through all the secret keys on your keyring trying them in turn. ie:
`gpg -d --try-all-secrets test-gpg.txt.asc`

```shell
To encrypt a file using a recipient’s public key, use:
gpgtar --encrypt --output <out_file_name> -r <recipient> <dir_name>
gpgtar --encrypt --output cowboy_deployment_$inception_fqdn_domain_friendly_name.gpgtar --recipient sparkx deployment_machine realm_node

To decrypt a file use:
gpgtar --decrypt <out_file_name>
gpgtar --decrypt cowboy_deployment_$inception_fqdn_domain_friendly_name.gpgtar
```


## To sign a file or message with your private key to prove authenticity, use:
This will create a signed file. The recipient can verify that the file is genuinely from you by checking your signature.
```shell
   gpg --output signed_file.gpg --sign file_to_sign.txt
```

## Verifying a Signature, If you receive a signed message, you can verify it with:
This will confirm whether the message was signed by the correct person and if it has been tampered with.
```shell
    gpg --verify signed_file.gpg
```

gpg --armor --export "${gpg_root_keyid}"! > gpg_root_key_pub.asc
gpg --armor --export-secret-keys "${gpg_root_keyid}"! > gpg_root_key_priv.asc
gpg --armor --export-secret-subkeys > sub-secret-keys.gpg
pgpdump ./gpg_root_key.priv

gpg_subkey_auth_keyid=`gpg --list-keys --with-colons | awk -F':' '$1=="fpr"{print $10}'`


https://unix.stackexchange.com/questions/401577/gpg-trust-like-an-ca-cert
https://curl.se/docs/caextract.html
https://stackoverflow.com/questions/17935619/what-is-difference-between-cacerts-and-keystore






tree $gpg_tmpdir

gpg --list-keys --keyid-format=long
   gpg: checking the trustdb
   gpg: marginals needed: 3  completes needed: 1  trust model: pgp
   gpg: depth: 0  valid:   1  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 1u
   /tmp/tmp.QciEcaOi0J/pubring.kbx
   -------------------------------
   pub   ed25519/0x6FD427A70493316A 2025-02-03 [SCA]
         Key fingerprint = 9798 B480 34CF 9318 9C58  6E77 6FD4 27A7 0493 316A
   uid                   [ultimate] test case (test comment here) <contact@example.com>
   sub   ed25519/0xA1C49B9E801B14C9 2025-02-03 []

gpg --list-keys --with-subkey-fingerprint --keyid-format=long
gpg --list-secret-keys --with-subkey-fingerprint <filename>
gpg --list-public-keys


gpg --with-colons --import-options show-only --import a4ff2279

To get long format key ID, long key id format (using --show-keys and --with-colons):
  gpg --show-keys --with-colons keyfile.key | awk -F':' '$1=="fpr"{print $10}'


```
usage: gpg [options] --generate-key [parameterfile]
