
## Good security tools site:
https://asecuritysite.com/

https://www.youtube.com/watch?v=UBa2qpd5cq0
Aggregates (dark-yellow): A group of domain objects, with a root entity enforcing consistency and transactional boundries.
Actors (light-yellow): Person initiating the event.
Events (orange): Significant **business event** or state changes within a domain. (**In past tense**)
Commands (blue): Intent to perform an action or to cause a change in the domain. (**In present tense**)
Policys (teal): Business rules, constraints, or validation criteria within the domain.
Hotspots (black-magenta): Services that might fail durin command.
ReadModels (dark-green): Data sources that are needed.
ExternalSystem (pink): Domain managed by another team that you interact with but is not part of your core domain.
UI () -
Oportunity (light-green): Questions, Risks, Assumptions.

```shell
Aggregates:
Actors:
Events:
Commands:
Policys:
Hotspots:
ReadModels:
ExternalSystems:
UI:
Oportunity:
```

It's best practice to generate and use two separate CAs — one for signing host certificates, one for signing user certificates.
This is because you don't want the same processes that add hosts to your fleet to also be able to add users (and vice versa).
Using separate CAs also means that in the event of a private key being compromised, you only need to reissue the certificates for either your hosts or your users, not both at once.
https://goteleport.com/blog/how-to-configure-ssh-certificate-based-authentication/

## 0. Set shell variables and create folder structure:
Aggregates:
Actors:
Events:
Commands:
Policys:
Hotspots:
ReadModels:
ExternalSystems:
Thoughts:
```shell
## 0. Create temporary folders structure and configuration files that will not persist after reboot
ssh_tmpdir=$(mktemp -d) && cd $ssh_tmpdir && mkdir -p ./deployment_machine/ssh ./realm_node/ssh

## Define a friendly name for the deployment so that it will reflect the iteration also.
## This is a way to identify the generated keys so that no confusion can occur between iterations.
## Keys will be named, ssh_xxx_${inception_fqdn_domain_friendly_name}.pub Eg: ssh_hosts_ca_cowboy_local_1.pub
## User defined
inception_fqdn_domain_friendly_name="cowboyai_local_1"

## Define your FQDN domain name where all hosts will live, eg: cowboy.ai
## User defined
inception_fqdn_domain="cowboyai.local"

## FQDN organization email - User defined
org_email_adress="contact@${inception_fqdn_domain}"

## Git repo to store the secrets.
gitrepo_fqdn="git-cowboy.${inception_fqdn_domain}"
gitrepo_secrets_address="git@git-cowboy:inception/secrets.git"

## Generate random strong passwords for the CAs, SSH keys, PGP and TLS CAs.
ssh_hosts_ca_cowboy_inception_pass=`openssl rand -base64 32`
ssh_users_ca_cowboy_inception_pass=`openssl rand -base64 32`
realm_node_cowboy_ssh_key_pass=`openssl rand -base64 60`
```

## 1. Generate SSH HOST_CA keypair WITH a password using the [ssh-keygen](https://www.man7.org/linux/man-pages/man1/ssh-keygen.1.html) command:
The `ssh_hosts_ca_$inception_fqdn_domain_friendly_name` file is the host CA's private key and should be protected.
Make sure that as few people have access to it as possible.
Ideally, it should live on a machine which doesn't allow direct access to it, and all certificates should be issued by an automated process.
This file will be transfered to /etc/ssh/ on the realm_node.
```shell
-t key type
-C key comment
-a rounds, default is 16.
-b flag will be ignored for ECDSA-SK, Ed25519 and Ed25519-SK keys that have a fixed length.

ssh-keygen -t ed25519 -a 256 -N $ssh_hosts_ca_cowboy_inception_pass -C "ssh-hosts-ca@inception.${inception_fqdn_domain_friendly_name}" -f ./ssh_hosts_ca_$inception_fqdn_domain_friendly_name
```
Save ./ssh_hosts_ca_$inception_fqdn_domain_friendly_name password
```shell
echo $ssh_hosts_ca_cowboy_inception_pass > ./ssh_hosts_ca_$inception_fqdn_domain_friendly_name.pass
```


