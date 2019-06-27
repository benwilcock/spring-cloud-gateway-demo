# Hiding Services & Runtime Discovery

It's rare for a company to want every API to be publicly accessible, preferring to keep all their services secret by default and only exposing APIs publicly when absolutely necessary.

[Spring Cloud Gateway][14] can help. Spring Cloud Gateway allows you to route traffic to your APIs using Java™ instructions (as we saw [in the last article][15]) or with configuration files in YAML format which we’ll demonstrate in this one. To hide your services, you set up your network so that the only server accessible from the outside is the gateway. The gateway then becomes a gate-keeper, controlling ingress and egress from outside. It’s a very popular pattern.

Cloud-based services also have a habit of changing location without much warning. To cope better with this, you can combine a gateway with a service registry to allow the applications on your network to find each other dynamically at runtime. If you do this, your applications will be much more resilient to changes. [Spring Cloud Netflix Eureka Server][13] is one such service registry. In this post, we'll look at both of these libraries and illustrate how you can bring them together. 

Because this requires a fair amount of setup, we’ve provided a ready-made demo which you can download and run locally. We’ll use Docker to orchestrate our services and emulate our private network. We’ll then talk to our services (via the gateway) using HTTPie.

## Things You'll Need

* Java (version 8 is assumed), plus your favorite web browser and terminal applications.

* [The Source Code][3] - There’s no need to code anything, simply `git clone` (or download and `unzip`) [this project's source code repository][3] from GitHub and `cd` to the `runtime-discovery` folder in your terminal.

* [Docker Desktop][1] - Docker will provide our "pseudo-production environment". We'll use it to hide our running services in a private network.

* [Cloud Native Buildpacks][2] - We'll use the Cloud Native Buildpacks to build Docker container images for us. Buildpacks embody several DevOps best practices, including the use of hardened open-source operating systems and free to use OpenJDK distributions.

* [HTTPie][16] – a command line client for HTTP
  
## Quickstart Guide

* First, get all the "things you'll need" from the list above and install them. Then `cd` to the `runtime-discovery` folder as follows:

```bash
cd runtime-discovery
```

* Next, build & package all the source code and create Docker container images for everything. Use the `pack-images.sh` script provided to do this:

  ```bash
  ./pack-images.sh
  ```

* Now, bring up the test environment in the background.

  ```bash
  docker-compose up # Add `-d` to silence the container logs
  ```

* After a few minutes, Docker will have started all the containers following the configuration provided in the `docker-compose.yml` file.

> Waiting a couple of extra minutes here is advised, just to make sure that everything we started has had a chance to communicate and settle down. If you left the logs running, you’ll see this happening periodically.

## Let's Test It...

#### First, Check that the Greeting Service is Hidden:

The Greeting Service operates on port `8762` and is hidden inside the Docker network. Let's try to call it from your favorite browser using [http://localhost:8762/greeting](http://localhost:8762/greeting). You should be told that "the site can't be reached" by your browser. This is because the Greeting Service is hidden inside the Docker network (as if it were behind a company firewall). It shouldn't be possible for us to talk to the greeting service directly.

#### Next, Access the Greeting Service via the Gateway:

Now, Navigate your browser to [http://localhost/service/greeting][11]. You should now get a valid response with content similar to the "Hello, World" JSON shown below:

```json
{ "id": 1, "content": "Hello, World!"}
```

> Note: As we're using the default HTTP port for this request, the port number (80) has been omitted.

When you issued this new HTTP request from your browser, it was sent to, and handled by, the Gateway. The Gateway service _is_ publicly accessible (it is mapped to port `80`, the default for HTTP). Your request was forwarded by the Gateway to the Greeting Service on your behalf, and the response was then routed back to you by the Gateway.

#### Now, let's take a look at the Registry of Services:

The microservices on the Docker network are each registering themselves with the Registry server (this may take a couple of minutes, so be patient). The Registry server acts an address book for the services. If the services move, or if new instances are created, they will add themselves to the registry.

To view the current list of registered services, point your browser at [http://localhost/registry][10]. You should see a screen similar to the one below.

![Screenshot from the Registry console, listing several services][12]

#### Finally, lets shut things down

When you're done, use `ctrl-C` in your terminal to shut down the Docker services. If for any reason this fails to work, you can also use `docker-compose down` from the `runtime-discovery` folder. Using either technique, you should see output similar to this:

```bash
Stopping gateway  ... done
Stopping service  ... done
Stopping registry ... done
```

## How It Works

In this demo, we have three servers. These three servers are all running inside a "hidden" network which is provided by Docker Compose. Only the [Gateway server][5] is exposed to the outside world, so all HTTP traffic must go via this Gateway.

Here's a description of the three servers and what each does...

1. [The Gateway][5] – The Gateway server acts as our gatekeeper for all HTTP traffic. All inbound and outbound traffic flows through this portal – it acts as the bridge between the outside world (your browser) and the services on the internal Docker network. The Gateway has a configuration that specifies routes which can be used externally to talk to the services inside the network. These routes use the 'logical' names of the target services. These logical names are turned into real addresses by the Registry server.

2. [The Registry][6] – acts as a phone book of all the services on the hidden network. It allows the Gateway to find the other services using only their logical service names.

3. [The Greeting Service][7] – (imaginatively titled 'service' in the [docker-compose.yml][8]) is a simple greeting service based on the [Spring.io](spring.io) guide "[Building a RESTful Web Service][4]".

As you can see in the [`docker-compose.yml` configuration][8], Docker is configured to only allow external calls to reach the Gateway – on port `80`. The other servers (the Registry, and the Greeting Service), cannot be reached directly from outside the Docker network.

The Gateway's configured URL passthrough paths can be seen in the Gateway's [application.yml file][9]. This configuration is using the "logical" names of these servers and the `lb:` (load balancer) protocol as you can see in the extract below:

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

By using these 'logical' server names, the Gateway can use the Registry to discover the true location of these services at runtime.
## Next Time

In this blog, we’ve only just scratched the surface of what’s possible. With the entire Spring toolkit at its disposal, it quickly becomes apparent how flexible and powerful Spring Cloud Gateway can be. If you take a look in [the source code for this sample][3], you’ll notice that with just a few lines of code and a few dependencies, we can easily integrate Spring Boot microservices with Eureka, and how we can control access to our APIs with . Next time we’ll take a look at <NEXT BLOG>!

Finally, be sure to check out SpringOne Platform, the premier conference for building scalable applications that people love. Join your peers to learn, share, and have fun in Austin, TX from October 7th to 10th for the biggest and best show yet. Even better, use code S1P_Save200 when registering to save on your ticket. We hope to see you there!

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
[12]: /img/registry.png
[13]: https://spring.io/guides/gs/service-registration-and-discovery/
[14]: https://spring.io/guides/gs/gateway/
[15]: https://content.pivotal.io/practitioners/getting-started-with-spring-cloud-gateway-3
[16]: https://httpie.org/