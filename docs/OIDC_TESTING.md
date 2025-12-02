# OIDC Authentication Testing Guide

This guide walks you through testing OIDC authentication with Keycloak in your local development environment.

## OIDC Configuration Overview

Mydia uses an optimized OIDC configuration that works with **any standard OIDC provider** without requiring special client configuration. The configuration uses:

- **Standard OAuth2 authentication methods** (`client_secret_post`, `client_secret_basic`)
- **Standard OAuth2 response mode** (`query`)
- **Standard OIDC scopes** (`openid`, `profile`, `email`)

This means you can use Mydia with **minimal provider configuration** - no need to specify:

- `token_endpoint_auth_method` settings
- `response_modes` lists
- JWT-based authentication methods
- PAR (Pushed Authorization Request) settings

### Supported Providers

This configuration uses standard OAuth2 methods that should work with any compliant OIDC provider:

- **Keycloak** - Default configuration should work out of the box
- **Authelia** - Minimal client configuration required
- **Auth0** - Should work with default client settings
- **Okta** - Standard OAuth2 client should work
- **Azure AD** - Should work with standard app registration
- **Google** - Should work with OAuth2 client credentials
- Any other standard OIDC/OAuth2 provider

### How It Works

The OIDC library automatically:

1. Discovers provider capabilities via the `.well-known/openid-configuration` endpoint
2. Selects the most compatible authentication method from our preferred list
3. Uses standard OAuth2 flows that all providers support
4. Enables PAR only if the provider explicitly supports and requires it

## Quick Start

1. **Start all services including Keycloak:**

   ```bash
   ./dev up -d
   ```

2. **Access Keycloak admin console:**

   - URL: http://localhost:8080
   - Username: `admin`
   - Password: `admin`

3. **Create a realm:**

   - Click "Create realm" button
   - Name: `mydia`
   - Click "Create"

4. **Create a client:**

   - Go to "Clients" in the left menu
   - Click "Create client"
   - Client ID: `mydia`
   - Client type: `OpenID Connect`
   - Click "Next"
   - Enable "Client authentication"
   - Click "Save"
   - Configure the client:
     - Valid redirect URIs: `http://localhost:4000/auth/oidc/callback`
     - Valid post logout redirect URIs: `http://localhost:4000`
     - Web origins: `http://localhost:4000`
   - Click "Save"
   - Go to "Credentials" tab
   - Copy the "Client secret"

5. **Configure Mydia environment variables:**

   Edit `compose.override.yml` and uncomment these lines in the `app` service environment section:

   ```yaml
   OIDC_ISSUER: "http://keycloak:8080/realms/mydia"
   OIDC_CLIENT_ID: "mydia"
   OIDC_CLIENT_SECRET: "YOUR_CLIENT_SECRET_FROM_KEYCLOAK"
   OIDC_REDIRECT_URI: "http://localhost:4000/auth/oidc/callback"
   OIDC_SCOPES: "openid profile email"
   ```

   Replace `YOUR_CLIENT_SECRET_FROM_KEYCLOAK` with the actual secret from step 4.

6. **Create a test user in Keycloak:**

   - Go to "Users" in the left menu
   - Click "Create new user"
   - Username: `testuser`
   - Email: `test@example.com`
   - First name: `Test`
   - Last name: `User`
   - Email verified: ON
   - Click "Create"
   - Go to "Credentials" tab
   - Click "Set password"
   - Password: `password`
   - Temporary: OFF
   - Click "Save"

7. **Restart the app to load new environment variables:**

   ```bash
   ./dev restart app
   ```

8. **Test the authentication:**
   - Open http://localhost:4000/auth/login
   - Click "Sign in with OIDC"
   - You'll be redirected to Keycloak
   - Login with `testuser` / `password`
   - You should be redirected back to Mydia and logged in

## Configuring User Roles

To test role-based authorization:

1. **Create roles in Keycloak:**

   - Go to "Realm roles" in the left menu
   - Click "Create role"
   - Role name: `admin` (or `user`, `readonly`)
   - Click "Save"

2. **Assign roles to users:**

   - Go to "Users" → select your test user
   - Go to "Role mapping" tab
   - Click "Assign role"
   - Select the role (e.g., `admin`)
   - Click "Assign"

3. **Test role-based access:**
   - Login to Mydia
   - Try accessing admin-only routes (e.g., `/admin/config`)
   - Users with `admin` role should have access

## Testing with Authelia (Recommended for Production)

Authelia is an excellent choice for self-hosted OIDC authentication. Here's how to configure it:

### Generate Client Secret

First, generate a secure client secret:

```bash
# Generate a random secret (recommended)
openssl rand -base64 64 | tr -d '\n'

# Or use a password hash tool for Authelia
docker run --rm authelia/authelia:latest authelia crypto hash generate pbkdf2 --password 'your-password'
```

### Authelia Client Configuration

Add the Mydia client to your Authelia configuration in the `identity_providers.oidc.clients` section:

