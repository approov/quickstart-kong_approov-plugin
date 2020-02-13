#!/bin/sh

set -eu

Show_Help() {
    cat <<EOF

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

destroy     Does the same as \`down\`, and also removes the associated docker volume.
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

EOF
}

Print_Message() {
    printf "\n---> ${1}\n"
}

Print_Error() {
    printf "\n---> ERROR: ${1} <---\n"
}

Docker_Container_Is_Running() {
  sudo docker container ls -a | grep -w "${1}" - | grep -qw Up -
  return $?
}

Docker_Container_Is_Stopped() {
  sudo docker container ls -a | grep -w "${1}" - | grep -qw Exited -
  return $?
}

Docker_Compose() {
    sudo docker-compose \
        --project-name "${PROJECT_NAME}" \
        --file "${DOCKER_COMPOSE_FILE}" \
        ${@}
}

Kong_Up() {

    if Docker_Container_Is_Running "${PROJECT_NAME}_kong_1"; then
        return
    fi

    Docker_Compose up --detach

    # Give time for the database to start and run the migrations.
    sleep 5
}

Kong_Down() {
    Docker_Compose down
}

Kong_Destroy() {
    Kong_Down
    sudo docker volume rm "${PROJECT_NAME}_kong_data"
}

Kong_Status() {
    printf "\nSERVICES STATUS:\n"
    Docker_Compose ps

    printf "\nVOLUME STATUS:\n"
    sudo docker volume ls | grep -i "${PROJECT_NAME}" -

    printf "\nNETWORK STATUS:\n"
    sudo docker network ls | grep -i "${PROJECT_NAME}" -

    echo
}

Main() {


    ############################################################################
    # SETUP
    ############################################################################

        # Docker compose uses this to prefix the names for services, networks, volumes, etc.
        local PROJECT_NAME=kong-approov

        if [ -f  ./.bash.vars ]; then
            . ./.bash.vars
        fi

        if [ -f  ./.bash.vars.local ]; then
            . ./.bash.vars.local
        fi

        if [ ! -f  ./.env ] && [ -f ./.env.example ]; then
            cp ./.env.example .env
        fi

        if [ -f  ./.env ]; then
            . ./.env
        fi

        local DOCKER_COMPOSE_FILE=./docker/kong-api-gateway/docker-compose.yml


    ############################################################################
    # INPUT
    ############################################################################

        for input in  in "${@}"; do
            case "${input}" in

                --project-name )
                    PROJECT_NAME="${2? Missing project name.}"
                ;;

                demo )
                    Kong_Up
                    ./kong-admin approov:demo-setup
                    exit $?
                ;;

                destroy )
                    Kong_Destroy
                    exit $?
                ;;

                down )
                    Kong_Down
                    exit $?
                ;;

                help | -h | --help )
                    Show_Help
                    exit 0
                ;;

                logs )
                    Docker_Compose logs --follow ${2:-}
                    exit $?
                ;;

                logs-find )
                    Docker_Compose logs ${3:-} | grep -in "${2}" -
                    exit $?
                ;;

                quick-start )
                    Kong_Up
                    ./kong-admin approov:quick-start
                    exit $?
                ;;

                shell )
                    Kong_Up
                    Docker_Compose exec kong sh
                    exit 0
                ;;

                status )
                    Kong_Status
                    exit 0
                ;;

                up )
                    Kong_Up
                    exit $?
                ;;
            esac
        done

        Show_Help
}

Main $@
