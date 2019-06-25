# Hiding Services & Runtime Discovery 

It's rare that a company wants every service and every API to be publicly available. Most companies would prefer to keep all their services secret by default only exposing them publicly if absolutely necessary. [Spring Cloud Gateway][14] can help in this endeavour by allowing us to control access to these 'secret' services using simple Java instructions or configuration files in yaml format.

It's also true that networks of services have a habit of changing over time, often without much warning. It helps, therefore, if the applications on your network can find each other dynamically at runtime, no matter what their current IP address might be. [Spring Cloud Netflix Eureka Server][13] provides just such a feature, and prevents the need to constantly re-configure your services as things change. It also allows you to use human friendly names to describe the location of your applications rather than IP addresses, and handles load balancing duties if there are multiple instances.

In this demo, we'll look at all of these features and use them together in one sample.

## Things You'll Need

* [Docker Desktop][1] - Docker will provide our "pseudo production environment". We'll use Docker to hide running services making them unreachable using regular direct requests.

* [Cloud Native Buildpacks][2] - We'll use the Cloud Native Buildpacks `pack` command to build Docker images of our applications using open-source operating systems and an OpenJDK distribution.

* [The Source Code][3] - You don't have to code anything, simply `git clone` (or download and `unzip`) [this project's source code repository][3] from GitHub and look in the `runtime-discovery` folder.

* Your favorite web browser.
  
## Quickstart Guide

1. First, get all the "things you'll need" from the list above and install them.

2. Next, `cd` to the project folder and then run the `./pack-images.sh` script – this will build the source code and create Docker images for all the services in this demo and place them in your local Docker image cache.

```bash
./pack-images.sh
```

1. Finally, at the command line, run `docker-compose up` – this will bring up the test environment in the background (or you can add `-d` if you want to run in the background and not see any server logs).

```bash
docker-compose up
```

After a few minutes, Docker should have used the images you built and the configuration provided in the `docker-compose.yml` to start up the demo environment for you.

> Waiting a couple of extra minutes is advised, just to make sure that everything we started has had a chance to communicate and settle down.

## Let's Test It...

#### First, Check that the Greeting Service is Hidden:

The Greeting Service operates on port `8762` inside the Docker network. Let's try to call it from your favorite browser using [http://localhost:8762/greeting](http://localhost:8762/greeting). You should be told that "the site can't be reached" by your browser. This is because the Greeting Service is hidden inside the Docker network (as if it were behind a company firewall for example). It should not be possible for us to talk to the greeting service directly in this way.

#### Next, Access the Greeting Service via the Gateway:

