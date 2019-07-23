## End to end OAuth 2 JOSE/JWT Interaction

These logging highlights illustrate what's happening during the OAuth2 flow when  JOSE/JWT.

First, a request is sent to `http://localhost:8080/resource and this is intercepted by the API gateway. 

The gateway expects all requestes to be authenticated, so it immediately asks the authentication provider (the UAA) to authenticate the user via the `authentication-uri` of `http://localhost:8090/uaa/oauth/authorize`. The UAA then steps in and presents the user with an authentication challenge:

```bash
uaa | DEBUG --- UaaMetricsFilter: Successfully matched URI: /uaa/oauth/authorize to a group: /ui
uaa | DEBUG --- ChainedAuthenticationManager: Attempting chained authentication of org.springframework.security.authentication.UsernamePasswordAuthenticationToken@3ce6bcf6: Principal: user1; Credentials: [PROTECTED]; Authenticated: false; Details: remoteAddress=172.23.0.1, sessionId=<SESSION>; Not granted any authorities with manager:org.cloudfoundry.identity.uaa.authentication.manager.CheckIdpEnabledAuthenticationManager@3c5169cf required:null
uaa | DEBUG --- AuthzAuthenticationManager: Processing authentication request for user1
uaa | DEBUG --- AuthzAuthenticationManager: Password successfully matched for userId[user1]:61b7c1c4-a0c0-44f7-a709-a8638068d137
uaa | INFO --- Audit: IdentityProviderAuthenticationSuccess ('user1'): principal=61b7c1c4-a0c0-44f7-a709-a8638068d137, origin=[remoteAddress=172.23.0.1, sessionId=<SESSION>], identityZoneId=[uaa], authenticationType=[uaa]
uaa | INFO --- Audit: UserAuthenticationSuccess ('user1'): principal=61b7c1c4-a0c0-44f7-a709-a8638068d137, origin=[remoteAddress=172.23.0.1, sessionId=<SESSION>], identityZoneId=[uaa]
```

Above, the UAA has confirmed the users identity has been as `user1` and their principal id has been assigned as `61b7c1c4-a0c0-44f7-a709-a8638068d137`.

The UAA will now ask the user to 'Authorise' the `login-client` application (the gateway) and give it access to the users profile:

```bash
uaa | DEBUG --- UaaMetricsFilter: Successfully matched URI: /uaa/oauth/authorize to a group: /ui
uaa | DEBUG --- SessionResetFilter: Evaluating user-id for session reset:61b7c1c4-a0c0-44f7-a709-a8638068d137
uaa | DEBUG --- UserManagedAuthzApprovalHandler: Looking up user approved authorizations for client_id=login-client and username=user1
uaa | DEBUG --- JdbcApprovalStore: adding approval: [[61b7c1c4-a0c0-44f7-a709-a8638068d137, resource.read, login-client, Fri Aug 23 11:11:25 GMT 2019, APPROVED, Tue Jul 23 11:11:25 GMT 2019]]
uaa | INFO --- Audit: TokenIssuedEvent ('["resource.read","openid","email"]'): principal=61b7c1c4-a0c0-44f7-a709-a8638068d137, origin=[caller=login-client, details=(remoteAddress=172.23.0.4, clientId=login-client)], identityZoneId=[uaa]
gateway | DEBUG --- HttpLogging: [26d3ff07] Decoded [{access_token=eyJhbGciOiJSUzI1NiIsImprdSI6Imh0dHBzOi8vbG9jYWxob3N0OjgwODAvdWFhL3Rva2VuX2tleXMiLCJraW (truncated)...]
```

Above, the gateway application `login-client` has now been granted access to the users profile, which includes the scope `resource.read`. The gateway has also been issued with a JWT `access_token` (part redacted in the log for security):

The gateway checks the validity and authenticity of this token using the UAA's published public keys on the `jwk-set-uri` (which is `http://uaa:8090/uaa/token_keys`):

```bash
uaa     | DEBUG --- SecurityFilterChainPostProcessor$HttpsEnforcementFilter: Filter chain 'tokenKeySecurity' processing request GET /uaa/token_keys
gateway | DEBUG --- HttpLogging: [434f3904] Decoded "{"keys":[{"kty":"RSA","e":"AQAB","use":"sig","kid":"key-id-1","alg":"RS256","value":"-----BEGIN PUB (truncated)...
gateway | DEBUG --- HttpLogging: [3c76d40a] Decoded [{user_id=61b7c1c4-a0c0-44f7-a709-a8638068d137, user_name=user1, name=first1 last1, given_name=first1 (truncated)...]
```

The JWT token is deemed to be authentic by the gateway, so the gateway starts forwarding the request to the resource server's `/resource` endpoint:

```bash
gateway | DEBUG --- RoutePredicateHandlerMapping: Route matched: resource
gateway | DEBUG --- RoutePredicateHandlerMapping: Mapping [Exchange: GET http://localhost:8080/resource] to Route{id='resource', uri=http://resource:9000, order=0, predicate=org.springframework.cloud.gateway.support.ServerWebExchangeUtils$$Lambda$334/1074263646@2fb64b12, gatewayFilters=[OrderedGatewayFilter{delegate=org.springframework.cloud.security.oauth2.gateway.TokenRelayGatewayFilterFactory$$Lambda$336/1107412069@42187950, order=0}, OrderedGatewayFilter{delegate=org.springframework.cloud.gateway.filter.factory.RemoveRequestHeaderGatewayFilterFactory$$Lambda$339/1139814130@210d549e, order=0}]}
```

 The resource server then contacts the UAA. It also wants to authenticate the users JWT `access_token`:

