## Mongo

Docker Hub: https://hub.docker.com/_/mongo/
Default Port: 27017

```
docker run --name some-mongo-6 -p 27018:27017 -d mongo:6

docker run --name mongo-7 -p 27017:27017 -d mongo:7 --replSet rs0
docker exec mongo-7 mongosh --eval "rs.initiate({ _id: 'rs0', members: [ { _id: 0, host: 'localhost:27017' } ] })"
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



## LocalStack

```
# docker run --rm -it -p 4566:4566 -p 4510-4559:4510-4559 -e EXTRA_CORS_ALLOWED_ORIGINS=https://app.localstack.cloud. localstack/localstack:1.3.1

docker run --rm -it -p 4566:4566 -p 4510-4559:4510-4559 -e EXTRA_CORS_ALLOWED_ORIGINS=https://app.localstack.cloud. localstack/localstack:3.7.1
```