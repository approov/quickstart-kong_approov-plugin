# KONG ADMIN API - DEEP DIVE

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

Please follow [this instructions](/docs/APPROOV_SECRET.md#the-dummy-secret) to set it up.


## KONG CONSUMER

In order to add the security layer for the Approov Token Service we need to create a consumer for it which will hold the secret to be used later by the Kong JWT plugin to verify the signature of the `Approov-Token`.

### Creating a new Kong Consumer

The option `--data username=shapes-mobile-app` sets the user name for the consumer, and you can use whatever string identifier you want here, for example the name for your mobile app project. This string identifier will be used later on in the urls for the consumer, when querying the Kong Admin API.

##### request:

```
curl -i -X POST \
  --url localhost:8001/consumers/ \
  --data username=shapes-mobile-app
```

We can confirm that the consumer application was added by visiting http://localhost:8001/consumers.


### Adding to the Consumer the secret to check the Approov Token

The parameter `algorithm` in `--data algorithm="HS256"` sets `HS256` as the algorithm to be used when the Kong JWT plugin validates the JWT token.

The parameter `secret` will be be stored as a key value pair, thus the parameter `key` in `--data key=approov` sets `approov` to be used as the key name where we want to store the value from the environment variable `APPROOV_BASE64URL_SECRET`.

> **NOTE**: When providing a base64 encoded secret we need to have the service configured to accept it with `config.secret_is_base64=true`. Check it at http://localhost:8001/consumers/shapes-mobile-app/jwt.

The `approov` key name will then be used as a value for the key `kid` in all JWT token headers we want to validate with this consumer secret, otherwise Kong will not know what secret to use to validate the JWT and the validation will fail.

```json
{
  "typ": "JWT",
  "alg": "HS256",
  "kid": "approov"
}
```

##### request:

```
output=$(source .env && curl -i -X POST \
    --url http://localhost:8001/consumers/shapes-mobile-app/jwt \
    --header "Content-Type: application/x-www-form-urlencoded" \
    --data algorithm="HS256" \
    --data key=approov \
    --data secret="${APPROOV_BASE64URL_SECRET? Missing the Approov Secret in the .env file.}") && echo $output
```

> **NOTE**: It's not a good practice to enter sensitive data in a shell, because it will be kept in the shell history, therefore the command was executed in a sub shell `output=$(command_to_run) && echo output`.

To confirm the Approov Secret was added as the JWT credential we can visit http://localhost:8001/consumers/shapes-mobile-app/jwt.


## KONG SERVICE FOR THE APPROOV TOKEN

In order to check for the Approov token we will need to create a Kong service, add routes to it, enable the Kong JWT plugin to validate the `Approov-Token`, and finally we will need to add the `approov-token` consumer to this service.

### Creating the Approov Token Service

The parameter `name` in `--data 'name=approov-token'` is used to set the name for the service to `approov-token`, but you are free to choose whatever you like.

The parameter `url` in `--data url=https://shapes.demo.approov.io`  is used to set the url for the Third Party API or backend where we want to proxy the requests. So in this case the url `https://shapes.demo.approov.io` is the Third Party API that we want to proxy the requests to, and protect the access with an Approov Token.

##### request:

```
curl -i -X POST \
  --url http://localhost:8001/services/ \
  --data name=approov-token \
  --data url=https://shapes.demo.approov.io
```

Visit http://localhost:8001/services/ to confirm the response.

### Adding Routes to the Approov Token Service

The parameter `hosts[]` in `--data 'hosts[]=localhost'` is an array of hosts where the `approov-token` service is listening for requests to proxy to the Third Party API or backend. So here we are defining `localhost`, but in production you will add the domains that you want your Reverse Proxy to be listening to.

The parameter `paths[]` in `--data 'paths[]=/v1/shapes'` is an array of routes/endpoints you want your Reverse Proxy to be listening to. So here we only want to be listening for any request for `/v1/shapes/*`, thus requests for other routes will not be processed by the `approov-token` service.

The parameter `strip_path` in `--data strip_path=false` disables removing the path we are matching from the request we proxy. So if we receive a request to `proxy.example.com/v1/shapes` we will keep `/v1/shapes` when forwarding it to the api, like `api.example.com/v1/shapes`, otherwise it would strip it, and the forwarded request would be `api.example.com`.

##### request:

```
curl -i -X POST \
  --url http://localhost:8001/services/approov-token/routes \
  --data 'hosts[]=localhost' \
  --data 'paths[]=/v1/shapes' \
  --data strip_path=false
```

To confirm the response visit http://localhost:8001/services/approov-token/routes.

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

Now that we know Kong is correctly forwarding our requests, it's time to add the security layer.

### Enabling the Kong JWT plugin for the Approov Token service

The Approov Token service was created to match all routes for `/v1/shapes/*`, therefore any matching request will be checked for having an `Approov-Token` which is correctly signed and has not expired. On a successful check the request will be forwarded and if it fails the request is immediately terminated.

The parameter `name` in `--data name=jwt` is used to give the name of the plugin we want to enable, in this case the Kong JWT official plugin.

The parameter `config.header_names` in `--data config.header_names=Approov-Token` sets the header name from where the JWT token will be extracted. In this case we are setting the header `Approov-Token` as the one to retrieve the token from.

The parameter `config.claims_to_verify` in `--data config.claims_to_verify=exp` is used to enforce Kong to validate the Approov Token expiration time. In this case we configure the JWT claim `exp` as the one containing the unix timestamp with the expiration time.

> **NOTE**: This is an optional parameter for Kong, but **REQUIRED** for Approov token checks, otherwise you weaken the security because Kong will accept expired tokens.

The parameter `config.key_claim_name` in `--data config.key_claim_name=kid` is used to identify which JWT header key contains the identifier to retrieve the secret to be used to check the Approov Token. Remember the JWT header from above in the docs:

```json
{
  "typ": "JWT",
  "alg": "HS256",
  "kid": "approov"
}
```

The parameter `config.secret_is_base64` in `--data config.secret_is_base64=true` is used to configure the Kong JWT plugin to treat the secret as a base64 encoded string.


##### request:

```
curl -i -X POST \
    --url http://localhost:8001/services/approov-token/plugins \
    --data name=jwt \
    --data config.header_names=Approov-Token \
    --data config.claims_to_verify=exp \
    --data config.key_claim_name=kid \
    --data config.secret_is_base64=true
```

Visit http://localhost:8001/services/approov-token/plugins to confirm the response.


## KONG SERVICE FOR THE APPROOV TOKEN BINDING

This will be very similar to what we did for the Approov Token Service, therefore I will give the sequence of commands, without explaining them, except for when we do something extra.

### Creating the Approov Token Binding Service

```
curl -i -X POST \
  --url http://localhost:8001/services/ \
  --data name=approov-token-binding \
  --data url=https://shapes.demo.approov.io
```

### Adding Routes to the Approov Token Binding Service

```
curl -i -X POST \
  --url http://localhost:8001/services/approov-token-binding/routes \
  --data 'hosts[]=localhost' \
  --data 'paths[]=/v1/forms' \
  --data strip_path=false
```

### Enabling the Approov Token Binding Plugin

This plugin will ensure that we have a valid token binding.

This Approov Demo is configured to bind the `Authorization` token with the `Approov-Token`.

So in order to have a valid token binding, the SHA256 hash of the base64 string for the `Authorization` token must match with the value in the `pay` claim for the `Approov-Token`.

In other words we are binding **who** is in the request with **what** made the request.

##### request:

```
curl -i -X POST \
    --url http://localhost:8001/services/approov-token-binding/plugins \
    --data name=approov-token-binding \
    --data config.token_binding_header_name=Authorization
```

Visit http://localhost:8001/services/approov-token-binding/plugins to confirm the response.
