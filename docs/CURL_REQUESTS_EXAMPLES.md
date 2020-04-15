# CURL REQUESTS EXAMPLES

This curl examples aim to be an exact copy of the same requests used in the [Postman collection](/postman/approov-2-kong-plugin.postman_collection.json).

## NOT PROTECTED BY APPROOV

This type of request will not require an Approov Token to be present in the headers of the request.

##### request:

```
curl -i --request GET 'http://localhost:8000/v1/hello'
```

##### response headers:

```
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 25
Connection: keep-alive
Date: Thu, 13 Feb 2020 11:56:18 GMT
Server: Werkzeug/0.15.2 Python/3.6.7
X-Kong-Upstream-Latency: 69
X-Kong-Proxy-Latency: 1
Via: kong/1.5.0
```

##### response body:

```json
{
  "text": "Hello, World!"
}
```

## APPROOV TOKEN PROTECTED

### VALID REQUESTS

#### Approov Token with Valid Signature and Expire Time

The Approov Token payload must contain always the mandatory key `exp`, that contains the unix timestamp for the time the token will expire, thus this time must be less or equal to the current time.

A JWT token is formed by 3 parts separated by dots, like `header.payload.signature`, thus the third part of the token must have been signed with the same secret Kong knows.

##### request:

```
curl -i --request GET 'http://localhost:8000/v1/shapes' \
  --header 'Approov-Token: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6ImFwcHJvb3YifQ.eyJleHAiOjQ3MDg2ODMyMDUuODkxOTEyfQ.lZnuTLsu0K1YIoq9kWp0vljx6CWzOldPp6wmNxPBG5I'
```
##### response headers:

```
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 19
Connection: keep-alive
Date: Thu, 13 Feb 2020 12:02:07 GMT
Server: Werkzeug/0.15.2 Python/3.6.7
X-Kong-Upstream-Latency: 68
X-Kong-Proxy-Latency: 0
Via: kong/1.5.0
```

##### response body:

```json
{
  "shape": "Circle"
}
```

### INVALID REQUESTS

#### Missing the Approov Token in the Request Headers

The request is missing the header for setting the Approov Token, in the likes of `--header 'Approov-Token: Bearer header.payload.signature`.

##### request:

```
curl -i --request GET 'http://localhost:8000/v1/shapes'
```

##### response headers:

```
HTTP/1.1 401 Unauthorized
Date: Thu, 13 Feb 2020 12:15:57 GMT
Content-Type: application/json; charset=utf-8
Connection: keep-alive
Content-Length: 26
X-Kong-Response-Latency: 0
Server: kong/1.5.0
```

##### response body:

```json
{
  "message": "Unauthorized"
}
```

#### Malformed Approov Token in the Request Headers

A JWT token is formed by 3 parts separated by dots, like `header.payload.signature`, thus anything we pass for the Approov Token in the form of a dummy string, like `adasdasdsadasd`, must be considered invalid, and this one doesn't even contain the dot separators.

##### request:

```
curl -i --request GET 'http://localhost:8000/v1/shapes' \
  --header 'Approov-Token: adasdasdsadasd'
```

##### response headers:

```
HTTP/1.1 401 Unauthorized
Date: Thu, 13 Feb 2020 12:24:03 GMT
Content-Type: application/json; charset=utf-8
Connection: keep-alive
Content-Length: 26
X-Kong-Response-Latency: 0
Server: kong/1.5.0
```

##### response body:

```json
{
  "message": "Unauthorized"
}
```

> **CHALLENGE:** Now try to make a request with a dummy string that have the the dots to simulate the `header.payload.signature`, like:
>
> ```
> curl -i --request GET 'http://localhost:8000/v1/shapes' --header 'Approov-Token: adasdasdsadasd.xxcvxvcxvcxcxcv.uyiyuiyuityty'
>```
>
> His the result what you expected to be?

#### Missing the key `kid` in the JWT header

The Kong JWT plugin needs to know what secret to use to check the signature of the JWT, and that is done via the key `kid` in the JWT header. The `kid` value is the name for the key that will be used to retrieve the secret from the database.

