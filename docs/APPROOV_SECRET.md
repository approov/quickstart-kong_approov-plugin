# APPROOV SECRET

We need the secret to check the signature in the JWT tokens. For testing out the quick start with the [Postman collection](/postman/approov-2-kong-plugin.postman_collection.json) or with the [Curl examples](/docs/CURL_REQUESTS_EXAMPLES.md) the secret can be a dummy one, but for production we will need to get it with the Approov CLI Tool.

## The Dummy Secret

 The native Kong JWT plugin requires the secret to be Base64 URL safe encoded, therefore we can create one with the `openssl` and `base64url` Linux packages.

##### command:

```
openssl rand -hex 64 | base64url
```

> **NOTE**: The `base64url` command is part of the `basez` package in Linux.

##### output:

```
MTllNTMxM2U3Mjk4ODkxOWU1MTBhNmQwYjA1YmU0NzM1ODQ3NGZkZjg0MzEyMjgxNGY1NDhhMGNhNzlkNjQ4YTkwZDM0ZTcwZDE0NzM1YmIwZDk0MjQwZDM1M2E4NTZkMWQwYTg0NjVkZDdhMGMwZTJjYjhmYmM3NzEzN2E2MTAK
```

## The Production Secret

In production we don't use a custom dummy secret, instead we need to use the same one used by the Approov Cloud service to sign the Approov Tokens issued to our mobile app.

We will use the [Approov CLI Tool](https://approov.io/docs/v2.2/approov-installation/#approov-tool) to download the [Approov secret](https://approov.io/docs/v2.2/approov-cli-tool-reference/#secret-command).

##### command:

```
approov secret path/to/admin.token -get base64url
```

##### output:

```
note: secret is base64url encoded and must be decoded to its binary form to verify Approov tokens
here_will_be_the_base64_url_safe_encoded_secret
```

## Adding the Approov Secret to the Environment File

Now that we have a ready to use Approov secret, we must set it in the `.env` file, at the root of this project.

#### Example with the dummy secret:

```
APPROOV_BASE64URL_SECRET=MTllNTMxM2U3Mjk4ODkxOWU1MTBhNmQwYjA1YmU0NzM1ODQ3NGZkZjg0MzEyMjgxNGY1NDhhMGNhNzlkNjQ4YTkwZDM0ZTcwZDE0NzM1YmIwZDk0MjQwZDM1M2E4NTZkMWQwYTg0NjVkZDdhMGMwZTJjYjhmYmM3NzEzN2E2MTAK
```

## The Approov Secret Key Identifier(kid)

The native Kong JWT plugin requires that the Approov Token contains in it's header the key `kid` in order to identify what secret to use to verify the signature of the JWT token, like this:

```json
{
  "typ": "JWT",
  "alg": "HS256",
  "kid": "approov"
}
```

In order to set the `kid` for each Approov Token issued we will use the [Approov CLI Tool](https://approov.io/docs/v2.2/approov-installation/#approov-tool) as mentioned in the [Approov docs](https://approov.io/docs/v2.2/approov-usage-documentation/#key-ids):

```
approov secret path/to/admin.token -setKeyID approov
```

We used the string `approov` for the identifier, but you are free to use whatsoever unique string identifier for your own project.
