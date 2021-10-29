help:
	@echo "Use these to get started:\n\
	  submodules    Update the submodules\n\
	  packages      Install required packages\n\
	  certificates  Regenerate certificates\n\
	  buildcore     Build Arrowhead Core\n\
	  tunedatabase  Increase number of connections\n\
	  run           Run Arrowhead Core services"

all: submodules packages certificates buildcore tunedatabase

submodules:
	@echo "Updating submodules..."
	git submodule update --init .

packages:
	@echo "Downloading required packages..."
	sudo apt-get install default-jdk mariadb-server

certificates:
	@echo "Creating folder for certificates..."
	test -d certificates || mkdir certificates
	@echo "Duplicating master certificates..."
	cp ./core-java-spring/certificates/master* ./ah-certgen/
	@echo "Duplicating cloud truststore..."
	cp ./core-java-spring/certificates/testcloud2/testcloud2* ./certificates/
	@echo "Generating new certificates..."
	PASSWORD=123456 FOLDER="../certificates/" DOMAIN="aitia" CLOUD="testcloud2" bash ./ah-certgen/generate.sh service_registry authorization gateway event_handler datamanager gatekeeper orchestrator choreographer certificate_authority
	@echo "Replacing old certificates..."
	find ./core-java-spring -name \*.p12 | grep main/resources | xargs -n 1 -I'{}' bash -c "basename '{}' && test -f ./certificates/'{}' | xargs -n 1 -I'()' cp ./certificates/'()' '{}'"
	find ./core-java-spring -name \*.pub | grep main/resources | xargs -n 1 -I'{}' bash -c "basename '{}' && test -f ./certificates/'{}' | xargs -n 1 -I'()' cp ./certificates/'()' '{}'"

buildcore:
	@echo "Building Arrowhead Core..."
	cd ./core-java-spring && mvn install -DskipTests

tunedatabase:
	@echo "Tuning the database by increasing the number of connections..."
	@echo "This should remove the 'Too many connections' exceptions."
	sudo sed "s/#\(max_connections .*\)/\1/g" -i /etc/mysql/mariadb.conf.d/50-server.cnf

run:
	@tmux new-session \; \
	rename-window "ServiceRegistry" \; send-keys "cd ./core-java-spring/serviceregistry/target/" Enter \; send-keys "java -jar arrowhead-serviceregistry-4.3.0.jar" Enter \; \
	new-window \; rename-window "Authorization" \; send-keys "cd ./core-java-spring/authorization/target/" Enter \; send-keys "sleep 180s" Enter \; send-keys "java -jar arrowhead-authorization-4.3.0.jar" Enter \; \
	new-window \; rename-window "Gateway" \; send-keys "cd ./core-java-spring/gateway/target/" Enter \; send-keys "sleep 210s" Enter \; send-keys "java -jar arrowhead-gateway-4.3.0.jar" Enter \; \
	new-window \; rename-window "EventHandler" \; send-keys "cd ./core-java-spring/eventhandler/target/" Enter \; send-keys "sleep 240s" Enter \; send-keys "java -jar arrowhead-eventhandler-4.3.0.jar" Enter \; \
	new-window \; rename-window "DataManager" \; send-keys "cd ./core-java-spring/datamanager/target/" Enter \; send-keys "sleep 270s" Enter \; send-keys "java -jar arrowhead-datamanager-4.3.0.jar" Enter \; \
	new-window \; rename-window "Gatekeeper" \; send-keys "cd ./core-java-spring/gatekeeper/target/" Enter \; send-keys "sleep 300s" Enter \; send-keys "java -jar arrowhead-gatekeeper-4.3.0.jar" Enter \; \
	new-window \; rename-window "Orchestrator" \; send-keys "cd ./core-java-spring/orchestrator/target/" Enter \; send-keys "sleep 330s" Enter \; send-keys "java -jar arrowhead-orchestrator-4.3.0.jar" Enter \; \
	new-window \; rename-window "Choreographer" \; send-keys "cd ./core-java-spring/choreographer/target/" Enter \; send-keys "sleep 360s" Enter \; send-keys "java -jar arrowhead-choreographer-4.3.0.jar" Enter \; \
	new-window \; rename-window "CertificateAuthority" \; send-keys "cd ./core-java-spring/certificate-authority/target/" Enter \; send-keys "sleep 390s" Enter \; send-keys "java -jar arrowhead-certificate-authority-4.3.0.jar" Enter \;
