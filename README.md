# spring-cloud-gateway-demo

To build: `./mvnw install`

To run: `./mvnw spring-boot:run`

To test (with httpie):

````bash
http localhost:8080/get
````

Sould obtain the response: 

````bash
HTTP/1.1 200 OK
Access-Control-Allow-Credentials: true
Access-Control-Allow-Origin: *
Content-Encoding: gzip
Content-Length: 255
Content-Type: application/json
Date: Tue, 04 Jun 2019 15:31:54 GMT
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
        "Forwarded": "proto=http;host=\"localhost:8080\";for=\"0:0:0:0:0:0:0:1:59216\"",
        "Hello": "World",
        "Host": "httpbin.org",
        "User-Agent": "HTTPie/1.0.2",
        "X-Forwarded-Host": "localhost:8080"
    },
    "origin": "0:0:0:0:0:0:0:1, 2.102.146.151, ::1",
    "url": "https://localhost:8080/get"
}
````

> Note: A custom HTTP Header named "Hello" has been added during processing with the value "world".
