## Creating stuff

### Creating a Greeting service that includes Eureka Discovery Client:

```bash
http https://start.spring.io/starter.zip dependencies==web,actuator,cloud-eureka baseDir==service name==service applicationName==Service groupId==com.scg artifactId==service | tar -xzvf -
```

For the code, follow the tutorial [here][2] which adds the `/greeting` REST endpoint to the service.

### Creating a Eureka Discovery Server

```bash
http https://start.spring.io/starter.zip dependencies==cloud-eureka-server baseDir==registry name==registry applicationName==registry groupId==com.scg artifactId==registry javaVersion==11 | tar -xzvf -
```

Add `@EnableEurekaServer` annotation to the `Application.java` class.
> **Tip:** Using Java 11? Add the missing JAXB dependencies to the `pom.xml` file before packaging.

### Creating a Gateway

## Running stuff

```bash
docker run --rm -p 8080:9092 -d benwilcock/scg-demo-service
```

## Building images

For fun, we thought we'd try out "Cloud Native Buildpacks" which can generate sophisticated Docker images with very 
little fuss using Docker Community Editition and the `pack` command line. 

> The instructions for installing Docker Community Edition and Pack can be found [here][1]. Pack is available for 
Mac OS X, Linux and Windows. You'll need docker running on your PC in order to create and run Docker images

To use `pack` manually, you simply open a command line in the directory containing your Spring application and then issue 
the command `pack build <your-image-name>`. The convention is to use your Docker username followed by a `/` and then
the name of the image you're creating (e.g. benwilcock/gateway).

If you want to go quickly, you can skip this step. The images used for the `docker compose` have been uploaded to 
Docker Hub already.

```bash
cd <code-dir>
pack build benwilcock/gateway
```


[1]: https://buildpacks.io/docs/app-journey/
[2]: https://spring.io/guides/gs/rest-service/
