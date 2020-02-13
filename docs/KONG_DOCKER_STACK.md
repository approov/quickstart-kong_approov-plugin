# KONG DOCKER STACK

This stack is based on the docker compose template from the official Kong repository at this [commit](https://github.com/Kong/docker-kong/tree/f48b8a5b8dcae8c4ef59f7bb9adaf15619a302df/compose).

## HOW TO USE

### Help

##### command:

```
./kong help
```

##### output:

```
A bash script to wrap the Docker stack for the Kong API Gateway.

---> MUST BE USED FROM THE ROOT OF THE PROJECT <---

SIGNATURE:

./kong [options] <command> [arguments]

OPTIONS:

--project-name  Sets the project to be used by docker compose.
                $ ./kong --project-name <project-name-here> <command> [arguments]
                $ ./kong --project-name approov up

COMMANDS:

demo        Starts the Kong Docker Stack and configures Kong for the demo.
            $ ./kong demo

destroy     Does the same as `down`, and also removes the associated docker volume.
            $ ./kong destroy

down        Stops and removes the services for Kong and the Database.
            $ ./kong down

logs        Tails the logs for all services or just for the given one.
            $ ./kong logs
            $ ./kong logs kong
            $ ./kong logs db

logs-find   Find all ocurrences of a string in the logs for a specific service.
            $ ./kong logs <service> <word to find>
            $ ./kong logs kong approov

shell       Gives a bash shell inside the Docker container for the Kong service.
            $ ./kong shell

status      Shows the status for the services, volume and network.
            $ ./kong status

up          Starts Kong and the Databas\e services in Docker containers.
            $ ./kong up
```


### Kong Up

This will bring up the Kong API Gateway with the Admin interface, backed by a Postgres database.

#### command

```
./kong up
```

##### output:

```
Creating network "kong-approov_kong-net" with the default driver
Creating volume "kong-approov_kong_data" with default driver
Creating kong-approov_db_1 ... done
Creating kong-approov_kong_1               ... done
Creating kong-approov_kong-migrations-up_1 ... done
Creating kong-approov_kong-migrations_1    ... done
```

Visit http://localhost:8000/ to ensure the API Gateway is up, and visit http://localhost:8001/ to ensure the Kong Admin API is reachable.

### Kong Down

This will remove all docker containers and networks.

##### command:

```
./kong down
```

##### output:

```
Stopping kong-approov_kong_1 ... done
Stopping kong-approov_db_1   ... done
Removing kong-approov_kong-migrations_1    ... done
Removing kong-approov_kong-migrations-up_1 ... done
Removing kong-approov_kong_1               ... done
Removing kong-approov_db_1                 ... done
Removing network kong-approov_kong-net
```

### Kong Destroy - Reset Kong and Database

The database is persisted in the docker volume `kong-approov_kong_data`, therefore if we want to reset the state we need to destroy the docker stack for Kong.

This will call `Kong Down` to stop and remove the Docker containers, and will also remove the docker volume.

##### command:

```
./kong destroy
```

##### output when Kong is up and running:

```
Stopping kong-approov_kong_1 ... done
Stopping kong-approov_db_1   ... done
Removing kong-approov_kong-migrations_1    ... done
Removing kong-approov_kong-migrations-up_1 ... done
Removing kong-approov_kong_1               ... done
Removing kong-approov_db_1                 ... done
Removing network kong-approov_kong-net
kong-approov_kong_data
```

##### output when Kong is already down:

```
Removing network kong-approov_kong-net
WARNING: Network kong-approov_kong-net not found.
kong-approov_kong_data
```