##### request:

```
curl -i --request GET 'http://localhost:8000/v1/shapes' \
  --header 'Approov-Token: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjQ3MDg2ODMzNTUuMjI3NDE1LCJwYXkiOiJmM1UyZm5pQkpWRTA0VGRlY2owZDZvclY5cVQ5dDUyVGpmSHhkVXFEQmdZPSJ9.dEstT0XWf3BJUlurXoGm_XOJyUK3ZkpxyqlUcY7u1kY'
```

Let's inspect the header of the JWT to ensure that doesn't contain the `kid` key:

```
$ echo "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9" | base64 -d
{"typ":"JWT","alg":"HS256"}
```

##### response headers:

```
HTTP/1.1 401 Unauthorized
Date: Thu, 13 Feb 2020 12:10:52 GMT
Content-Type: application/json; charset=utf-8
Connection: keep-alive
Content-Length: 42
X-Kong-Response-Latency: 1
Server: kong/1.5.0
```

##### response body:

```json
{
  "message": "No mandatory 'kid' in claims"
}
```

#### Invalid Signature for the Approov Token

The Approov Token must be signed with the same secret shared between the backend and the Approov Cloud service.

##### request:

```
curl -i --request GET 'http://localhost:8000/v1/shapes' \
  --header 'Approov-Token: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6ImFwcHJvb3YifQ.eyJleHAiOjE1NTUwODMzNDkuMzc3NzYyM30.vbTlW5hqBlhu0kFr_JsHLb_CfM-DmUz2_xPZ92I0NjQ'
```

##### response headers:

```
HTTP/1.1 401 Unauthorized
Date: Thu, 20 Feb 2020 19:15:49 GMT
Content-Type: application/json; charset=utf-8
Connection: keep-alive
Content-Length: 31
X-Kong-Response-Latency: 1
Server: kong/1.5.0
```

##### response body:

```json
{
  "message": "Invalid signature"
}
```

#### Missing expiration time in the Approov Token

The Approov Token payload must contain always the mandatory key `exp`, that contains the unix timestamp for when the token will expire.

##### request:

```
curl -i --request GET 'http://localhost:8000/v1/shapes' \
  --header 'Approov-Token: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6ImFwcHJvb3YifQ.eyJpc3MiOiJhcHByb292LmlvIn0.q9U0X8yzUKRnelO-qdx-FCXB57GdKUicVdz1rCLiOWU'
```

##### response headers:

```
HTTP/1.1 401 Unauthorized
Date: Thu, 20 Feb 2020 19:20:41 GMT
Content-Type: application/json; charset=utf-8
Connection: keep-alive
Content-Length: 26
X-Kong-Response-Latency: 1
Server: kong/1.5.0
```

##### response body:

```json
{
  "exp": "must be a number"
}
```

#### Expired Approov Token with Valid Signature

The Approov Token payload must contain always the mandatory key `exp`, that contains the unix timestamp for the time the token will expire.

##### request:

```
curl -i --request GET 'http://localhost:8000/v1/shapes' \
  --header 'Approov-Token: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6ImFwcHJvb3YifQ.eyJleHAiOjE1NTUwODMzNDkuMzc3NzYyM30.m7fPoDvOAFmYFLueQtiTBsjzJmUc-Jd4OAcRbOXL8wE'
```

##### response headers:

```
HTTP/1.1 401 Unauthorized
Date: Thu, 13 Feb 2020 12:47:59 GMT
Content-Type: application/json; charset=utf-8
Connection: keep-alive
Content-Length: 23
X-Kong-Response-Latency: 0
Server: kong/1.5.0
```

##### response body:

```json
{
  "exp": "token expired"
}
```


## APPROOV TOKEN BINDING PROTECTED

### VALID REQUESTS

#### Valid Approov Token Binding, that Matches the Authorization Token

The value for the key `pay` in the Approov Token payload is a base64 string of the SHA256 hash for the Authorization token.

This ties the approov token with the user Authentication token, thus securing further the request.

