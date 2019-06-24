#!/bin/bash

echo "Performing a clean Maven build"
./mvnw clean package -DskipTests=true

echo "Packing the Service"
cd service
pack build benwilcock/scg-demo-service
cd ..

echo "Packing the Eureka Discovery Server"
cd registry
pack build benwilcock/scg-demo-registry
cd ..

echo "Packing the Spring Cloud Gateway"
cd gateway
pack build benwilcock/scg-demo-gateway
cd ..
