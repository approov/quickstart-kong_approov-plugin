#!/bin/sh

set -eu

Show_Help() {
    cat <<EOF

A bash script to wrap repetitive tasks in the Kong Admin API.

---> MUST BE USED FROM THE ROOT OF THE PROJECT <---

SIGNATURE:

./kong [options] <command> [arguments]

COMMANDS:

approov:demo-setup                           Configures the Approov demo in one go.
                                             $ ./kong-admin consumer:new shapes-mobile-app

consumer:new                                 Creates a new consumer.
                                             $ ./kong-admin consumer:new shapes-mobile-app

consumer:add-base64url-secret                Adds the base64url safe encoded secret.
                                             $ ./kong-admin consumer:add-base64url-secret <consumer-name> <key-id-for-the-secret>
                                             $ ./kong-admin consumer:add-base64url-secret shapes-mobile-app approov

service:new                                  Creates a new Kong service.
                                             $ ./kong-admin <service-name> <url-to-forward-requests>
                                             $ ./kong-admin service:new approov-token https://example.com

service:add-route-by-path                    Adds a route to the service for the given path.
                                             $ ./kong-admin <service-name> <domain-service-is-listening-on> <route-path>
                                             $ ./kong-admin service:add-route-by-path approov-token domain.com /v1/shapes

service:add-all-routes                       Adds all routes to the service.
                                             $ ./kong-admin <service-name> <domain-service-is-listening-on>
                                             $ ./kong-admin service:add-route-by-path approov-token domain.com

service:enable-jwt-plugin                    Enables the Kong JWT plugin for the given service.
                                             $ ./kong-admin service:enable-jwt-plugin <service-name>
                                             $ ./kong-admin service:enable-jwt-plugin approov-token

service:enable-approov-token-binding-plugin  Enables and configures the plugin to check the Approov Token Binding.
                                             $ ./kong-admin service:enable-approov-token-binding-plugin <service-name>
                                             $ ./kong-admin service:enable-approov-token-binding-plugin approov-token-binding

EOF
}

Print_Message() {
    printf "\n---> ${1}\n"
}

Print_Error() {
    printf "\n---> ERROR: ${1} <---\n\n"
}

Approov_QuickStart_Setup() {

    local _consumer_name="quick-start-app"
    local _service_name="quick-start-api"
    local _approov_jwt_header_kid="quick-start-secret-kid"

    #################################
    # CONSUMER: NEW CONSUMER SETUP
    #################################

    Print_Message "CONSUMER: ADD A NEW CONSUMER"
    Consumer_New "${_consumer_name}"


    ###########################
    # SERVICE: APPROOV TOKEN
    ###########################

    Print_Message "SERVICE: PROTECTED BY APPROOV TOKEN"
    Service_New \
        "${_service_name}" \
        "${KONG_PROXY_FORWARD_TO_HOST}"
    echo

    Print_Message "SERVICE: ADD ALL ROUTES"
    Service_Add_All_Routes \
        "${_service_name}" \
        "${KONG_SERVICE_HOST}"
    echo
}

Approov_Demo_Setup() {

    #################################
    # CONSUMER: NEW CONSUMER SETUP
    #################################

    Print_Message "CONSUMER: ADD A NEW CONSUMER"
    Consumer_New "${KONG_CONSUMER_NAME}"
    echo

    Print_Message "CONSUMER: ADD A BASE64 URL SECRET"
    Consumer_Add_Secret \
        "${KONG_CONSUMER_NAME}" \
        "${APPROOV_JWT_HEADER_KID}"
    echo


    ##############################
    # SERVICE: NO APPROOV TOKEN
    ##############################

    Print_Message "SERVICE: NOT PROTECTED BY APPROOV TOKEN"
    Service_New \
        "${KONG_SERVICE_NAME}_not-protected" \
        "${KONG_PROXY_FORWARD_TO_HOST}"
    echo

    Print_Message "SERVICE: ADD ROUTE FOR V1/HELLO"
    Service_Add_Route_By_Path \
        "${KONG_SERVICE_NAME}_not-protected" \
        "${KONG_SERVICE_HOST}" \
        "/v1/hello"
    echo


    ###########################
    # SERVICE: APPROOV TOKEN
    ###########################

    Print_Message "SERVICE: PROTECTED BY APPROOV TOKEN"
    Service_New \
        "${KONG_SERVICE_NAME}" \
        "${KONG_PROXY_FORWARD_TO_HOST}"
    echo

    Print_Message "SERVICE: ADD ROUTE FOR V1/SHAPES"
    Service_Add_Route_By_Path \
        "${KONG_SERVICE_NAME}" \
        "${KONG_SERVICE_HOST}" \
        "/v1/shapes"
    echo

    Print_Message "SERVICE: ENABLE JWT PLUGIN FOR V1/SHAPES"
    Service_Enable_JWT_Plugin \
        "${KONG_SERVICE_NAME}"
    echo


    ###################################
    # SERVICE: APPROOV TOKEN BINDING
    ###################################

    Print_Message "SERVICE: ADD A NEW KONG SERVICE FOR V1/FORMS"
    Service_New \
        "${KONG_SERVICE_NAME}-binding" \
        "${KONG_PROXY_FORWARD_TO_HOST}"
    echo

    Print_Message "SERVICE: ADD ROUTE FOR V1/FORMS"
    Service_Add_Route_By_Path \
        "${KONG_SERVICE_NAME}-binding" \
        "${KONG_SERVICE_HOST}" \
        "/v1/forms"
    echo

    Print_Message "SERVICE: ENABLE JWT PLUGIN FOR V1/FORMS"
    Service_Enable_JWT_Plugin \
        "${KONG_SERVICE_NAME}-binding"
    echo

    Print_Message "SERVICE: ENABLE APPROOV TOKEN BINDING PLUGIN FOR V1/FORMS"
    Service_Enable_Approov_Token_Binding_Plugin \
        "${KONG_SERVICE_NAME}-binding"
    echo
}

