# Securing Services with Spring Cloud Gateway

* [Ben Wilcock][1] – Spring Marketing, Pivotal.
* [Brian McClain][2] – Technical Marketing, Pivotal.

So far in this series, we've covered [Getting Started][3] and [Hiding Services][4] with [Spring Cloud Gateway][5]. However, when we set about hiding our services, we didn't actually get around to securing them. In this article, we'll correct this.

To secure our services, we'll use the Token Relay pattern supported by OAuth 2.0 and the Javascript Object Signing & Encryption (JOSE) and JSON Web Tokens standards. This will give our users a means to identify themselves, authorize applications to view their profile, and access the secured resources behind the gateway.

> All the demo code is available in [this repository on GitHub][6] in the `secured-gateway` folder.

Before we run the demo, I want to draw your attention to the major components within it and how they were created. The diagram below shows the overall system design. It consists of a network of three services: a Single Sign-On Server, an API Gateway Server, and a Resource Server.

![Diagram illustrating the overarching architecture of the demo][demo]

The Resource Server is a regular Spring Boot application hidden behind the API Gateway. The API Gateway is built with Spring Cloud Gateway and delegates the management of user accounts and authorization to the Single Sign-On server. In order to create these three components, there are a number of small but important things to take into account. Let’s take a look at what these were next.

## Creating A User

In order to authenticate our users, we need two things: user account records and an OAuth2 compatible Authentication Provider (or server). There are many commercial OAuth2 authentication providers out there, but in our demo, we're going to stick with open-source software and use Cloud Foundry’s User Account & Authentication Server, more commonly referred to as the UAA.

The UAA is a Web Archive (WAR) that can be deployed onto any server that supports this format. In our case, we've chosen the open-source Apache Tomcat server. When running in Tomcat, the UAA provides OAuth and OpenId Connect authentication against its internal user account database.

For this demo, we’ve built the UAA and Tomcat into a container image using a `Dockerfile` (which you can examine in the `uaa` folder). The other item to draw your attention to is the `uaa.yml` file. This YAML file will configure our UAA with the user and password to use later when we’re trying to access the Resource Server. It also contains the OAuth2 applications to register, and the keys required to perform JWT token encryption.

In the `uaa.yml` we tell the UAA to add `user1` to its account database and to grant this user the `resource.read` scope. This is the scope the Resource Server will require to allow access.

```yaml
scim:
  groups:
    email: Access your email address
    resource.read: Allow access with 'resource.read'
  users:
    - user1|password|user1@provider.com|first1|last1|uaa.user,profile,email,resource.read
```

In the `uaa.yml` we also register our OAuth2 ‘client’ application. This registration tells the UAA that it should expect an application to identify itself as the `gateway` and that this application will use the `authorization_code` scheme. The gateway will expect to access various scopes including `resource.read`.

```yaml
oauth:
...
  clients:
    gateway:
      name: gateway
      secret: secret
      authorized-grant-types: authorization_code
      scope: openid,profile,email,resource.read
      authorities: uaa.resource
      redirect-uri: http://localhost:8080/login/oauth2/code/gateway
```

## Integrating The UAA with Spring Cloud Gateway

As you can see in the [Spring Cloud Security, OAuth2 Token Relay docs][6]: "Spring Cloud Gateway can forward OAuth2 access tokens to the services it is proxying. In addition to logging in the user and grabbing a token, a filter extracts the access token for the authenticated user and puts it into a request header for downstream requests."

This effectively means that there is very little work involved when integrating our Spring Cloud Gateway server with our chosen security mechanism when using Spring Cloud Security. The gateway will coordinate authentication with the single sign-on server on our behalf and ensure that downstream applications get a copy of the users access token when they need it.

In order to configure this feature, the first thing of note is the OAuth2 configuration in our gateway’s `application.yml` file.

```yaml
security:
    oauth2:
      client:
        registration:
          gateway:
            provider: uaa
            client-id: gateway
            client-secret: secret
            authorization-grant-type: authorization_code
            redirect-uri-template: "{baseUrl}/login/oauth2/code/{registrationId}"
            scope: openid,profile,email,resource.read
        provider:
          uaa:
            authorization-uri: http://localhost:8090/uaa/oauth/authorize
            token-uri: http://uaa:8090/uaa/oauth/token
            user-info-uri: http://uaa:8090/uaa/userinfo
            user-name-attribute: sub
            jwk-set-uri: http://uaa:8090/uaa/token_keys
```

