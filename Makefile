help:
	@echo "Use these to get started:\n\
	  submodules\tUpdate the submodules\n\
	  packages\tInstall required packages\n\
	  buildcore\tBuild Arrowhead Core\n\
	  run\tRun Arrowhead Core services"

all: submodules packages buildcore

submodules:
	@echo "Updating submodules..."
	git submodule update --init .

packages:
	@echo "Downloading required packages..."
	sudo apt-get install default-jdk mariadb-server

buildcore:
	@echo "Building Arrowhead Core..."
	cd ./core-java-spring && mvn install -DskipTests

run:
	@tmux new-session \; \
	rename-window "ServiceRegistry" \; send-keys "cd ./core-java-spring/serviceregistry/target/" Enter \; send-keys "java -jar arrowhead-serviceregistry-4.3.0.jar" Enter \; \
	new-window \; rename-window "Authorization" \; send-keys "cd ./core-java-spring/authorization/target/" Enter \; send-keys "sleep 10s" Enter \; send-keys "java -jar arrowhead-authorization-4.3.0.jar" Enter \; \
	new-window \; rename-window "Gateway" \; send-keys "cd ./core-java-spring/gateway/target/" Enter \; send-keys "sleep 10s" Enter \; send-keys "java -jar arrowhead-gateway-4.3.0.jar" Enter \; \
	new-window \; rename-window "EventHandler" \; send-keys "cd ./core-java-spring/eventhandler/target/" Enter \; send-keys "sleep 10s" Enter \; send-keys "java -jar arrowhead-eventhandler-4.3.0.jar" Enter \; \
	new-window \; rename-window "DataManager" \; send-keys "cd ./core-java-spring/datamanager/target/" Enter \; send-keys "sleep 10s" Enter \; send-keys "java -jar arrowhead-datamanager-4.3.0.jar" Enter \; \
	new-window \; rename-window "Gatekeeper" \; send-keys "cd ./core-java-spring/gatekeeper/target/" Enter \; send-keys "sleep 10s" Enter \; send-keys "java -jar arrowhead-gatekeeper-4.3.0.jar" Enter \; \
	new-window \; rename-window "Orchestrator" \; send-keys "cd ./core-java-spring/orchestrator/target/" Enter \; send-keys "sleep 10s" Enter \; send-keys "java -jar arrowhead-orchestrator-4.3.0.jar" Enter \; \
	new-window \; rename-window "Choreographer" \; send-keys "cd ./core-java-spring/choreographer/target/" Enter \; send-keys "sleep 10s" Enter \; send-keys "java -jar arrowhead-choreographer-4.3.0.jar" Enter \; \
	new-window \; rename-window "CertificateAuthority" \; send-keys "cd ./core-java-spring/certificate-authority/target/" Enter \; send-keys "sleep 10s" Enter \; send-keys "java -jar arrowhead-certificate-authority-4.3.0.jar" Enter \;
