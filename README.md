# Arrowhead Framework Core Services for Raspberry Pi
This repository should contain a straightforward manual on how to
get Arrowhead Core working on Raspberry Pi.


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
find ./core-java-spring -name \*.p12 | grep main/resources | xargs -n 1 -I'{}' bash -c "basename '{}' && test -f ./certificates/'{}' | xargs -n 1 -I'()' cp ./certificates/'()' '{}'"
find ./core-java-spring -name \*.pub | grep main/resources | xargs -n 1 -I'{}' bash -c "basename '{}' && test -f ./certificates/'{}' | xargs -n 1 -I'()' cp ./certificates/'()' '{}'"
```

### Core building

The core services are build using:
```sh
cd ./core-java-spring && mvn install -DskipTests
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