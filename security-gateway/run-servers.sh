#!/bin/bash
docker run -d -p 8090:8090 --name uaa scg-demo-uaa
docker run -d -p 9000:9000 --name resource scg-demo-secured-service
docker run -d -p 8080:8080 --name gateway scg-demo-security-gateway
