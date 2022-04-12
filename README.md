# Arrowhead Framework Core Services for Raspberry Pi
This repository should contain a straightforward manual on how to
get Arrowhead Core working on Raspberry Pi.

- [Quick start](#quick-start)
- [Notes](#notes-for-the-project)
  - [Packages](#packages)
  - [Submodules](#submodules)
  - [Certificates](#certificates)
  - [Core building](#core-building)
  - [Database filling](#database-filling)
  - [Database tuning](#database-tuning)
  - [Run the core](#run-the-core)
- [Debian installers](#debian-installers)
  - [Installing Core systems](#installing-the-core-systems)
  - [Maintaining certificates](#maintaining-certificates)
    - [System certificate](#generate-certificate-for-a-system)
    - [CA certificate](#generate-certificate-authority-ca-file)
    - [Sysop certificate](#generate-system-operator-sysop-certificate)
  - [Uninstalling Core systems](#uninstalling-the-core-systems)
  - [Purging database](#purging-the-database)


## Quick start

To start right up, clone the repository and run:
```sh
make all
make run-minimal
```

This should (after a lot of minutes) prepare the environment and run the main three Arrowhead Core systems. The default configuration is set to `*.testcloud2.aitia.arrowhead.eu` cloud. Therefore, all services and systems using certificates from `testcloud2` should be able to connect right away.


## Notes for the project

In this section, we explain the steps performed by the `make all` target.

### Packages

```sh
sudo apt-get install git default-jdk mariadb-server tmux
```

Following packages are required for building and running the project:

- `git` for obtaining the repositories.
- `default-jdk` which installs the supported version of Java Development Kit.
- `mariadb-server` is a database server supported on the Raspberry Pi.
- `tmux` which is used only to hold all of the core parts in one window.

### Submodules

```sh
git submodule update --init .
```

The project contains two submodules:

- `core-java-spring` is the repository holding the Arrowhead Core systems. We clone version `4.3.0`, i.e., the code frozen at that release.
- `ah-certgen` is our script for generating the certificates for services/systems.

### Certificates

As said earlier, we use the `testcloud2` from the Arrowhead repository. Unfortunately, some of the certificates contained in the repository are generated badly. Therefore, we re-generate all of the certificates just to be sure.

Nevertheless, as the cloud truststore certificate is still the same, it should be compatible with any other certificates generated for `testcloud2`.

To prepare for the certificate generation, we first duplicate the `master` and `testcloud2` certificates:
```sh
mkdir certificates
cp ./core-java-spring/certificates/master* ./ah-certgen/
cp ./core-java-spring/certificates/testcloud2/testcloud2* ./certificates/
```

The certificates are generated using:
```sh
PASSWORD=123456 FOLDER="../certificates/" DOMAIN="aitia" CLOUD="testcloud2" bash ./ah-certgen/generate.sh service_registry authorization gateway event_handler datamanager gatekeeper orchestrator choreographer certificate_authority onboarding_controller device_registry system_registry translator
```

And then we copy them to their appropriate location (we overwrite existing files):
```sh
find ./core-java-spring -name \*.p12 | grep main/resources | xargs -n 1 -I'{}' bash -c "basename '{}' | xargs -n 1 -I'()' bash -c \"test -f ./certificates/'()' && cp ./certificates/'()' '{}'\""
find ./core-java-spring -name \*.pub | grep main/resources | xargs -n 1 -I'{}' bash -c "basename '{}' | xargs -n 1 -I'()' bash -c \"test -f ./certificates/'()' && cp ./certificates/'()' '{}'\""
```

### Core building

The core services are build using:
```sh
cd ./core-java-spring && mvn install -DskipTests
```

### Database filling

We have to create tables for Arrowhead Framework. Also, we need to give access to all the core systems. The passwords in this file should match the passwords in the configuration of each core system.
```sh
sudo mysql -u root < ./scripts/create_empty_arrowhead_db.sql
```


### Database tuning

_Note: This is maybe not necessary after delaying the startup times._

In the default state, the `max_connections` parameter of the database is not set (and left on default value). In order to get rid of the errors, we set it:
```sh
sudo sed "s/#\(max_connections .*\)/\1/g" -i /etc/mysql/mariadb.conf.d/50-server.cnf
```

### Run the core

We run the core by calling:
```sh
make run
```

Which opens up a tmux session with all the core services. They start up in a specific order, forced by calling `sleep`. This solves _MAX CONNECTIONS_ exceptions.

We can also run:
```sh
make run-minimal
```

Which launches only _Service Registry_, _Authorization_ and _Choreographer_.


## Debian installers

Along with the Arrowhead Core systems, `.deb` files are created inside `./core-java-spring/target`. If you opt in using Debian installers right from the start, you can skip some steps of the Makefile:
```sh
make packages modulepatch buildcore
```

**Warning!** By default, both installations are not compatible (they overwrite the MySQL passwords, etc.). If you want to be able to use both (direct java and debian) you need to set all passwords properly.

### Installing the Core systems

At first, we install the core package:
```sh
sudo dpkg -i arrowhead-core-common*
```

During the installation it requires some input from user. To be compatible with already created certificates, use `Authorized` installation method and specify the path to the created cloud truststore.

Afterwards, you can install the rest of the core systems.
```sh
sudo dpkg -i arrowhead-serviceregistry* arrowhead-authorization* arrowhead-orchestrator*
```

Or simply:
```sh
sudo dpkg -i arrowhead*
```

### Maintaining certificates

Debian installation also brings several scripts that come up from the `core-common` package. They are used for maintaining and generating certificates:
```sh
arrowhead
ah_gen_system_cert.sh
ah_gen_relay_cert.sh
```

#### Generate certificate for a system

To generate a certificate for new system, we call:
```sh
/usr/bin/ah_gen_system_cert.sh SYSTEM_NAME PASSWORD [SYSTEM_HOST] [SYSTEM_IP] [ADDITIONAL_HOST_OR_IP]
```

Note that this scripts (as for the 4.3.0) needs to be called with sudo, e.g.,
```sh
sudo ah_gen_system_cert.sh newsystem 123456 localhost 127.0.0.1 ip:192.168.1.2
```

The certificate is generated to folder `SYSTEM_NAME` as `SYSTEM_NAME.p12` along with `truststore.p12`. Unfortunately, both certificates are owned by `root`, so this is also required:
```sh
sudo chown pi SYSTEM_NAME/*
```

Public key of the system is shown in the terminal. All you need is to put it into a file `SYSTEM_NAME.pub`, like:
```ini
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyxw7OMHft33H69BgLiXm
iNI1nTo2mdRIoDru0q5BLg0RQOKZD4woSeDd7LYNV1p66YAZWEan6+TUi5EGC8kX
naLNL52nwal3p1/2TAY+p+95OtI9iUVfI5pzfyxEVxc1nqV40F70XNKoFduPWLFw
YaSEg3cXaBiUSiCgTsMQzoEZQ9o7ueTxnUrBgx0UlsuQQOdKagTJMfuTF1/2IKMt
lVgnHZ5/yVTRtsaUlage+TG/9tto2pxd3TWj5rTGGLDbkKSg4BP9YOHcTTnJZNbG
1bnRwgDrpEPI4TaK6GNOQicRTiKLjv79/EyGFJzgTkcPJ0lW4pc9Al/2Dx15z9L6
owIDAQAB
-----END PUBLIC KEY-----
```

The whole procedure can be also done using:
```sh
generate_certificate() {
    SYSTEM_NAME="$1"
    sudo ah_gen_system_cert.sh "$@"
    sudo chown -R "$USER" "$SYSTEM_NAME"
    keytool -list -keystore "$SYSTEM_NAME/$SYSTEM_NAME.p12" -storepass "$2" -rfc | openssl x509 -inform pem -pubkey -noout > "$SYSTEM_NAME/$SYSTEM_NAME.pub"
}

generate_certificate testingsystem 123456 localhost 127.0.0.1
```

#### Generate Certificate Authority (.ca) file

In order to verify certificates, you may need to have a `.ca` file. This is generated once per cloud and can be publicly available (as it does not contain any secret information).

To generate certificate authority file, use:
```sh
CLOUD_NAME=$(cat /etc/arrowhead/arrowhead.cfg | grep cloudname= | cut -d= -f2-)
CLOUD_PASS=$(cat /etc/arrowhead/arrowhead.cfg | grep cert_password= | cut -d= -f2-)
sudo cat /etc/arrowhead/master.crt > "$CLOUD_NAME".ca
sudo openssl pkcs12 -in /etc/arrowhead/clouds/"$CLOUD_NAME".p12 -passin "pass:$CLOUD_PASS" -clcerts -nokeys | openssl x509 >> "$CLOUD_NAME".ca
```

#### Generate System Operator (sysop) certificate

Certificate called `sysop` is used to access web interfaces of the core system. There is nothing special about it (maybe with an exception that it probably cannot contain CA inside [jara001/ah-certgen@309bf4e0](https://github.com/jara001/ah-certgen/commit/309bf4e07c21e59ce90f028bbd83ba2b89dd6c82)).

However, for some unknown reason, OpenJDK's keytool generates certificates with _improperly formated DER-encoded message_. Therefore, we use openssl-only method:
```sh
SYSTEM_NAME="sysop"
SYSTEM_PASS="PASSWORD"

TMP_DIR=$(mktemp -d)
CLOUD_NAME=$(cat /etc/arrowhead/arrowhead.cfg | grep cloudname= | cut -d= -f2-)
CLOUD_PASS=$(cat /etc/arrowhead/arrowhead.cfg | grep cert_password= | cut -d= -f2-)
OPERATOR=$(cat /etc/arrowhead/arrowhead.cfg | grep operator= | cut -d= -f2-)
pushd "$TMP_DIR"

# Create certificate request
sudo openssl req -newkey rsa:2048 -keyout "$SYSTEM_NAME".key.pem -out "$SYSTEM_NAME".req.pem -nodes -subj /CN="$SYSTEM_NAME"."$CLOUD_NAME"."$OPERATOR".arrowhead.eu

# Split cloud .p12 into .pem(s)
sudo openssl pkcs12 -in /etc/arrowhead/clouds/"$CLOUD_NAME".p12 -passin "pass:$CLOUD_PASS" -out "$CLOUD_NAME".crt.pem -clcerts -nokeys
sudo openssl pkcs12 -in /etc/arrowhead/clouds/"$CLOUD_NAME".p12 -passin "pass:$CLOUD_PASS" -out "$CLOUD_NAME".key.pem -nocerts -nodes

# Generate pem for system
sudo openssl x509 -req -days 365 -in "$SYSTEM_NAME".req.pem -out "$SYSTEM_NAME".pem -CA "$CLOUD_NAME".crt.pem -CAkey "$CLOUD_NAME".key.pem -CAcreateserial

# Create system .p12 file
sudo openssl pkcs12 -export -in "$SYSTEM_NAME".pem -inkey "$SYSTEM_NAME".key.pem -out "$SYSTEM_NAME".p12 -passout "pass:$SYSTEM_PASS" -name "$SYSTEM_NAME"

# Move back the certicate and delete the folder (softly)
sudo rm "$CLOUD_NAME".crt.pem "$CLOUD_NAME".crt.srl "$CLOUD_NAME".key.pem "$SYSTEM_NAME".key.pem "$SYSTEM_NAME".pem "$SYSTEM_NAME".req.pem
popd
sudo mv "$TMP_DIR"/"$SYSTEM_NAME".p12 .
sudo chown "$USER" "$SYSTEM_NAME".p12
rmdir "$TMP_DIR"
```


### Uninstalling the Core systems

To remove the package (and eventually all the systems) you have to:

1. Remove the packages: `sudo apt remove --purge arr\*`

2. Remove the arrowhead configuration folder: `sudo rm -rf /etc/arrowhead`

3. Remove the configuration of packages: `sudo rm -rf /usr/share/arrowhead`

### Purging the database

To remove any traces from the database (and restore it to the default state), you have to:

1. Stop the database: `sudo service mysql stop`

2. Remove the database from the system: `sudo rm -rf /var/lib/mysql`

3. Recreate the database: `sudo mysql_install_db`

4. Start the service: `sudo service mysql start`

5. Install the database: `sudo mysql_secure_installation`