## 2. Generate SSH USERS_CA keypair WITH a password using the [ssh-keygen](https://www.man7.org/linux/man-pages/man1/ssh-keygen.1.html) command:
The `ssh_users_ca_$inception_fqdn_domain_friendly_name` file is the user CA's private key and should also be protected in the same way as the host CA's private key.
This file will be transfered to /etc/ssh/ on the realm_node.
```shell
-t key type
-C key comment
-a rounds, default is 16.
-b flag will be ignored for ECDSA-SK, Ed25519 and Ed25519-SK keys that have a fixed length.

ssh-keygen -t ed25519 -a 256 -N $ssh_users_ca_cowboy_inception_pass -C "ssh-users-ca@inception.${inception_fqdn_domain_friendly_name}" -f ./ssh_users_ca_$inception_fqdn_domain_friendly_name
```

Save ./ssh_hosts_ca_$inception_fqdn_domain_friendly_name password
```shell
echo $ssh_users_ca_cowboy_inception_pass > ./ssh_hosts_ca_$inception_fqdn_domain_friendly_name.pass
```


## 3. Issuing ssh_host keys and certificate (to authenticate hosts for the users)
a. Generate the main ssh_host keypair **WITHOUT a password**.
Thse files will be transfered to /etc/ssh/ on the realm_node and will replace the auto generated ones.
```shell
ssh-keygen -t ed25519 -a 256 -N '' -C "realm@${inception_fqdn_domain_friendly_name}" -f ./ssh_host_ed25519_key
```
b. Sign the above key with the ssh_hosts_ca_$inception_fqdn_domain_friendly_name CA private key and generate a SSH host public certificate.
```shell
ssh-keygen -P $ssh_hosts_ca_cowboy_inception_pass -s ./ssh_hosts_ca_$inception_fqdn_domain_friendly_name -I realm,realm-cowboy,realm.$inception_fqdn_domain -h -n realm.$inception_fqdn_domain -V +52w ssh_host_ed25519_key.pub

Signed host key ssh_host_ed25519_key-cert.pub: id "realm.cowboy.local" serial 0 for realm.cowboy.local valid from 2025-01-31T12:53:00 to 2026-01-30T12:54:14
```
The newly generated `ssh_host_ed25519_key-cert.pub` contains the signed host certificate.

Here's an explanation of the flags used:
    -N new_passphrase: Provides the new passphrase.
    -P passphrase: Provides the (old) passphrase.
    -s host_ca: specifies the filename of the CA private key that should be used for signing.
    -I host.example.com: the certificate's identity — an alphanumeric string that will identify the server. I recommend using the server's hostname. This value can also be used to revoke a certificate in future if needed.
    -h: specifies that this certificate will be a host certificate rather than a user certificate.
    -n host.example.com: specifies a comma-separated list of principals that the certificate will be valid for authenticating — for host certificates, this is the hostname used to connect to the server. If you have DNS set up, you should use the server's FQDN (for example host.example.com) here. If not, use the hostname that you will be using in an ~/.ssh/config file to connect to the server.
    -V +52w: specifies the validity period of the certificate, in this case 52 weeks (one year). Certificates are valid forever by default — expiry periods for host certificates are highly recommended to encourage the adoption of a process for rotating and replacing certificates when needed.

If you need to see the options that a given certificate was signed with, you can use ssh-keygen -L
```shell
ssh-keygen -L -f ./ssh_host_ed25519_key-cert.pub
```

