# Getting Started with Spring Cloud Gateway

In this first article in our series on Spring Cloud Gateway, we’ll start by doing something very simple – reroute requests coming into a gateway and forward them to another service elsewhere. We’ll also insert a simple HTTP Header to the request just to show one more example of what’s possible with a gateway.

#### Tools you'll need:

* [HTTPie][4] – a command line client for http calls 
* Your favorite Java IDE (check out [Spring Tools][5] if you don’t have one)
* Your favorite command line (e.g zsh, bash, DOS command or PowerShell)
* [Httpbin.org][6] – a website and diagnosis tool which converts Http GET request data into a JSON response 

## Step 1: Create a project

In a new folder, download and extract a new Spring Cloud Gateway project using [start.spring.io][7] (and [HTTPie][4]) as follows...

```bash
http https://start.spring.io/starter.zip dependencies==cloud-gateway,actuator baseDir==spring-cloud-gateway-demo | tar -xzvf -
```

We can immediately assert that this project is working by building and running the code and checking the Spring Boot Actuator health endpoint like so...

```bash
./mvnw package spring-boot:run
```

Now that your Spring Boot application is up and running, point your browser to [http://localhost:8080/actuator/health][8]. You should receive a JSON-formatted message saying `{"status":"UP"}` which indicates that everything is working fine. Now stop your server (ctrl+c) and continue to the next section.

## Step 2: Add a re-route instruction to the Gateway

In your IDE, open the class `src/main/java/com/example/demo/DemoApplication.java` and add the following method, correcting the import statements as you go. If you get stuck, check out the code sample [here][10].

```java
    @Bean
    public RouteLocator myRoutes(RouteLocatorBuilder builder) {
        return builder.routes()
            // Add a simple re-route from: /get to: http://httpbin.org:80
            // Add a simple "Hello:World" HTTP Header
            .route(p -> p
            .path("/get") // intercept calls to the /get path
            .filters(f -> f.addRequestHeader("Hello", "World")) // add header
            .uri("http://httpbin.org:80")) // forward to httpbin
            .build();
    }
```

Here we build a new route for our gateway. Any request to `http://localhost:8080/get` will be matched to this route instruction and our two changes to the request will be made. The `filters()` method handles things such as adding or changing headers, in our case setting the `Hello` header to the value `World`. Additionally, the `uri()` method forwards our request to the new host. It’s important to note that the `/get` path is being retained when forwarding the message. 

Now compile your new code and start the application server once more, like this...

```bash
./mvnw package spring-boot:run
```

In the next section we'll test what we've built.

# Step 3: Test your new Gateway

To test what we have built, we can once again use [HTTPie][4]. Send a HTTP GET request to [http://localhost:8080/get][9] and observe what comes back, like this...

```bash
http localhost:8080/get --print=HhBb
```

You should see a response very much like the one shown below.

```bash
GET /get HTTP/1.1
Accept: */*
Accept-Encoding: gzip, deflate
Connection: keep-alive
Host: localhost:8080
User-Agent: HTTPie/1.0.2

HTTP/1.1 200 OK
Access-Control-Allow-Credentials: true
Access-Control-Allow-Origin: *
Content-Encoding: gzip
Content-Length: 256
Content-Type: application/json
Date: Mon, 10 Jun 2019 13:13:36 GMT
Referrer-Policy: no-referrer-when-downgrade
Server: nginx
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block

{
    "args": {},
    "headers": {
        "Accept": "*/*",
        "Accept-Encoding": "gzip, deflate",
        "Forwarded": "proto=http;host=\"localhost:8080\";for=\"0:0:0:0:0:0:0:1:52144\"",
        "Hello": "World",
        "Host": "httpbin.org",
        "User-Agent": "HTTPie/1.0.2",
        "X-Forwarded-Host": "localhost:8080"
    },
    "origin": "0:0:0:0:0:0:0:1, 2.102.147.153, ::1",
    "url": "https://localhost:8080/get"
}
```

There are a few things of note in this output:

1. The response originates from [httpbin.org][6] as evidenced by the `Host` header. 
2. The `X-Forwarded-Host` is `localhost:8080` (our locally running Gateway application)
3. The Http header `Hello` has been inserted and given a value of `World`.
4. In the Json response, the full `"url"` of the original request is `"https://localhost:8080/get"` (the DemoApplication service that we built together).

The path of execution is from the client ([HTTPie][4]) -> DemoApplication.java (our gateway) -> httpbin.org (our echo service) and then back again.

## Final thoughts.

That’s it. You now should have a Spring Cloud Gateway application up and running and have learned how to forward basic requests to another endpoint. You could use this technique to automatically forward requests from your Gateway application to any other service.

The code to accompany this article can be found [here][10]. The full documentation for the current GA release of Spring Cloud Gateway (2.1.0 at the time of writing) can be found [here][11].

## Next time.

We’ve only dipped our toes into what Spring Cloud Gateway can do, but hopefully, this was a good first look. In our next post, we’ll take a look at how to create a dynamic gateway – one that can discover the location of services at runtime. Until then, if you'd like to learn more, be sure to check out the [Spring Cloud Gateway page on spring.io][3], the [official guide][12], or set up your own service and gateway on [Pivotal Web Services][13]! 

Finally, be sure to check out [SpringOne Platform][14], the premier conference for building scalable applications that people love. Join your peers to learn, share, and have fun in Austin, TX from October 7th to 10th for the biggest and best show yet. Even better, use code **S1P_Save200** when registering to save on your ticket. We hope to see you there!


[1]: https://twitter.com/benbravo73
[2]: https://twitter.com/BrianMMcClain
[3]: https://spring.io/projects/spring-cloud-gateway
[4]: https://httpie.org/
[5]: https://spring.io/tools
[6]: http://httpbin.org
[7]: https://start.spring.io/
[8]: http://localhost:8080/actuator/health
[9]: http://localhost:8080/get
[10]: https://github.com/benwilcock/spring-cloud-gateway-demo
[11]: https://cloud.spring.io/spring-cloud-static/spring-cloud-gateway/2.1.0.RELEASE/single/spring-cloud-gateway.html
[12]: https://spring.io/guides/gs/gateway/
[13]: https://run.pivotal.io/
[14]: https://springoneplatform.io/