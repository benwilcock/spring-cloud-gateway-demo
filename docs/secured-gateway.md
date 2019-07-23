# Securing Services with Spring Cloud Gateway

* [Ben Wilcock][1] – Spring Marketing, Pivotal.
* [Brian McClain][2] – Technical Marketing, Pivotal.

So far in this series, we've covered [Getting Started][3] and [Hiding Services][4] with [Spring Cloud Gateway][5]. However, when hiding services with the gateway we didn't actually make them secure. If you knew the correct endpoint, you could still access what the service had to offer. In this article we'll set about securing our applications behind Spring Cloud Gateway. 

To do this, we'll use the Token Relay pattern supported by OAuth 2.0 and the Javascript Object Signing & Encryption (JOSE) and JSON Web Tokens standards. This will give the users of our gateway a means to identify themselves, authorize applications, and ultimately access resources in a secure way. Let's get started...

> All the demo code is available in [this repository on GitHub][6] in the `secured-gateway` folder. There's a glossary of terms below for any that you're not familiar with.

Before we explain what's happening, lets first clone the sample code, compile it, and build our containers. With Docker already started, in the `security-gateway` folder we simply run the `build-images.sh` script provided.

```bash
git clone https://github.com/benwilcock/spring-cloud-gateway-demo.git
cd security-gateway
./build-images.sh
```

We won't run the code yet. First I want to draw your attention to some of the more important pieces of code.

## Step One: Creating A User

In order to authenticate a users we need two things. The first is a user, the second is an OAuth2 compatible authentication provider (or server).

There are many different commercial OAuth2 providers that you can work with. Okta is one popular example. In our code though, we're going to stick with Open Source and use the Cloud Foundry Universal Authorisation & Authentication Server, often referred to as the UAA. The UAA is a Java Web Archive (WAR) that can be configured and deployed onto any web server that supports this format. In our case, we've chosen Apache Tomcat to take on this duty.

To make this simple, all the configuration required to set up Tomcat and the UAA has been provided. The UAA is built into a container image using Docker. 

The main bit of configuration to draw your attention to here is the `uaa/uaa.yml` file. This file sets up the UAA with the keys that it needs to perform encryption, the clients registered as OAuth applications, and the users and roles to use when authenticating. 

On lines 10–27 we register our OAuth ‘client’ application:

```yaml
oauth:
...
  clients:
    login-client:
      name: Login Client
      secret: secret
      authorized-grant-types: authorization_code
      scope: openid,profile,email,resource.read
      authorities: uaa.resource
      redirect-uri: http://localhost:8080/login/oauth2/code/login-client
```

This tells the OAuth server that it should expect an application to identify itself as the `login-client` and this application will use the `authorisation_code` grant type. The client will also expect to access various scopes including `resource.read`.

On lines 29–34 we create the our user:

```yaml
scim:
  groups:
    email: Access your email address
    resource.read: Allow access with 'resource.read'
  users:
    - user1|password|user1@provider.com|first1|last1|uaa.user,profile,email,resource.read
```

This tells the OAuth server to add user `user1` to its database of users and to associate the `resource.read` scope with this user. 

When being built by Docker, the server will have its endpoint port set to 8090 by overriding Apache Tomcat’s default `server.xml`. 

## Step Two: Integrating a Security Server with Spring Cloud Gateway

As you can see in the [Spring Cloud Security, OAuth2 Token Relay docs][8]: "If your app has a Spring Cloud Gateway embedded reverse proxy then you can ask it to forward OAuth2 access tokens downstream to the services it is proxying. Then, in addition to logging in the user and grabbing a token, the Gateway will pass the authentication token downstream to other services. The filter extracts an access token from the currently authenticated user, and puts it in a request header for the downstream requests."

This means that there is very little work involved in integrating our Spring Cloud Gateway server with our chosen security mechanism. 

The [original sample][9].

```java
@Autowired
private TokenRelayGatewayFilterFactory filterFactory;

@Bean
public RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
    return builder.routes()
                    .route("resource", r -> r.path("/resource")
                        .filters(f -> f.filters(filterFactory.apply())
                            .removeRequestHeader("Cookie")) // Prevents client cookie reset
                        .uri("http://resource:9000")) // Taking advantage of docker naming
                    .build();
}
```

This YAML configuration acheives the same thing without the need for code:

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
```



## Glossary

These terms are used in this article, so here is some more information.

### OAuth2

[OAuth 2.0][12] is the industry-standard protocol for authorization. OAuth 2.0 supersedes the work done on the original OAuth protocol created in 2006. OAuth 2.0 focuses on client developer simplicity while providing specific authorization flows for web applications, desktop applications, mobile phones,and living room devices. This specification and its extensions are being developed within the IETF OAuth Working Group. OAuth 2 is [spported by Spring Boot][11].

### Token Relay

A [Token Relay][8] is where an OAuth2 consumer acts as a Client and forwards the incoming token to outgoing resource requests. The consumer can be a pure Client (like an SSO application) or a Resource Server.

### Javascript Object Signing & Encryption (JOSE) 

[JOSE][10] is a framework intended to provide a method to securely transfer claims (such as authorization information) between parties. The JOSE framework provides a collection of specifications to serve this purpose. 


### JSON Web Token (JWT)

A [JSON Web Token (JWT)][7] contains claims that can be used to allow a system to apply access control to resources it owns. One potential use case of the JWT is as the means of authentication and authorization for a system that exposes resources through an OAuth 2.0 model.

### Spring Cloud Security

[Spring Cloud Security][13] offers a set of primitives for building secure applications and services in cloud environments with minimum fuss. It's a declarative model which lends itself to the implementation of large systems of co-operating, remote components, usually with a central indentity management service. Building on Spring Boot and Spring Security OAuth2 we can quickly create systems that implement common patterns like single sign on, token relay and token exchange.

[1]: https://twitter.com/benbravo73
[2]: https://twitter.com/BrianMMcClain
[3]: getting_started.md
[4]: runtime-discovery-and-service-hiding.md
[5]: https://spring.io/projects/spring-cloud-gateway
[6]: https://jose.readthedocs.io/en/latest/#f1
[7]: https://jose.readthedocs.io/en/latest/#f2
[8]: https://cloud.spring.io/spring-cloud-static/spring-cloud-security/2.1.3.RELEASE/single/spring-cloud-security.html#_token_relay
[9]: https://github.com/spring-cloud-samples/sample-gateway-oauth2login
[10]: https://jose.readthedocs.io/en/latest/
[11]: https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/#boot-features-security-oauth2
[12]: https://oauth.net/2/
[13]: https://spring.io/projects/spring-cloud-security