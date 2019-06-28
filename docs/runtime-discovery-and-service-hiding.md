# Hiding Services & Runtime Discovery 

It's rare for a company to want every API to be publicly accessible. Most prefer to keep their services secret by default, only exposing APIs publicly when absolutely necessary. 

[Spring Cloud Gateway][14] can help. Spring Cloud Gateway allows you to route traffic to your APIs using simple Java™ instructions (which we saw [in the last article][15]) or with YAML configuration files (which we’ll demonstrate in this one). To hide your services, you set up your network so that the only server accessible from the outside is the gateway. The gateway then becomes a gate-keeper, controlling ingress and egress from outside. It’s a very popular pattern.

Cloud-based services also have a habit of changing location and granularity without much warning. To cope better with this, you can combine a gateway with a service registry to allow the applications on your network to find each other dynamically at runtime. If you do this, your applications will be much more resilient to changes. [Spring Cloud Netflix Eureka Server][13] is one such service registry.

In this post, we'll look at Spring Cloud’s gateway and registry components and illustrate how you can use them together to make your applications more secure and more reliable. 

Because this arrangement requires a particular setup, we’ve provided ready-to-run code which you can download and run. We’ll be using Docker to orchestrate our services and emulate a private network. We’ll then talk to our running services using HTTPie.

## Things You'll Need
* Java (version 8 is assumed), plus your favorite web browser and terminal applications.

