## Mongo

Docker Hub: https://hub.docker.com/_/mongo/
Default Port: 27017

```
docker run --name some-mongo-6 -p 27018:27017 -d mongo:6
```

Once your container is up and running you can use the following connection string to access it
```
mongodb://localhost:27017/workflowtest
```

Note: Run as shown above, the local mongo container will not require authentication.  This can be configured, read the docs!



## MySQL

Docker Hub: https://hub.docker.com/_/mysql/
Default Port: 3306

```
docker run --name some-mysql -p 3307:3306 -e MYSQL_ROOT_PASSWORD=MySqlPassword -d mysql:8.0.33
```

Once your container is up and running you can use the following connection information to access it
```
host: 127.0.0.1
username: root
password: MySqlPassword
```