Now, Navigate your browser to [http://localhost/service/greeting][11]. You should get a perfectly valid response with content similar to the "Hello, World" JSON shown below.

```json
{ "id": 1, "content": "Hello, World!"}
```

> Note: We're using the default http port for this request – so the port number has been omitted.

When you issued this new http request from your browser, it was sent to, and handled by, the Gateway. The Gateway service _is_ publicly accessible (it is mapped to port `80`, the default for http). Your request was forwarded by the Gateway to the Greeting Service on your behalf, and the response was then routed back to you by the Gateway.

#### Now, let's take a look at the Registry of Services:

The microservices on the Docker network are each registering themselves with the Registry server just after boot (this may take a couple of minutes, so be patient). This Registry server acts an an address book. If the services move, or if new instances are created, they are added to the register.

To view the current registry, point your browser at [http://localhost/registry][10] and you should see a screen similar to the one below.

![Screenshot from the Registry console][12]

#### Finally, lets shut things down

When you're done, use `docker-compose down` to shutdown the servers (or `ctrl-C` if you ran in the foreground).

## How It Works

In this demo we have three servers. The three servers are all run inside a "hidden" network which is provided by Docker Compose. Only the Spring Cloud Gateway server is exposed to the outside world, so all traffic must go via this Gateway.

You can recreate these three Spring Boot projects for yourself from scratch, but the code can be downloaded to give you a quick-start. Here's a description of the three servers and what they each do...

1. [The Gateway][5] – The Gateway server acts as our gatekeeper for all HTTP traffic. All inbound and outbound traffic flows through this portal – it acts as the bridge between the outside world (your browser) and the internal Docker network. The Gateway has configuration that specifies some routes that can be used to talk to other services inside the network. These routes use the 'logical' names of the target services. These logical names are turned into real addresses by the Registry server.


2. [The Registry][6] – acts as a registry of all the services inside the hidden network. It allows the Gateway to find the other services mentioned in it's configuration using only logical service names.


3. [The Greeting Service][7] – (imaginatively titled 'service' in the [docker-compose.yml][8]) is a simple greeting service based on the [Spring.io](spring.io) guide "[Building a RESTful Web Service][4]".

As you can see in the [`docker-compose.yml` configuration][8], Docker is is configured to only allow external calls to reach the Gateway – on port `80`. The other servers, the Registry and the Service, cannot be reached directly from outside the Docker network. 

To allow traffic to be forwarded to the hidden servers, the Gateway is configured to offer some URL paths which redirect traffic to the these "hidden" servers. You can see the configuration for this in the Gateway's [application.yml file][9]. This configuration is using the "logical" names of these servers and the `lb:` (load balancer) protocol as you can see in the configuration snippet below.

```yaml
spring:
  application:
    name: gateway  
  cloud:
    gateway:
      routes:
      - id: service
        uri: lb://service
        predicates:
        - Path=/service/**
        filters:
        - StripPrefix=1
...
```

By using these 'logical' server names, the Gateway can discover the true location of these services at runtime. We cann this 'runtime-discovery'.

## Starting From Scratch

This really isn't necessary, but if you like to get your hands dirty, here's some pointers of what you need to do to recreate the demo.

### Creating a Greeting service that includes Eureka Discovery Client:

```bash
http https://start.spring.io/starter.zip dependencies==web,actuator,cloud-eureka baseDir==service name==service applicationName==Service groupId==com.scg artifactId==service | tar -xzvf -
```

For the code, follow the tutorial [here][4] which adds a `/greeting` REST endpoint to a Spring Boot service and responds with `{"id":1,"content":"Hello, World!"}` when called.

### Creating a Eureka Discovery Server

```bash
http https://start.spring.io/starter.zip dependencies==cloud-eureka-server baseDir==registry name==registry applicationName==Registry groupId==com.scg artifactId==registry javaVersion==11 | tar -xzvf -
```

Add `@EnableEurekaServer` annotation to the `Application.java` class.

> **Tip:** Using Java 11? You'll need to add some missing JAXB dependencies to the `pom.xml` file before packaging up the code.

### Creating a Gateway

```bash
http https://start.spring.io/starter.zip dependencies==actuator,cloud-gateway,cloud-eureka baseDir==gateway name==gateway applicationName==Gateway groupId==com.scg artifactId==gateway javaVersion=11 | tar -xzvf -
```

You'll need to configure the gateway to forward requests. Use [this example][9] as a guide.

## Building Server Images

To use [Cloud Native Buildpacks][2], you simply open a command line in the directory containing your Spring application code and then issue the command `pack build <your-image-name>`. The convention is to use your Docker username followed by a `/` and then the name of the image you're creating (for example 'benwilcock/scg-demo-service'). You may choose whatever names you like, but remember that these must match the image names you chose in your [`docker-compose.yml` file][8].

```bash
cd <code-dir>
pack build benwilcock/scg-demo-service
```

When you're done building all three, `docker images` should show all your images are available in the image cache as follows.

```bash
$ docker images
REPOSITORY                     TAG                 IMAGE ID            CREATED             SIZE
benwilcock/scg-demo-gateway    latest              4b1cf52e1cd9        21 hours ago        262MB
benwilcock/scg-demo-registry   latest              f48f8ed3ef10        21 hours ago        265MB
benwilcock/scg-demo-service    latest              33340b97b834        21 hours ago        260MB
```

> Note: you may have chosen different image names.

### Creating the Docker Compose group

Use [this file][8] as a guide. The goal here is to only expose the Gateway directly and to hide the Registry and the Greeting Service. There are some things to remember. The Docker images names must match the images that you built. The ports must match the ports you configured (`8080` by default for Gateway and Service, `8761` for the Registry). You'll notice that in our code we have injected the location of the Registry into the other servers at runtime using the JAVA_OPTS environment variable. Inside the Docker network, the Registry can be reached on `http://registry:8761/eureka`.

[1]: https://www.docker.com/products/docker-desktop
[2]: https://buildpacks.io/docs/app-journey/
[3]: https://github.com/benwilcock/spring-cloud-gateway-demo.git
[4]: https://spring.io/guides/gs/rest-service/
[5]: https://github.com/benwilcock/spring-cloud-gateway-demo/tree/master/runtime-discovery/gateway
[6]: https://github.com/benwilcock/spring-cloud-gateway-demo/tree/master/runtime-discovery/registry
[7]: https://github.com/benwilcock/spring-cloud-gateway-demo/tree/master/runtime-discovery/service
[8]: https://github.com/benwilcock/spring-cloud-gateway-demo/blob/master/runtime-discovery/docker-compose.yml
[9]: https://github.com/benwilcock/spring-cloud-gateway-demo/blob/master/runtime-discovery/gateway/src/main/resources/application.yml
[10]: http://localhost/registry
[11]: http://localhost/service/greeting
[12]: ../docs/img/registry.png
[13]: https://spring.io/guides/gs/service-registration-and-discovery/
[14]: https://spring.io/guides/gs/gateway/