##### request

```
curl -i --request GET 'http://localhost:8000/v1/forms' \
  --header 'Approov-Token: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6ImFwcHJvb3YifQ.eyJleHAiOjM5NjQyNTU3ODEuNDE1NjI4LCJwYXkiOiJWUUZGUEpaNjgyYU90eFJNanowa3RDSG15V2VFRWVTTXZYaDF1RDhKM3ZrPSJ9.BBUkJoN98V5-_tR9sKN1CgOEl-bDUqrhQK_yWcXisis' \
  --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c'
```

##### response headers:

```
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 18
Connection: keep-alive
Date: Thu, 13 Feb 2020 12:52:28 GMT
Server: Werkzeug/0.15.2 Python/3.6.7
X-Kong-Upstream-Latency: 273
X-Kong-Proxy-Latency: 1
Via: kong/1.5.0
```

##### response body:

```json
{
  "form": "Sphere"
}
```

#### Without an Approov Token Binding, but with a Valid Approov Token

We need to accept the request as valid when the expected key `pay` is missing in the payload of the Approov Token, because when the Approov token comes from the Approov failover system it will not contain it.

##### request:

```
curl -i --request GET 'http://localhost:8000/v1/forms' \
  --header 'Approov-Token: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6ImFwcHJvb3YifQ.eyJleHAiOjQ3MDg2ODMyMDUuODkxOTEyfQ.lZnuTLsu0K1YIoq9kWp0vljx6CWzOldPp6wmNxPBG5I' \
  --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c'
```

##### response headers:

```
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 16
Connection: keep-alive
Date: Thu, 13 Feb 2020 12:56:56 GMT
Server: Werkzeug/0.15.2 Python/3.6.7
X-Kong-Upstream-Latency: 65
X-Kong-Proxy-Latency: 2
Via: kong/1.5.0
```

##### response body:

```json
{
  "form": "Cone"
}
```

#### Missing the header for the Approov Token Binding

The Approov Token Binding contained in the payload key `pay` binds to an header in the request, like the `Authorization` token, thus if not present the Approov Token Binding cannot be validated.

##### request:

```
curl -i --request GET 'http://localhost:8000/v1/forms' \
  --header 'Approov-Token: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6ImFwcHJvb3YifQ.eyJleHAiOjQ3MDg2ODM0NTcsInBheSI6IjU2NnZRV2FXR0JncytLRTh5c2pUVFBRdGdwdWUrWExNcXg4ZVlvYkNySTA9In0.9FGvK0ElAgJFglH14rRRhu3gRZpDuT_C_50TdC0TWd0'
```

##### response headers:

```
HTTP/1.1 401 Unauthorized
Date: Thu, 13 Feb 2020 13:07:36 GMT
Content-Type: application/json; charset=utf-8
Connection: keep-alive
Content-Length: 2
X-Kong-Response-Latency: 0
Server: kong/1.5.0
```

##### response body:

```json
{}
```

#### Approov Token Binding not Matching the Authorization Token

The value for the key `pay` in the Approov Token payload doesn't match the base64 string for the SHA256 of the Authorization token, thus invalidating the request.

##### request:

```
curl -i --request GET 'http://localhost:8000/v1/forms' \
  --header 'Approov-Token: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6ImFwcHJvb3YifQ.eyJleHAiOjQ3MDg2ODM0NTcuNDg1Mzk1LCJwYXkiOiI1NjZ2UVdhV0dCZ3MrS0U4eXNqVFRQUXRncHVlK1hMTXF4OGVZb2JDckkwPSJ9.lDSAuPPYWLEYuPMZLQrPFqyQlHOebzwiZLhvNbsapeU' \
  --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c'
```

##### response headers:

```
HTTP/1.1 401 Unauthorized
Date: Thu, 13 Feb 2020 14:10:04 GMT
Content-Type: application/json; charset=utf-8
Connection: keep-alive
Content-Length: 2
X-Kong-Response-Latency: 1
Server: kong/1.5.0
```

##### response body:

```json
{}
```
