#!/bin/bash

echo "Performing a clean Maven build"
./mvnw clean package -DskipTests=true

echo "Packing the Service"
cd secured-service
pack build scg-demo-secured-service --env "BP_JAVA_VERSION=8.*"
cd ..

echo "Packing the Eureka Discovery Server"
cd registry
pack build scg-demo-registry --env "BP_JAVA_VERSION=8.*"
cd ..

echo "Packing the Spring Cloud Gateway"
cd security-gateway
pack build scg-demo-security-gateway --env "BP_JAVA_VERSION=8.*"
cd ..
