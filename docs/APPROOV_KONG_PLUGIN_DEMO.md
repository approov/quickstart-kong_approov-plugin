# APPROOV KONG PLUGIN DEMO

This demo will show how to protect API endpoints with an Approov token and with the Approov token binding.

## DEMO CONTEXT

For this Approov demo we will use the API at `https://shapes.demo.approov.io/v1` to simulate a Third Party API which we have no control over, but which we want to protect from being abused and exploited.

The `v1` API has three routes: `v1/hello`, `v1/shapes` and `v1/forms`. We will not be protecting the `v1/hello`, but the other ones we care about protecting. The `v1/shapes` and `v1/forms` will be protected by an Approov Token check. For `v1/forms` we require user authentication and for enhanced security we will bind the `Authentication` token with the `Approov-Token`, thus we will enable the Approov Token Binding check.


## DEMO QUICK START

This demo runs on top of the [Kong Docker Stack](/docs/KONG_DOCKER_STACK.md), and it's made easy to use by invoking the [./kong](/bin/kong.sh) helper script.

This wraps a series of `curl` requests to the Kong Admin API in order to setup the Approov demo. If you want to learn how it works under the hood, then feel free to read the Kong Admin API [Step by Step](/docs/KONG_ADMIN_API_STEP_BY_STEP.md) or the [Deep Dive](/docs/KONG_ADMIN_API_DEEP_DIVE.md).

### Starting the Kong Demo for Approov

This will take some time, especially on the first run, where it needs to pull and build the docker images and run the migrations. Subsequent runs will be much faster to start.

##### command:

```
./kong demo
```

##### output:

```
Creating network "kong-approov_kong-net" with the default driver
Creating volume "kong-approov_kong_data" with default driver
Creating kong-approov_db_1 ... done
Creating kong-approov_kong_1               ... done
Creating kong-approov_kong-migrations-up_1 ... done
Creating kong-approov_kong-migrations_1    ... done

---> CONSUMER: ADD A NEW CONSUMER
HTTP/1.1 201 Created

... some content omitted for brevity ...

---> SERVICE: ENABLE APPROOV TOKEN BINDING PLUGIN FOR V1/FORMS
HTTP/1.1 201 Created
Date: Thu, 13 Feb 2020 15:24:30 GMT
Content-Type: application/json; charset=utf-8
Connection: keep-alive
Access-Control-Allow-Origin: *
Server: kong/1.5.0
Content-Length: 432
X-Kong-Admin-Latency: 9

{"created_at":1581607470,"config":{"remove_approov_token_header":false,"token_binding_header_name":"Authorization","run_on_preflight":true,"remove_approov_token_binding_header":false},"id":"fc95d9f4-d6a4-4cf2-9896-aad62906e831","service":{"id":"081f325c-b346-4b84-bf6c-90bdf6da8d70"},"name":"approov-token-binding","protocols":["grpc","grpcs","http","https"],"enabled":true,"run_on":"first","consumer":null,"route":null,"tags":null}
```

> **TIP**: If you need to start over from a clean state, then just destroy the Kong demo and start a new one with:
> ```
> ./kong destroy && ./kong demo
> ```

### Making Requests to the Third Party API

In order to test the Approov integration with the Kong API Gateway we will perform some requests to the Third Party API which will cover both valid and invalid requests for Approov Tokens, with and without token binding.

Feel free to modify the examples we are providing for Postman and Curl, so that you can try as many edge cases as you can think of.

#### Using Postman

Use the [Postman collection](/postman/approov-2-kong-plugin.postman_collection.json) to start playing with the request examples.

#### Using CURL

If you don't have Postman installed or you prefer to do it from the terminal, then just go through the [CURL_REQUEST_EXAMPLES.md](/docs/CURL_REQUESTS_EXAMPLES.md).