```yaml
identity_providers:
  oidc:
    # Required: HMAC secret for signing tokens
    hmac_secret: 'your-hmac-secret-here'

    # Required: JWKS key for token signing
    jwks:
      - key_id: 'main'
        algorithm: 'RS256'
        use: 'sig'
        key: |
          -----BEGIN PRIVATE KEY-----
          ... your RSA private key ...
          -----END PRIVATE KEY-----

    clients:
      - client_id: 'mydia'
        client_name: 'Mydia - Media Companion'
        client_secret: 'your-client-secret-here'  # Plain text or hashed
        authorization_policy: 'one_factor'  # or 'two_factor'
        redirect_uris:
          - 'https://mydia.example.com/auth/oidc/callback'
          - 'http://localhost:4000/auth/oidc/callback'  # For development
        scopes:
          - 'openid'
          - 'profile'
          - 'email'
        grant_types:
          - 'authorization_code'
        response_types:
          - 'code'
        response_modes:
          - 'query'
          - 'fragment'
          - 'form_post'
        token_endpoint_auth_method: 'client_secret_post'
```

### Mydia Environment Variables

Configure Mydia with these environment variables:

```yaml
# docker-compose.yml or environment file
environment:
  OIDC_ENABLED: "true"
  OIDC_DISCOVERY_DOCUMENT_URI: "https://auth.example.com/.well-known/openid-configuration"
  OIDC_CLIENT_ID: "mydia"
  OIDC_CLIENT_SECRET: "your-client-secret-here"
  OIDC_REDIRECT_URI: "https://mydia.example.com/auth/oidc/callback"
  OIDC_SCOPES: "openid profile email"
  PHX_HOST: "mydia.example.com"
```

**Important Notes:**

- `OIDC_DISCOVERY_DOCUMENT_URI` should point to Authelia's well-known endpoint
- `OIDC_REDIRECT_URI` must exactly match one of the `redirect_uris` in Authelia
- The `client_secret` must match between Authelia and Mydia

### Minimal Configuration (Defaults Work)

For a simpler setup, only these fields are required in Authelia:

```yaml
clients:
  - client_id: 'mydia'
    client_secret: 'your-client-secret-here'
    redirect_uris:
      - 'https://mydia.example.com/auth/oidc/callback'
    scopes:
      - 'openid'
      - 'profile'
      - 'email'
```

Authelia's defaults handle everything else:
- `authorization_policy` defaults to `one_factor`
- `grant_types` defaults to `['authorization_code']`
- `response_types` defaults to `['code']`
- `token_endpoint_auth_method` defaults to `client_secret_basic` (Mydia supports both)

### Restart the app:

```bash
./dev restart app
# Or for Docker:
docker compose restart mydia
```

## Testing with Authentik (Alternative)

If you prefer to use Authentik instead of Keycloak:

1. Uncomment the Authentik service and its dependencies in `compose.override.yml`
2. Comment out the Keycloak service
3. Start services: `./dev up -d`
4. Access Authentik: http://localhost:9000
5. Follow the Authentik setup wizard
6. Create an OAuth2/OIDC provider
7. Update the OIDC environment variables accordingly

## Troubleshooting

### OIDC login not working

1. **Check that Keycloak is running:**

   ```bash
   ./dev logs keycloak
   ```

2. **Verify environment variables are loaded:**

   ```bash
   ./dev shell
   env | grep OIDC
   ```

3. **Check application logs:**
   ```bash
   ./dev logs -f app
   ```

### Redirect URI mismatch error

- Make sure the redirect URI in your OIDC provider exactly matches your configured `OIDC_REDIRECT_URI`
- Check that `OIDC_REDIRECT_URI` environment variable is set correctly
- **Important:** The scheme (http vs https) must match exactly

### "Redirected to the wrong URI" error behind reverse proxy

If you see an error like:

```
OIDC callback failure: Redirected to the wrong URI: http://mydia.example.com/auth/oidc/callback
```

This happens when Mydia is behind a reverse proxy (like Nginx, Caddy, or Traefik) and cannot detect the original HTTPS scheme. The fix is already included in Mydia - it trusts `X-Forwarded-*` headers from the proxy.

**Ensure your reverse proxy sends these headers:**

For **Caddy** (automatic):
```
reverse_proxy mydia:4000
```
Caddy automatically sets `X-Forwarded-Proto`, `X-Forwarded-Host`, and `X-Forwarded-For`.

For **Nginx**:
```nginx
location / {
    proxy_pass http://mydia:4000;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Host $host;
}
```

For **Traefik** (automatic with default middleware):
Headers are set automatically when using IngressRoutes or labels.

**Critical:** Make sure `OIDC_REDIRECT_URI` uses `https://` when your site is served over HTTPS:
```yaml
OIDC_REDIRECT_URI: "https://mydia.example.com/auth/oidc/callback"
```

### Invalid client credentials

- Verify the `OIDC_CLIENT_SECRET` environment variable exactly matches the secret configured in your OIDC provider
- For Authelia: Check the `client_secret` in your Authelia configuration
- For Keycloak: Check the client credentials tab in the admin console
- Ensure no trailing whitespace or newlines in the secret

### User not created in Mydia database

- Check application logs for errors during user creation
- Ensure the OIDC provider returns `sub`, `email`, and `preferred_username` claims

## Local Development Fallback

If you don't want to set up OIDC for local development, you can use the local authentication fallback:

1. Access: http://localhost:4000/auth/local/login
2. Default credentials: `admin` / `admin`

This is only available in development mode and should not be used in production.
