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

For this, you need to write the following files: 
- postgres_user.secret --> put the superuser name, usually this is "postgres"
- postgres_password.secret --> put the password for the superuser
- filla_db_user.secret --> make a new personal user name that you plan on using in the future
- filla_db_password.secret --> set a password for your personal user
- filla_db_database.secret --> set the name of the personal database you want to use in the future

These files are part of the .gitignore, so that you dont accidentally commit them to a public git repo. 

We also implement some very basic security measures. When users are connecting remotely, they should not be able to login to the superuser. Hence, modify pg_hba.conf to disallow superuser with remote access. The user name here needs to match the username you specified in filla_db_user and the database could either be all or even better the one you specified in filla_db_database. 

This basically says: 
- host: A remote connection
- all: has access to all databases
- paul: if it is user paul
- 172.0.0.0/8: and comes from ip-ranges 172.0.0.0-172.255.255.255, (because docker lives here)
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
psql -h localhost -U postgres postgres -c "SELECT version();"
```

Now it should be up and running and everything should be configured. If we are on the server, it is locally available on port 5432. 

Howver, usually we work on swp-r3 and want to access it remotely, hence we set up an ssh-tunnel like so: 
```
ssh -L 5432:localhost:5432 strato_development_paul
```

Obviously, here strato_development_paul is only shorthand and you need to make sure your .ssh/config contains the respective keys and configurations for accessing the remote server. e.g. in my case: 

```
Host strato_development_paul
  HostName 85.215.42.232
  User paul
  Port 20202
```

In R, you can now do: 

```
con <- DBI::dbConnect(RPostgres::Postgres(),dbname = 'database', host = "localhost", port = "5432", user = "the_user_you _sepcified_in_filla", password = "the_password_you_specified_in_filla")
```