* [The Source Code][3] – There’s no need to write any code this time, simply `git clone` (or download and `unzip`) [this project's source code repository][3] from GitHub.

* [Docker Desktop][1] – Docker will provide our pseudo-production environment. We'll use it to hide our services in a private network.

* [Cloud Native Buildpacks][2] – We'll use Cloud Native Buildpacks to build Docker container images for us. Buildpacks embody several DevOps best practices, including hardened open-source operating systems and free to use OpenJDK distributions.
  
## Let’s Get Started...

#### Step 1:

Download and install all the "things you'll need" from the list above. Then change to the runtime-discovery folder in the source code as follows:

```bash
cd runtime-discovery
```

#### Step 2:

Build & package the gateway, registry, and service into JARs using Maven, and then create Docker containers for each of them. We have provided a handy [pack-images][21] script to do this:

  ```bash
 ./pack-images.sh
  ```

#### Step 3:

Start up the Docker test environment in the background. We’re using docker-compose here as it can start multiple containers and create a private network for them to communicate on:

  ```bash
  docker-compose up
  ```

#### Step 4:

Wait. Docker will start all the containers (using the configuration provided in the [docker-compose.yml][8] file). Waiting a couple of extra minutes here is advised. It gives Docker time to start everything and gives the applications a chance to communicate and settle down. If you do wait, you should see the Gateway and the Greeting Service register themselves with the Registry. There will be lots of logs, but within them will be lines like these from the registry:


```bash
registry    | 2019-06-28 12:19:01.780  INFO 1 --- [nio-8761-exec-2] c.n.e.registry.AbstractInstanceRegistry  : Registered instance REGISTRY/db1d80613789:registry:8761 with status UP (replication=false)
registry    | 2019-06-28 12:19:02.380  INFO 1 --- [nio-8761-exec-6] c.n.e.registry.AbstractInstanceRegistry  : Registered instance GATEWAY/9c0c0c9ba027:gateway:8760 with status UP (replication=true)
registry    | 2019-06-28 12:19:02.382  INFO 1 --- [nio-8761-exec-6] c.n.e.registry.AbstractInstanceRegistry  : Registered instance SERVICE/fe7e38b21cac:service:8762 with status UP (replication=true)
```
## Let's Try It...

#### First, Check that the Greeting Service is Hidden:

The Greeting Service operates on port `8762` and is hidden inside the Docker network. Let's try to call it from your favorite browser using [http://localhost:8762/greeting](http://localhost:8762/greeting). You should be told that "the site can't be reached" by your browser. This is because the Greeting Service is hidden inside the Docker network (as if it were behind a company firewall). It shouldn't be possible for us to talk to the greeting service directly.

#### Next, Access the Greeting Service via the Gateway:

Now, Navigate your browser to [http://localhost:8080/service/greeting][11]. You should now get a valid response with content similar to the "Hello, World" JSON shown below:

```json
{ "id": 1, "content": "Hello, World!"}
```

When you issued this new HTTP request from your browser, it was sent to, and handled by, the Gateway. The Gateway service _is_ publicly accessible (it’s mapped to port `8080`). Your request was forwarded by the Gateway to the Greeting Service on your behalf, and the response was then routed back to you by the Gateway.

#### Now, View the Registry of Services:

The microservices on the Docker network are each registering themselves with the Registry server (this may take a couple of minutes, so be patient). The Registry server acts an address book for the services. If the services move, or if new instances are created, they will add themselves to the registry.

To view the current list of registered services, point your browser at [http://localhost/registry][10]. You should see a screen similar to the one below.

![Screenshot from the Registry console, listing several services][12]

#### Finally, Clean Up:

When you're done, use `ctrl-C` in your terminal to shut down the Docker services. If for any reason this fails to work, you can also use `docker-compose down` from the `runtime-discovery` folder. Using either technique, you should see output similar to this:

```bash
Stopping gateway  ... done
Stopping service  ... done
Stopping registry ... done
```

## How It Works

In this demo, we have 3 servers. These servers are all running inside a "hidden" network which is provided by [Docker Compose][20]. Only the [Gateway server][5] is exposed to the outside world, so all HTTP traffic must go via this Gateway.

Here's a description of the 3 servers and what each does...

1. [The Gateway][5] – acts as our gatekeeper for all HTTP traffic. All inbound and outbound traffic flows through this portal – it acts as the bridge between the outside world (your browser) and the services on the internal Docker network. The Gateway has a configuration that specifies routes which can be used to talk to the services inside the network. These routes use the 'logical' names of the target services. These logical names are turned into real addresses by the Registry server.

2. [The Registry][6] – acts as a phone book of all the services on the hidden network. It allows the Gateway to find the Greeting Service using only its logical name.

3. [The Greeting Service][7] – (imaginatively titled 'service' in the [docker-compose.yml][8]) is a simple REST service based on the [Spring.io](spring.io) guide "[Building a RESTful Web Service][4]".

As you can see in the [`docker-compose.yml`][8], Docker is configured to only allow external calls to reach the Gateway – on port `80`. The other servers (the Registry, and the Greeting Service), cannot be reached directly from outside.

The Gateway's configured URL passthrough paths can be seen in the Gateway's [application.yml file][9]. This configuration is using the "logical" names of these servers and the `lb:` (load balancer) protocol as shown in the extract below:

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
## Wrapping Up

With the entire Spring toolkit at its disposal, it quickly becomes apparent how flexible and powerful Spring Cloud Gateway can be. If you dig into [the source code][3], you’ll notice that with just a few lines of Java and a few dependencies, we can easily integrate Spring Boot microservices with Eureka, and control access to our service’s APIs. 

Before you go, why not sign up for [SpringOne Platform][18], the premier conference for building scalable applications that delight users. Join thousands of like-minded Spring developers to learn, share, and have fun in Austin, TX from October 7th to 10th.  Use the discount code **S1P_Save200** when registering to save money on your ticket and use [this page][19] if you need help convincing your manager. See you there.

[1]: https://www.docker.com/products/docker-desktop
[2]: https://buildpacks.io/docs/app-journey/
[3]: https://github.com/benwilcock/spring-cloud-gateway-demo.git
[4]: https://spring.io/guides/gs/rest-service/
[5]: https://github.com/benwilcock/spring-cloud-gateway-demo/tree/master/runtime-discovery/gateway
[6]: https://github.com/benwilcock/spring-cloud-gateway-demo/tree/master/runtime-discovery/registry
[7]: https://github.com/benwilcock/spring-cloud-gateway-demo/tree/master/runtime-discovery/service
[8]: https://github.com/benwilcock/spring-cloud-gateway-demo/blob/master/runtime-discovery/docker-compose.yml
[9]: https://github.com/benwilcock/spring-cloud-gateway-demo/blob/master/runtime-discovery/gateway/src/main/resources/application.yml
[10]: http://localhost:8080/registry
[11]: http://localhost:8080/service/greeting
[12]: /img/registry.png
[13]: https://spring.io/guides/gs/service-registration-and-discovery/
[14]: https://spring.io/guides/gs/gateway/
[15]: https://content.pivotal.io/practitioners/getting-started-with-spring-cloud-gateway-3
[16]: https://httpie.org/
[17]: https://github.com/OlgaMaciaszek/spring-cloud-netflix-demo
[18]: https://springoneplatform.io/
[19]: https://springoneplatform.io/2019/convince-your-manager
[20]: https://docs.docker.com/compose/
[21]: https://github.com/benwilcock/spring-cloud-gateway-demo/blob/master/runtime-discovery/pack-images.yml
[22]: /img/unreachable.png
