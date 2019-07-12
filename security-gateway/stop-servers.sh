#!/bin/bash
docker stop uaa
docker stop resource
docker stop gateway
docker rm $(docker ps -aq --filter name=uaa)
docker rm $(docker ps -aq --filter name=resource)
docker rm $(docker ps -aq --filter name=gateway)