Consumer_New() {
    local _consumer_name="${1? Missing the name for Kong consumer.}"

    curl -i -X POST \
      --url "${KONG_ADMIN_API_URL}"/consumers/ \
      --data username="${_consumer_name}"
}

Consumer_Add_Secret() {
    local _consumer_name="${1? Missing the name for the Kong consumer.}"
    local _secret_kid_value="${2? Missing the name for the 'kid' in the Approov JWT Header.}"

    curl -i -X POST \
        --url http://localhost:8001/consumers/"${_consumer_name}"/jwt \
        --header "Content-Type: application/x-www-form-urlencoded" \
        --data algorithm="HS256" \
        --data key="${_secret_kid_value}" \
        --data secret="${APPROOV_BASE64URL_SECRET? Missing the Approov Secret in the .env file.}"
}

Service_New() {
    local _kong_service_name="${1? Missing Kong service name.}"
    local _kong_proxy_to_url="${2? Missing url for where to proxy the requests.}"

    curl -i -X POST \
      --url "${KONG_ADMIN_API_URL}"/services/ \
      --data name="${_kong_service_name}" \
      --data url="${_kong_proxy_to_url}"
}

Service_Add_All_Routes() {
    local _kong_service_name="${1? Missing Kong service name.}"
    local _kong_service_host="${2? Missing Kong service host.}"

    curl -i -X POST \
      --url "${KONG_ADMIN_API_URL}"/services/"${_kong_service_name}"/routes \
      --data "hosts[]=${_kong_service_host}"
}

Service_Add_Route_By_Path() {
    local _kong_service_name="${1? Missing Kong service name.}"
    local _kong_service_host="${2? Missing Kong service host.}"
    local _kong_route_path="${3? Missing Kong route path.}"

    curl -i -X POST \
      --url "${KONG_ADMIN_API_URL}"/services/"${_kong_service_name}"/routes \
      --data "hosts[]=${_kong_service_host}" \
      --data "paths[]=${_kong_route_path}" \
      --data strip_path=false
}

Service_Enable_JWT_Plugin() {

    local _kong_service_name="${1? Missing Kong service name.}"

    curl -i -X POST \
        --url "${KONG_ADMIN_API_URL}"/services/"${_kong_service_name}"/plugins \
        --data "name=jwt" \
        --data "config.header_names=Approov-Token" \
        --data "config.claims_to_verify=exp" \
        --data "config.key_claim_name=kid" \
        --data "config.secret_is_base64=true"
}

Service_Enable_Approov_Token_Binding_Plugin() {

    local _kong_service_name="${1? Missing Kong service name.}"

    curl -i -X POST \
        --url "${KONG_ADMIN_API_URL}"/services/"${_kong_service_name}"/plugins \
        --data "name=approov-token-binding" \
        --data "config.token_binding_header_name=Authorization"
}

Main() {

    ############################################################################
    # SETUP
    ############################################################################

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


    ############################################################################
    # INPUT
    ############################################################################

        for input in  in "${@}"; do
            case "${input}" in

                approov:demo-setup )
                    shift 1
                    Approov_Demo_Setup
                    exit $?
                ;;

                approov:quick-start )
                    shift 1
                    Approov_QuickStart_Setup
                    exit $?
                ;;

                consumer:new )
                    shift 1
                    Consumer_New ${@}
                    exit $?
                ;;

                consumer:add-base64url-secret )
                    shift 1
                    Consumer_Add_Secret ${@}
                    exit $?
                ;;

                service:new )
                    shift 1
                    Service_New ${@}
                    exit $?
                ;;

                service:add-route-by-path )
                    shift 1
                    Service_Add_Route_By_Path ${@}
                    exit $?
                ;;

                service:add-all-routes )
                    shift 1
                    Service_Add_All_Routes ${@}
                    exit $?
                ;;

                service:enable-jwt-plugin )
                    shift 1
                    Service_Enable_JWT_Plugin ${@}
                    exit $?
                ;;

                service:enable-approov-token-binding-plugin )
                    shift 1
                    Service_Enable_Approov_Token_Binding_Plugin ${@}
                    exit $?
                ;;

                help | -h | --help )
                    Show_Help
                    exit 0
                ;;
            esac
        done

        Show_Help
}

Main ${@}