## 4. Generate system service user's (cowboy) credentials and configurations needed for ssh connection to :
Generate system service user's (cowboy) SSH keypair with a strong passphrase
```shell
ssh-keygen -t ed25519 -a 256 -N $realm_node_cowboy_ssh_key_pass -C "cowboy@inception.$inception_fqdn_domain_friendly_name" -f ./cowboy_deployment_$inception_fqdn_domain_friendly_name
```
Generate system service user's (cowboy) SSH keypair password file
```shell
echo $realm_node_cowboy_ssh_key_pass > ./cowboy_deployment_$inception_fqdn_domain_friendly_name.pass
```
On deployment_machine, for your local ssh client to make use of this (and automatically trust the host based on the certificate's identity), you will need to add the CA's public key to your user's known_hosts file.
Content of `setup_deployment_paste_to_locals_known_hosts` will have to be appended to ~/.ssh/known_hosts of the user on the deployment_machine, eg: `cat ./setup_deployment_paste_to_locals_known_hosts >> ~/.ssh/known_hosts`
```shell
hosts_ca=`cat ./ssh_hosts_ca_$inception_fqdn_domain_friendly_name.pub` && echo "@cert-authority realm.${inception_fqdn_domain} ${hosts_ca}" > ./deployment_machine/ssh/setup_deployment_paste_to_known_hosts
```
cowboy_deployment_public key has to also be added to cowboy user's users.users.cowboy.openssh.authorizedKeys.keyFiles on the realm_node.
```shell
cat ./cowboy_deployment_$inception_fqdn_domain_friendly_name.pub > ./realm_node/ssh/ssh_cowboy_authorized_keys
```
On deployment_machine you can check that the certificate is being presented correctly with:
```shell
ssh -vv realm.cowboy.local 2>&1 | grep "Server host certificate"
```
Issuing system service user's (cowboy) certificates (to authenticate users to the host)
This is done signing user's ssh public key with the ssh_users_ca private key.
```shell
ssh-keygen -P $ssh_users_ca_cowboy_inception_pass -s ssh_users_ca_$inception_fqdn_domain_friendly_name -I cowboy@inception.$inception_fqdn_domain_friendly_name -n cowboy -V +25w ./cowboy_deployment_$inception_fqdn_domain_friendly_name.pub

Signed user key ./cowboy_deployment_cowboy_local_1-cert.pub: id "cowboy@cowboy_local_1" serial 0 for cowboy valid from 2025-01-31T15:54:00 to 2025-02-14T15:55:09
```
Here's an explanation of the flags used:
    -s ssh_users_ca_$inception_fqdn_domain_friendly_name: specifies the CA private key that should be used for signing
    -I cowboy@$inception_fqdn_domain_friendly_name: the certificate's identity, an alphanumeric string that will be visible in SSH logs when the user certificate is presented. I recommend using the email address or internal username of the user that the certificate is for — something which will allow you to uniquely identify a user. This value can also be used to revoke a certificate in future if needed.
    -n cowboy: specifies a comma-separated list of principals that the certificate will be valid for authenticating, i.e. the *nix users which this certificate should be allowed to log in as. In our example, we're giving this certificate access to both ec2-user and honda users.
    -V +1d: specifies the validity period of the certificate; in this case +1d means 1 day. Certificates are valid forever by default, so using an expiry period is a good way to limit access appropriately and ensure that certificates can't be used for access perpetually.

The resulting `cowboy_deployment_$inception_fqdn_domain_friendly_name-cert.pub` has to be added to `~/.ssh/` together with the user's keys.

If you need to see the options that a given certificate was signed with, you can use ssh-keygen -L
```shell
ssh-keygen -L -f ~/.ssh/cowboy_deployment_$inception_fqdn_domain_friendly_name-cert.pub
```

## 5. Generate /etc/ssh/ssh_config for deployment_machine using programs.ssh.extraConfig = '' HERE '';
Contents of this file will end up in deployment_machine's /etc/ssh/ssh_config
```shell
echo "
## Use programs.ssh.extraConfig = '' CONTENT HERE ''; to add it.
##
## For this to work you need to have all necessary files already placed in ~/.ssh/ on the deployment_machine
## cowboy_deployment_${inception_fqdn_domain_friendly_name},
## cowboy_deployment_${inception_fqdn_domain_friendly_name}.pub,
## cowboy_deployment_${inception_fqdn_domain_friendly_name}.pass,
## cowboy_deployment_${inception_fqdn_domain_friendly_name}-cert.pub
## setup_deployment_paste_to_known_hosts content added to ~/.ssh/known_hosts
## eg:
##    cp ./cowboy_deployment_${inception_fqdn_domain_friendly_name}* ~/.ssh/
##    chmod 600 ~/.ssh/cowboy_deployment_${inception_fqdn_domain_friendly_name}*
##    cat ./setup_deployment_paste_to_known_hosts >> ~/.ssh/known_hosts
##
## Ssh keys are also used by git to determine the user.
## git clone git@git-cowboy:<YOUR_ORG>/<REPO>.git
## Test connection with: ssh git@git-cowboy

Host git-cowboy-${inception_fqdn_domain_friendly_name}
  ## In case you don't have DNS record for the host replace below with the HOST_IP
  Hostname git.${inception_fqdn_domain}
  Port 2222
  IdentityFile ~/.ssh/cowboy_deployment_${inception_fqdn_domain_friendly_name}
  ForwardAgent yes
  IdentitiesOnly yes
  AddKeysToAgent yes

Host realm-cowboy-${inception_fqdn_domain_friendly_name}
  ## In case you don't have DNS record for the host replace below with the HOST_IP
  Hostname realm.${inception_fqdn_domain}
  Port 22
  IdentityFile ~/.ssh/cowboy_deployment_${inception_fqdn_domain_friendly_name}
  ForwardAgent yes
  IdentitiesOnly yes
  AddKeysToAgent yes

" > ./deployment_machine/ssh/setup_deployment_machine_ssh_config
```

## 6. Generate /etc/ssh/principals for realm_node
Contents of this file will end up in realm_node's /etc/ssh/principals
```shell
echo "
realm
realm-cowboy
realm.${inception_fqdn_domain}

" > ./realm_node/ssh/ssh_cowboy_principals
```

<!-- ## 7. Generate /etc/ssh/moduli file - https://www.linode.com/docs/guides/advanced-ssh-server-security/
[MODULI_GENERATION](https://www.man7.org/linux/man-pages/man1/ssh-keygen.1.html#MODULI_GENERATION)
```shell
## This takes a LOT of time !!!
ssh-keygen -M generate bits=2048 ./moduli-2048.candidates
ssh-keygen -M screen -f ./moduli-2048.candidates ./realm_node/ssh/cowboy_generated_moduli

## Alternate version:
cat /etc/ssh/moduli > ./realm_node/ssh/cowboy_generated_moduli

``` -->

## 7. Distribute files into they's folders and create the archive.
```shell
## Move cowboy ssh deployment files - needed on the deployment_machine
mv cowboy_deployment_* ./deployment_machine/ssh/

## Move host ssh files - needed on the realm_node
mv ssh_host_ed25519_key* ./realm_node/ssh/
mv ssh_hosts_ca_* ./realm_node/ssh/
mv ssh_users_ca_* ./realm_node/ssh/

## Archive the folders using the CowboyAI gpg public encryption key, untar with tar xzf archive name.
tar czf cowboy_deployment_$inception_fqdn_domain_friendly_name.tar.gz deployment_machine realm_node
##
```


















## Generate a new SSH keypair with a strong passphrase
```shell
ssh-keygen -t ed25519 -a 256 -C "ryan@idols-ai" -f ~/.ssh/shoukei
```

## Add the ssh key to the ssh-agent, so that nixos-rebuild can use it to pull my private secrets repo.
```shell
ssh-add ~/.ssh/key_name
```

[Ed25519 Online Tool - Sign, Verify, and Generate](https://cyphr.me/ed25519_tool/ed.html)
https://github.com/Cyphrme/Ed25519Tool


## Generate a PEM key pair
```shell
ssh-keygen -t ed25519 -m PEM -C your_email@example.com
```
## Convert keys from SSH2 -> OPENSSH to use them in authorised keys with:
```shell
ssh-keygen -i -f /etc/agenix/ssh/pub/ops-id-ed25519.pub
```
## Change/Add Passphrase for SSH Private Key
```shell
ssh-keygen -p -f private_key
```

## Print locally used keys fingerprints (keys fingerprints for client computer)
```shell
ssh-keygen -l -f ~/.ssh/known_hosts
```
## Display and store the public key for this specific OpenSSH private key.
```shell
ssh-keygen -y -f private_key | tee public_key.pub
```
## Display OpenSSH key fingerprint.
Doing this on eyther keys should get you the same result.
```shell
ssh-keygen -l -f private_key
ssh-keygen -l -f public_key.pub

256 SHA256:a1wDTTtlUo3Xt+SlN5WSXvusPBNdad1jSjyVRZVsCUE user@machine (ED25519)
```
## Compare OpenSSH key fingerprints.
```shell
$ diff --brief --report-identical-files \
       --label private\ key <(ssh-keygen -l -f private_key) \
       --label public\ key  <(ssh-keygen -l -f public_key.pub)

Files private key and public key are identical
```
