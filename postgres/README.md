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

```
## start container
docker-compose up -d

## install psql clinent
sudo apt install postgresql-client

## check that it is online
psql -h localhost -U postgres -c "SELECT version();"
```

## make user paul
```
CREATE USER paul WITH PASSWORD 'xxxx' CREATEDB;
```

## modify pg_hba.conf in /var/lib/postgresql/data/ to disallow superuser with remote access
```
# TYPE  DATABASE        USER            ADDRESS                 METHOD
host all paul 172.20.0.1/16 scram-sha-256
local all all  scram-sha-256
```

## make ssh tunnel with: 
```
ssh -L 5432:localhost:5432 strato_development_paul
```

obviously, here strato_development_paul is only shorthand and you need to make sure your .ssh/config contains the respective keys and configurations for accessing the remote server. e.g. in my case: 

```
Host strato_development_paul
  HostName 85.215.42.232
  User paul
  Port 20202
```
