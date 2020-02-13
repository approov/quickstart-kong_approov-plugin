# APPROOV TOKEN PLUGIN FOR KONG

Learn how to integrate [Approov](https://approov.io) in the [Kong API Gateway](https://konghq.com/kong/) by enabling the [Approov Token](https://www.approov.io/docs/latest/approov-usage-documentation/#approov-tokens) check with the native [Kong JWT plugin](https://docs.konghq.com/hub/kong-inc/jwt/), and the optional [Approov Token Binding](https://www.approov.io/docs/latest/approov-usage-documentation/#token-binding) check with the Approov plugin [included](/kong-plugin) in this repo.

## APPROOV QUICK START

For a quick start of integrating Approov in your current Kong API Gateway please follow this [guide](/docs/APPROOV_QUICK_START.md).


## APROOV DEMO

This [demo](/docs/APPROOV_KONG_PLUGIN_DEMO.md) has the goal of showing to bot experienced and inexperienced Kong users how Approov can be integrated in the Kong API Gateway, and also includes the Approov Token Binding check, an advanced feature of Approov.


## KONG ADMIN

In order to setup the Approov Token check in the quick start and in the demo we have used the Kong Admin API via `curl` requests, just like it is done in the official docs for Kong.

### Step by Step

Read the [Step by Step](/docs/KONG_ADMIN_API_STEP_BY_STEP.md) guide for learning how to use the [./kong-admin](/bin/kong-admin.sh) helper script, that wraps the `curl` requests to interact with the Kong Admin API in order to setup the demo.

### Deep Dive

Take the [deep dive](/docs/KONG_ADMIN_API_DEEP_DIVE.md) to learn how to use the Kong Admin API with raw `curl` requests, and read the detailed explanations for each request.