This configuration is doing two things. It’s specifying our OAuth client registration information (which matches the `gateway` application that we registered in the UAA earlier), and it is detailing where the OAuth authentication provider’s services can be found (along with some other attributes such as the `jwk-set-uri` which the gateway will use to verify the authenticity of the token). This config is essentially enabling our gateway to communicate effectively with the UAA.

The next item of interest here is the `GatewayApplication.java` class. In this class, we have two things to take note of. The first is the inclusion of an autowired `TokenRelayGatewayFilterFactory` and the second is the use of this class as a filter in the route configuration for our Resource Server:

```java
@Autowired
private TokenRelayGatewayFilterFactory filterFactory;

@Bean
public RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
    return builder.routes()
            .route("resource", r -> r.path("/resource")
              .filters(f -> f.filters(filterFactory.apply())
                .removeRequestHeader("Cookie"))
            .uri("http://resource:9000")) 
            .build();
}
```

The second is the configuration of the route. As discussed in the [Hiding Services][4], we must expose the Resource Server as a route, otherwise it will remain hidden inside our network. The `filterFactory.apply()` method in the route declaration ensures that any exchanges intended for the Resource Server contain a JWT access token. The `removeRequestHeader(“Cookie”)` tells the gateway to remove the users “Cookie” header from the request during the routing operation (because downstream services don’t need this, all they need is the JWT `access_token`).

The YAML configuration below achieves the same thing, but without the need for Java code:

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: resource
          uri: http://resource:9000
          predicates:
            - Path=/resource
          filters:
            - TokenRelay=
            - RemoveRequestHeader=Cookie
```

With our gateway configured this way (using either Java or YAML), any user request heading to the Resource Server on the `/resource` route will need a security `access_token` in JWT format.

## Creating a Resource Server and Securing a Resource

The Resource Server now requires only two things. The first is a `/resource` endpoint that expects an authentication principal in the form of a JWT token. The second is some configuration to prevent access to the `/resource` endpoint unless you have such a token.

The `@RestController` endpoint for `/resource` expects a Jwt object as a method parameter. This parameter is decorated as the `@AuthenticationPrincipal`. The method returns a simple string containing a message. This message confirms the resource was accessed and contains some basic details about the user.

```java
@GetMapping("/resource")
public String resource(@AuthenticationPrincipal Jwt jwt) {
    return String.format("Resource accessed by: %s (with subjectId: %s)" ,
            jwt.getClaims().get("user_name"),
            jwt.getSubject());
}
```

The security configuration is handled by the `SecurityConfig` class. This class contains a bean method that configures the `ServerHttpSecurity` object passed as a parameter in the `springSecurityFilterChain` method signature. 

This configuration declares that users asking to access the path `/resource` must be authenticated and must have the OAuth2 scope `resource.read` in their profile. The line `.oauth2ResourceServer().jwt()` is telling the application that it must use the OAuth2 JWT specification as the security scheme.

```java
public class SecurityConfig {

