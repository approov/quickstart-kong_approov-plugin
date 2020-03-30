# APPROOV QUICK START

This quick start is for developers familiar with Kong who are looking for a quick intro into how they can add [Approov](https://approov.io) into an existing project. Therefore this will guide you through the necessary steps for adding Approov to an existing Kong API Gateway in a testing environment. Don't try this for the first time in production.

> **NOTE**: If you don't have one or if you prefer to test the Approov Quick Start before you try it out in your own project, then use the **Kong Docker Stack** from this repo by following the instructions for [Trialling in a Test Setup](#trialling-in-a-test-setup) which are located at the end of this document.

For advanced usage of Approov in a Kong API Gateway please read the [Kong Admin API Deep Dive](/docs/KONG_ADMIN_API_DEEP_DIVE.md) guide.


## APPROOV SECRET

We need an [Approov secret](https://approov.io/docs/latest/approov-cli-tool-reference/#secret-command) to check the signature in the JWT tokens and we need to use the same one used by the [Approov Cloud service](https://www.approov.io/approov-in-detail.html) to sign the [Approov Tokens](https://www.approov.io/docs/latest/approov-usage-documentation/#approov-tokens) issued to our mobile app.

### Install the Approov CLI Tool

If you haven't done it already, please follow [these instructions](https://approov.io/docs/latest/approov-installation/#approov-tool) from the Approov docs to download and install the [Approov CLI Tool](https://approov.io/docs/latest/approov-cli-tool-reference/).

### The Approov Secret Key Identifier(kid)

The native Kong JWT plugin requires that the Approov Token contains the key ‘kid’ in its header to [identify](https://approov.io/docs/latest/approov-usage-documentation/#token-secret-extraction) what secret to use in order to verify the signature of the JWT token, like this:

```json
{
  "typ": "JWT",
  "alg": "HS256",
  "kid": "your-approov-kid-here"
}
```

In order to set the `kid` for each Approov Token issued we will use the [Approov CLI Tool](https://approov.io/docs/latest/approov-installation/#approov-tool) as mentioned in the [Approov docs](https://approov.io/docs/latest/approov-usage-documentation/#key-ids):

```
approov secret path/to/admin.token -setKeyID your-approov-kid-here
```

Please replace `your-approov-kid-here` with the unique identifier you want to use for the Approov Secret in your Kong API Gateway.


## KONG ADMIN API SETUP

The official docs for Kong recommend the use of `curl` requests to configure it through its Admin API, and that's what we will do here.

We assume that the Kong Admin API is only listening to the default `localhost` network `127.0.0.1` and port `8001`, available via `http://localhost:8001/admin-path-here`. If this is not true in your case, then replace `http://localhost:8001` with the correct protocol, domain and port.

> **NOTE:** The protocol being used here is `http` for accessing the `localhost` network `127.0.0.1`, but if your setup is exposing the Kong Admin API over the internet, then please use `https` protocol in all examples through this document.

### Updating the Kong Consumer with the Approov Secret

In the `--url` option you need to replace `your-consumer-name-here` with the name of your consumer.

The value in `-data key=...` is the one you set previously when following the [above instructions](#approov-secret) for the Approov secret.

For the value of `--data secret=...` we will need to retrieve the Approov secret from the Approov cloud service, and we will use the Approov CLI tool for that.

##### request:

```
curl -i -X POST \
    --url http://localhost:8001/consumers/your-consumer-name-here/jwt \
    --header "Content-Type: application/x-www-form-urlencoded" \
    --data algorithm="HS256" \
    --data key=your-approov-kid-here \
    --data secret=$(approov secret path/to/admin.token -get base64url | head -2 | tail -1)
```

>**NOTE:**: We retrieved the Approov secret in a sub shell, because if we had provided it directly then the secret would have been saved into the shell history.

To confirm the Approov Secret was added as the JWT credential we can visit http://localhost:8001/consumers/your-consumer-name-here/jwt.

### Enabling the Kong JWT plugin to check the Approov Token

You need to enable the Approov Token check on a per Kong service basis.

In the `--url` option you need to replace `your-service-name-here` with the service name you want to protect with an Approov Token, thus repeat this `curl` request for each service you want to protect with Approov.

##### request:

```
curl -i -X POST \
    --url http://localhost:8001/services/your-service-name-here/plugins \
    --data name=jwt \
    --data config.header_names=Approov-Token \
    --data config.claims_to_verify=exp \
    --data config.key_claim_name=kid \
    --data config.secret_is_base64=true
```

Visit http://localhost:8001/services/your-service-name-here/plugins to confirm the above response.


## TRIALLING IN A TEST SETUP

To test the Approov Quick Start, before using it in your real project, just follow the next steps.

### Kong Docker Stack

Bring up the Kong Docker Stack with:

```
./kong quick-start
```

This will give you a Kong API Gateway with a consumer named as `quick-start-app` and a service named as `quick-start-api`.

### Kong Admin API

#### Updating the Kong Consumer with the Approov Secret

For testing purposes we don't need to retrieve the secret from the Approov cloud service. Instead we have created a dummy one in `.env.example` in the var `APPROOV_BASE64URL_SECRET`. Read more in [APPOOV_SECRET.md](/docs/APPROOV_SECRET.md#the-dummy-secret).

##### request:

```
output=$(source .env.example && curl -i -X POST \
    --url http://localhost:8001/consumers/quick-start-app/jwt \
    --header "Content-Type: application/x-www-form-urlencoded" \
    --data algorithm="HS256" \
    --data key=approov \
    --data secret="${APPROOV_BASE64URL_SECRET? Missing the Approov Secret in the .env file.}") && echo $output
```

> **NOTE**: We use a sub shell to execute this request to avoid the secret `APPROOV_BASE64URL_SECRET` from the `.env.example` to be persisted in the bash history of your shell.

To confirm the Approov Secret was added as the JWT credential we can visit http://localhost:8001/consumers/quick-start-app/jwt.

#### Enabling the Kong JWT plugin to check the Approov Token

##### request:

```
curl -i -X POST \
    --url http://localhost:8001/services/quick-start-api/plugins \
    --data name=jwt \
    --data config.header_names=Approov-Token \
    --data config.claims_to_verify=exp \
    --data config.key_claim_name=kid \
    --data config.secret_is_base64=true
```

Visit http://localhost:8001/services/quick-start-api/plugins to confirm the above response.

### Making API Requests to the Kong API Gateway

Now you can use any request example for `/v1/shapes` in the [Postman collection](/postman/approov-2-kong-plugin.postman_collection.json) or in the [Curl examples](/docs/CURL_REQUESTS_EXAMPLES.md) to test the Approov integration with the Kong API Gateway.
