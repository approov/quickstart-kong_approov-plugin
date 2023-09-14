# KONG ADMIN API - STEP BY STEP

This step by step guide runs on top of the [Kong Docker Stack](/docs/KONG_DOCKER_STACK.md).

We will see how the Kong Admin API was used under the hood in this [Approov Demo](/docs/APPROOV_KONG_PLUGIN_DEMO).

To setup Kong to check the Approov Tokens, we will need to create a Kong consumer and two Kong services, one for the Approov Token, and another one for the Approov Token Binding, and enable their respective plugins.

## PREREQUISITES

### Kong Docker Stack

Before you start please ensure the Kong Docker Stack is up and running:

```
./kong up
```

### Approov Secret

Please follow [these instructions](/docs/APPROOV_SECRET.md#the-dummy-secret) to set it up.

## HELP

##### command:

```
./kong-admin help
```

##### output:

```
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
```

## KONG CONSUMER

In order to add the security layer for the Approov Token Service we need to create a consumer for it which will hold the secret to be used later by the Kong JWT plugin to verify the signature for the `Approov-Token`.

### Creating a new Kong Consumer

#### Command signature

```
./kong-admin consumer:new <consumer-name>
```

#### Command example

```
./kong-admin consumer:new shapes-mobile-app
```

We can confirm that the consumer application was added by visiting http://localhost:8001/consumers.


### Adding to the Consumer the secret to check the Approov Token

#### Command signature

```
./kong-admin consumer:add-base64url-secret <consumer-name> <key-id-for-the-secret>
```

#### Command example

```
./kong-admin consumer:add-base64url-secret \
    shapes-mobile-app \
    approov
```

To confirm the Approov Secret was added as the JWT credential we can visit http://localhost:8001/consumers/shapes-mobile-app/jwt.


## KONG SERVICE FOR THE APPROOV TOKEN

In order to check the Approov token we will need to create a Kong service, add routes to it, enable the Kong JWT plugin to validate the `Approov-Token`, and finally we will need to add the `shapes-mobile-app` consumer to this service.

### Creating the Approov Token Service

#### Command signature

```
./kong-admin <service-name> <url-to-forward-requests>
```

#### Command example

```
./kong-admin service:new \
    approov-token \
    https://shapes.demo.approov.io
```

We can now visit http://localhost:8001/services/ to confirm the response for the above command.

### Adding Routes to the Approov Token Service

#### Command signature

```
./kong-admin <service-name> <domain-service-is-listening-on> <route-path>
```

#### Command example

```
./kong-admin service:add-route-by-path \
    approov-token \
    localhost \
    /v1/shapes
```

We can confirm the response for the request by visiting http://localhost:8001/services/approov-token/routes.

>**NOTE**: To  match all routes `/*`:
>
>```
>./kong-admin service:add-all-routes \
>   approov-token \
>   localhost
>```


### Smoke Testing the Approov Token Service

To test the service we will send a request to the Kong API Gateway which will be proxied to the backend based on the `Host` header provided in the request.

##### request:

```
curl -i -X GET --url http://localhost:8000/v1/shapes
```

##### response body:

```json
{"shape": "Triangle"}
```

Now that we know Kong is forwarding correctly our requests, it's time to add the security layer.


### Enabling the Kong JWT plugin for the Approov Token service

The Approov Token service was created to match all routes for `/v1/shapes/*`, therefore any matching request will be checked for the existence of an `Approov-Token` which is correctly signed and has not expired. On a successful check the request will be forwarded and if it fails the request is immediately terminated.

#### Command signature

```
./kong-admin service:enable-jwt-plugin <service-name>
```

#### Command example

```
./kong-admin service:enable-jwt-plugin approov-token
```
We can visit http://localhost:8001/services/approov-token/plugins to confirm the above response.


## KONG SERVICE FOR THE APPROOV TOKEN BINDING

This will be very similar to what we have done for the Approov Token Service, therefore I will give the sequence of commands without explaining them, except when we do something extra.

### Creating the Approov Token Binding Service

```
./kong-admin service:new \
    approov-token-binding \
    https://shapes.demo.approov.io
```

### Adding Routes to the Approov Token Binding Service

```
./kong-admin service:add-route-by-path \
    approov-token-binding \
    localhost \
    /v1/forms
```

### Enabling the Kong JWT plugin for the Approov Token Binding Service

```
./kong-admin service:enable-jwt-plugin approov-token-binding
```

### Enabling the Approov Token Binding Plugin

This plugin will ensure that we have a valid token binding.

This Approov Demo is configured to bind the `Authorization` token with the `Approov-Token`.

So in order to have a valid token binding, the SHA256 hash of the base64 string for the `Authorization` token must match with the value in the `pay` claim for the `Approov-Token`.

In other words we are binding **who** is in the request with **what** made the request.

#### Command signature

```
./kong-admin service:enable-approov-token-binding-plugin <service-name>
```

#### Command example

```
./kong-admin service:enable-approov-token-binding-plugin approov-token-binding
```
We can visit http://localhost:8001/services/approov-token-binding/plugins to confirm the above response.