  @Bean
  SecurityWebFilterChain springSecurityFilterChain(ServerHttpSecurity http) throws Exception {
    http
            .authorizeExchange()
             .pathMatchers("/resource").hasAuthority("SCOPE_resource.read")
              .anyExchange().authenticated()
              .and()
            .oauth2ResourceServer()
              .jwt();
    return http.build();
  }
}
```

Finally, the Resource Server needs to know where it can find the public keys to validate the authenticity of the access token which it has been given. The UAA provides an endpoint which both the Resource Server and the Gateway rely upon at runtime to do this check. The endpoint is configured in the `application.yml` for each application:

```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          jwk-set-uri: http://uaa:8090/uaa/token_keys
```

You don’t have to use an endpoint to grab these keys, you can bundle them into your application directly, but we’ve chosen not to here. If you follow the `jwk-set-uri` link in a browser when the demo is running, you’ll see something like this:

![An example of the token keys endpoint data showing a JSON object containing public keys][keys]

## Running The Demo

As before, we’ll use Docker Compose to keep things simple and emulate a real network. With the code checked out and Docker already running in the background, in the `security-gateway` folder, execute the `build.sh` script to compile the Resource Server and the Gateway applications into JAR’s and then package these and the UAA into containers.

```bash
$> cd security-gateway
$> ./build.sh
```

Once this process has finished successfully, we can start the demo using `docker-compose up`:

```bash
$> docker-compose up
```

When you do this, you will see a lot of output on your screen while all three servers start up, but after a couple of minutes, it should settle down.

Now, open a ‘private’ or ‘incognito’ browser window and navigate to [http://localhost:8080/resource][7]. Immediately, the gateway will forward your browser to the UAA server and ask you to login using your username and password (in this case “user1” and ”password”). The UAA will then ask you to ‘Authorize’ the gateway to read user1’s profile. You’ll be presented with the following screen to do this:

![An image showing the UAA autherisation screen used to autherise the application's access to the read dot resource scope][authorization]

Notice in particular the checkbox entitled “Allow access with ‘resource.read’”. It’s this scope that the Resource Server will check before allowing you access to the resource. 

Once you click ‘Authorize’ you’ll be forwarded to the `[/resource][7]` endpoint which will show you some basic details about your user. You’ll see a message similar to this, although your `subjectId` will be different:

`Resource accessed by: user1 (with subjectId: 43c7681a-6762-451e-8435-d503fd7a0c4d)`

This is the resource server confirming you could access the resource, and showing that you used user1’s identity.

If you want to see some additional information about user1, navigate to [http://localhost:8080][8] where a more complete user detail screen has been provided. It looks something like this:

![An image showing the full user details screen available once logged in and authorized][user]

Finally, in the logs, we’ve printed out the JWT token passed to the Resource Server so that you can inspect it. We wouldn’t ever do this in production, but for demo purposes, we felt it would be helpful to see it. It looks something like this:

```bash
resource | TRACE --- SecuredServiceApplication: ***** JWT Token: eyJhbGciOiJSUzI1NiIsImprdSI6Imh0dHBzOi8vbG9jYWxob3N0OjgwODAvdWFhL3Rva2VuX2tleXMiLCJraWQiOiJrZXktaWQtMSIsInR5cCI6IkpXVCJ9.eyJqdGkiOiJm (truncated...)
```

You can copy this token in its entirety from the log and paste it into the JWT Debugger at [jwt.io][9]. This utility can parse the token and show you the contents. In the output, you’ll find the username and the scopes associated with the user's profile.

![An image showing the jwt.org screen after parsing the JWT token generated by the UAA and used by our user to access reasources][jwt]

The logs themselves are also quite revealing (although the order is not guaranteed). They show much of what’s going on as these three servers interact with each other. To see some edited log highlights with some additional notes, [look here][10].

## Finishing Up

When you're done, use `Ctrl-C` to shut down the Docker services. If for any reason this fails to work, you can also use `docker-compose down` from the `security-gateway` folder. With either technique, you should see output similar to this:

```bash
$> docker-compose down 
Stopping gateway  ... done
Stopping service  ... done
Stopping registry ... done
```

Further clean-up of Docker can be achieved using `docker-compose rm -f`.

## And Finally...

Why not have your developer dreams come true this year by signing up for [SpringOne Platform][11]? It’s the premier conference for building scalable applications with Spring. Join thousands of other developers to learn, share, and have fun in Austin, TX from October 7th to 10th. Use the discount code S1P_Save200 when registering to save money on your ticket. If you need help convincing your manager try [these tips][12].


[1]: https://twitter.com/benbravo73
[2]: https://twitter.com/BrianMMcClain
[3]: getting_started.md
[4]: runtime-discovery-and-service-hiding.md
[5]: https://spring.io/projects/spring-cloud-gateway
[6]: https://cloud.spring.io/spring-cloud-static/spring-cloud-security/2.1.3.RELEASE/single/spring-cloud-security.html#_token_relay
[7]: http://localhost:8080/resource
[8]: http://localhost:8080
[9]: https://jwt.io/
[10]: secured-gateway-access-log.md
[11]: https://springoneplatform.io
[12]: https://springoneplatform.io/2019/convince-your-manager



[demo]: https://static.spring.io/blog/bwilcock/20190801/demo.png "Diagram illustrating the overarching architecture of the demo"
[keys]: https://static.spring.io/blog/bwilcock/20190801/keys.png "An example of the token keys endpoint data showing a JSON object containing public keys"
[authorization]: https://static.spring.io/blog/bwilcock/20190801/authorize.png "An image showing the UAA authorisation screen used to autherise the application's access to the read dot resource scope"
[user]: https://static.spring.io/blog/bwilcock/20190801/user.png "An image showing the full user details screen available once logged in and authorized"
[jwt]: https://static.spring.io/blog/bwilcock/20190801/jwt.png "An image showing the jwt.org screen after parsing the JWT token generated by the UAA and used by our user to access reasources"