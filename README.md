## Setting up a remote postgres database

First, we need to make sure we can run the docker command after installing docker. 
```
## set my user to docker group so it can access docker socket
sudo usermod -aG docker paul
newgrp docker

## reboot to make group change valid
sudo reboot 
```

Now we need to make sure that we know what kind of database we are creating. The superuser needs to be set, as well as all the password and extra databases. 

Usually we set one superuser and then configure additional users who have less privileges. 

- ./postgres_user.secret --> put the superuser name, usually this is "postgres"
- ./postgres_password.secret --> put the password for the superuser
-  ./filla_db_user.secret --> make a new personal user name that you plan on using in the future
- ./filla_db_password.secret --> set a password for your personal user
- ./filla_db_database.secret --> set the name of the personal database you want to use in the future


We also implement some very basic security measures. When users are connecting remotely, they should not be able to login to the superuser. Hence, modify pg_hba.conf to disallow superuser with remote access. The user name here needs to match the username you specified in filla_db_user and the database could either be all or even better the one you specified in filla_db_database. 

This basically says: 
- host: A remote connection
- all: has access to all databases
- paul: if it is user paul
- 172.0.0.0/8: and comes from ip-ranges 172.0.0.0-172.255.255.255, (because docker lives somewhere here)
- scram-sha-256: if it provides a password

The full sentence is: A remote connection has access to all databases if it is user paul and comes from ip-ranges 172.0.0.0-172.255.255.255, (because docker lives here) if it provides a password.

The line starting with local basically says that a local connection can be used with any user, if the password is provided. So here we can also login with the superuser. 
```
# TYPE  DATABASE        USER            ADDRESS                 METHOD
host all paul 172.20.0.1/16 scram-sha-256
local all all  scram-sha-256
```



```
## start container
docker-compose up -d

## install psql clinent
sudo apt install postgresql-client


## check that it is online
psql -U postgres postgres -c "SELECT version();"

## this should fail, because we only allow connections to postgres from local with:
> connection to server at "localhost" (127.0.0.1), port 5432 failed: FATAL:  no pg_hba.conf entry for host "1

## connect into docker container (check docker ps for ids of containers)
docker exec -it eea67d609b0_your_docker_id_53313a6 bash 

## run again
psql -U postgres postgres -c "SELECT version();"

## this should prompt for your password and connect

## now check from the terminal of your computer where the database is running if you can access your user database
psql -h localhost -U your_filla_db_username your_filla_db_database -c "SELECT version();"
```

Now it should be up and running and everything should be configured. If we are on the server, it is locally available on port 5432. 

However, the whole point was to have this accesible on a remote server, hence we set up an ssh-tunnel like so: 
```
ssh -L 5432:localhost:5432 server_name_configured_in_ssh_config
```

Obviously, here server_name_configured_in_ssh_config is only shorthand and you need to make sure your .ssh/config contains the respective keys and configurations for accessing the remote server. e.g. in my case: 

```
Host server_name_configured_in_ssh_config
  HostName 75.63.34.xxx
  User some_user
  Port some_port
```

In R, you can now do: 

```
con <- DBI::dbConnect(RPostgres::Postgres(),
  dbname = 'database', 
  host = "localhost", 
  port = "5432", 
  user = "the_user_you _sepcified_in_filla", 
  password = "the_password_you_specified_in_filla")
```

