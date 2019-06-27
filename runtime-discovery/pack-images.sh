#!/bin/bash

echo "Performing a clean Maven build"
./mvnw clean package -DskipTests=true

echo "Packing the Service"
cd service
pack build benwilcock/scg-demo-service --env "BP_JAVA_VERSION=8.*"
cd ..

echo "Packing the Eureka Discovery Server"
cd registry
pack build benwilcock/scg-demo-registry --env "BP_JAVA_VERSION=8.*"
cd ..

echo "Packing the Spring Cloud Gateway"
cd gateway
pack build benwilcock/scg-demo-gateway --env "BP_JAVA_VERSION=8.*"
cd ..
