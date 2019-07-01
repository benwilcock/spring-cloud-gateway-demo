# Introduction

* [Ben Wilcock][1] – Spring Marketing, Pivotal.
* [Brian McClain][2] – Technical Marketing, Pivotal.

Microservice architectures are great, but as your application programming interfaces (APIs) start to grow, so do the challenges related to their maintenance. 

For example, as an existing API matures and adds new features it will need to take its clients along with it on the journey. When the details of an API change, clients need to adjust in order to work with these changes. This process takes time and can really slow your APIs evolution and interfere with your ability to iterate quickly. 

Offering multiple APIs can help but brings with it its own set of challenges. How do you route requests and responses to the correct API? How do you manage any message disparity? How do you support clients when your endpoints can move around? 

And then there’s the question of integrating with legacy systems. Not everyone is so lucky that they get to build apps and services into an entirely new ecosystem, instead needing to play nicely with preexisting systems for things like authentication and other backing services. 

An API Gateway helps you to solve these problems and more. It is a powerful architectural tool which you can use to manage message routing, filtering and proxying in your microservice architecture. Many API Management platforms can be dated back to SOA and these tend to have been implemented as centralized servers. But as microservices became more popular, modern lightweight independent and decentralized micro-api-gateway applications have appeared – such as [Spring Cloud Gateway][3].  

What follows is a series of articles by [Ben Wilcock][1] and [Brian McClain][2] of Pivotal on [Spring Cloud Gateway][3]. This series is designed to introduce you to Spring Cloud Gateway and show you some simple but popular use cases.

To follow along with these tutorials, you might benefit from these tools...

* Your favorite command line (e.g zsh, bash, DOS command or PowerShell)
* [HTTPie][4] – a command line client for http calls 
* Your favorite Java IDE (check out [Spring Tools][5] if you don’t have one)

## Episode 1: Getting Started With Spring Cloud Gateway

In this first article [Getting Started with Spring Cloud Gateway][6] we begin by constructing a simple gateway project which handles the re-routing of a HTTP request whilst adding headers to it.

## Episode 2: Service Hiding & Runtime Discovery

In this second installment we look at [Service Hiding & Runtime Discovery][8]. We construct a hidden network of services using Docker and then create a Spring Cloud Gateway reverse-proxy to police our network boundary and facilitate access to these hidden services. As part of the demo, we also illustrate how Spring Cloud Eureka Server can allow the discovery of services at runtime.

----

[License][7]


[1]: https://twitter.com/benbravo73
[2]: https://twitter.com/BrianMMcClain
[3]: https://spring.io/projects/spring-cloud-gateway
[4]: https://httpie.org/
[5]: https://spring.io/tools
[6]: getting_started.md
[7]: LICENSE
[8]: runtime-discovery-and-service-hiding.md