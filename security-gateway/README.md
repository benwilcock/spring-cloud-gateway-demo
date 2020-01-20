
## Getting up and Running...

````bash
./build.sh
docker-compose up
````

In an INCOGNITO or PRIVATE browser window...

[http://localhost:8080/resource](http://localhost:8080/resource)

You'll be asked to login, use Username: `user1` and Password: `password`.

> These credentials are configured in the `[uaa/uaa.yml](uaa/uaa.yml)` file.

You'll be asked to Authorise that the resource-server is allowed to read your profile and check your scopes. 
Click "Authorise" to allow this. You'll then be redirected to your original destination and the resource server 
will print out your Subject's identity GUID.

> Resource was accessed by a584b8b8-eaf2-4280-b9c3-12f65cf8524b (sub)


## Cleaning Up

When you're done use `Ctrl-C` to stop the containers, `docker-compose rm -f` to remove leftovers.

## Want to go again? 

Probably have to clear your cookies and restart the Docker bits... 
