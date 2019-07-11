#!/bin/bash

echo "Performing a clean Maven build"
./mvnw clean package -DskipTests=true

echo "Setting the default builder for pack"
pack set-default-builder cloudfoundry/cnb:bionic

echo "Packing the Service"
cd service
pack build scg-demo-service --env "BP_JAVA_VERSION=8.*"
cd ..

echo "Packing the Eureka Discovery Server"
cd registry
pack build scg-demo-registry --env "BP_JAVA_VERSION=8.*"
cd ..

echo "Packing the Spring Cloud Gateway"
cd gateway
pack build scg-demo-gateway --env "BP_JAVA_VERSION=8.*"
cd ..