```bash
uaa | DEBUG --- UaaMetricsFilter: Successfully matched URI: /uaa/token_keys to a group: /oauth-oidc
uaa | DEBUG --- SecurityFilterChainPostProcessor$HttpsEnforcementFilter: Filter chain 'tokenKeySecurity' processing request GET /uaa/token_keys
resource | DEBUG --- HttpLogging: [472e353f] Decoded "{"keys":[{"kty":"RSA","e":"AQAB","use":"sig","kid":"key-id-1","alg":"RS256","value":"-----BEGIN PUB (truncated)...
```

Above, the resource server checks the validity of the JWT token against the keys held by the UAA.

The keys check out, so the resource server decodes the JWT `access_token` and allows the user to access the `/resource` endpoint:

```bash
resource | TRACE --- SecuredServiceApplication: ***** JWT Headers: {jku=https://localhost:8080/uaa/token_keys, kid=key-id-1, typ=JWT, alg=RS256}
resource | TRACE --- SecuredServiceApplication: ***** JWT Claims: {sub=61b7c1c4-a0c0-44f7-a709-a8638068d137, user_name=user1, origin=uaa, iss=http://uaa:8090/uaa/oauth/token, client_id=login-client, aud=[resource, openid, login-client], zid=uaa, grant_type=authorization_code, user_id=61b7c1c4-a0c0-44f7-a709-a8638068d137, azp=login-client, scope=["resource.read","openid","email"], auth_time=1563880281, exp=Tue Jul 23 23:11:25 GMT 2019, iat=Tue Jul 23 11:11:25 GMT 2019, jti=fa9c60e2e89b48a584169f839f32e282, email=user1@provider.com, rev_sig=b3f4e1e1, cid=login-client}
resource | TRACE --- SecuredServiceApplication: ***** JWT Token: eyJhbGciOiJSUzI1NiIsImprdSI6Imh0dHBzOi8vbG9jYWxob3N0OjgwODAvdWFhL3Rva2VuX2tleXMiLCJraWQiOiJrZXktaWQtMSIsInR5cCI6IkpXVCJ9.eyJqdGkiOiJmYTljNjBlMmU4OWI0OGE1ODQxNjlmODM5ZjMyZTI4MiIsInN1YiI6IjYxYjdjMWM0LWEwYzAtNDRmNy1hNzA5LWE4NjM4MDY4ZDEzNyIsInNjb3BlIjpbInJlc291cmNlLnJlYWQiLCJvcGVuaWQiLCJlbWFpbCJdLCJjbGllbnRfaWQiOiJsb2dpbi1jbGllbnQiLCJjaWQiOiJsb2dpbi1jbGllbnQiLCJhenAiOiJsb2dpbi1jbGllbnQiLCJncmFudF90eXBlIjoiYXV0aG9yaXphdGlvbl9jb2RlIiwidXNlcl9pZCI6IjYxYjdjMWM0LWEwYzAtNDRmNy1hNzA5LWE4NjM4MDY4ZDEzNyIsIm9yaWdpbiI6InVhYSIsInVzZXJfbmFtZSI6InVzZXIxIiwiZW1haWwiOiJ1c2VyMUBwcm92aWRlci5jb20iLCJhdXRoX3RpbWUiOjE1NjM4ODAyODEsInJldl9zaWciOiJiM2Y0ZTFlMSIsImlhdCI6MTU2Mzg4MDI4NSwiZXhwIjoxNTYzOTIzNDg1LCJpc3MiOiJodHRwOi8vdWFhOjgwOTAvdWFhL29hdXRoL3Rva2VuIiwiemlkIjoidWFhIiwiYXVkIjpbInJlc291cmNlIiwib3BlbmlkIiwibG9naW4tY2xpZW50Il19.l9SC-3dvUWbqH-teAUpSDfn0V9EeRmaLioj5N6oYZSpKUBIFh7QR9Dd4e2wbG6itpI3ulA30629Tw8aIHo_72Owetc7v4dBmg-IL_c1Nycc5JYXguMMZmKT4oIW2lAfNxWl9Z821HyNk4SsRiIPpcWXiziAO8n4h3anjr7NQESYRFole0gDT19IOX1TIB03ZSbgjmRq3-UclpX-qRYW_XJ-CeVbcjRI_C1XEDuqLVflushpsQvBt6snb1Oq1c6zmvXkXag9QXA0iBusJnIt66zua2-dnGv334VPTo6SaIoGBSp4ReRDCFLKNk2tAF-Kqpc_S8KehmgY0jMYN7QLYNw
```

 Information encoded into the JWT is then used to show who read the resource - "Resource accessed by: user1 (with subjectId: 61b7c1c4-a0c0-44f7-a709-a8638068d137)":

 ```bash
 resource | DEBUG --- HttpLogging: [5becb7ae] Writing "Resource accessed by: user1 (with subjectId: 61b7c1c4-a0c0-44f7-a709-a8638068d137)"
 ```

 You can decode the token in the trace and see the content at [https://jwt.io/](https://jwt.io/)
