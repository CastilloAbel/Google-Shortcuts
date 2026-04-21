# OAuth2 Debugging Guide - Bruno HTTP Client

## 🎯 OBJETIVO
Test complete OAuth2 flow locally WITHOUT Xcode, then identify exact redirect_uri issue

---

## FASE 1: VERIFY GOOGLE CLOUD CONSOLE (CRITICAL)

### Step 1.1: Check Your Current Configuration
1. Go to: https://console.cloud.google.com/apis/credentials
2. Find your iOS Client ID: `25887787070-g1q6h2806850edpgllg3eboeot43e79p.apps.googleusercontent.com`
3. Click on it to edit
4. Scroll to "Authorized redirect URIs"
5. **COPY THE EXACT STRING** (we'll compare with app)

### Step 1.2: What You Should See
Expected redirect_uri for iOS apps (from Google docs):
```
com.googleusercontent.apps.<reverse-domain>:/oauthredirect
```

Your app generates:
```
com.googleusercontent.apps.25887787070-g1q6h2806850edpgllg3eboeot43e79p:/oauthredirect
```

### CRITICAL COMPARISON CHECKLIST
- [ ] Colon (`:`) is present (not double colon)
- [ ] Single forward slash after colon (`:/`)
- [ ] Exact match: `oauthredirect` (lowercase, no typos)
- [ ] No extra spaces or characters
- [ ] If URL has `http://` or `https://` = ❌ WRONG for custom schemes

---

## FASE 2: MANUAL OAUTH2 FLOW WITH BRUNO

### Step 2.1: Generate PKCE Code Verifier & Challenge

Use this Python script to generate PKCE parameters:

```python
import secrets
import hashlib
import base64
import urllib.parse

def generate_pkce():
    # Generate code_verifier (43-128 chars, unreserved characters)
    code_verifier = base64.urlsafe_b64encode(
        secrets.token_bytes(32)
    ).decode('utf-8').rstrip('=')
    
    # Generate code_challenge (S256 method)
    code_challenge = base64.urlsafe_b64encode(
        hashlib.sha256(code_verifier.encode()).digest()
    ).decode('utf-8').rstrip('=')
    
    print("code_verifier:", code_verifier)
    print("code_challenge:", code_challenge)
    print("\nUse these values in Bruno requests below")
    
generate_pkce()
```

✅ **RUN THIS AND SAVE THE OUTPUT**

---

## FASE 3: BRUNO REQUEST TEMPLATES

### Request 3.1: Get Authorization Code

**Request Method:** GET (opens in browser)

```
https://accounts.google.com/o/oauth2/v2/auth?
client_id=25887787070-g1q6h2806850edpgllg3eboeot43e79p.apps.googleusercontent.com&
redirect_uri=com.googleusercontent.apps.25887787070-g1q6h2806850edpgllg3eboeot43e79p:/oauthredirect&
response_type=code&
scope=email%20profile%20https://www.googleapis.com/auth/gmail.send%20https://www.googleapis.com/auth/gmail.readonly&
code_challenge=<YOUR_CODE_CHALLENGE>&
code_challenge_method=S256
```

**Steps:**
1. Replace `<YOUR_CODE_CHALLENGE>` with value from Python script
2. Copy full URL to browser
3. Sign in with your Google account
4. **WATCH THE REDIRECT** - you'll see Safari error or success
5. When you see error, copy the URL shown in browser address bar
6. **SAVE THIS URL** - it contains the error details

---

### Request 3.2: Exchange Code for Token

**Method:** POST  
**URL:** `https://oauth2.googleapis.com/token`

**Headers:**
```
Content-Type: application/x-www-form-urlencoded
```

**Body (x-www-form-urlencoded):**
```
code=<AUTH_CODE_FROM_STEP_3.1>
client_id=25887787070-g1q6h2806850edpgllg3eboeot43e79p.apps.googleusercontent.com
redirect_uri=com.googleusercontent.apps.25887787070-g1q6h2806850edpgllg3eboeot43e79p:/oauthredirect
grant_type=authorization_code
code_verifier=<YOUR_CODE_VERIFIER>
```

**Expected Response (Success):**
```json
{
  "access_token": "ya29.a0...",
  "expires_in": 3599,
  "refresh_token": "1//0...",
  "scope": "...",
  "token_type": "Bearer"
}
```

**Common Errors:**
- `invalid_grant` → code_verifier mismatch, or auth code expired
- `redirect_uri_mismatch` → redirect_uri not registered in Google Console
- `invalid_client` → wrong client_id

---

### Request 3.3: Test Gmail API with Token

**Method:** GET  
**URL:** `https://gmail.googleapis.com/gmail/v1/users/me/profile`

**Headers:**
```
Authorization: Bearer <YOUR_ACCESS_TOKEN>
```

**Expected Response:**
```json
{
  "emailAddress": "your.email@gmail.com",
  "messagesTotal": 1234,
  "threadsTotal": 456,
  "historyId": "123456"
}
```

This proves the token works! ✅

---

## FASE 4: COMMON ISSUES & SOLUTIONS

### Issue: `redirect_uri_mismatch`
**Root Cause:** URI in app ≠ URI in Google Console  
**Solution:**  
1. Copy EXACT redirect_uri from OAuthConfig.swift
2. Go to Google Console → OAuth Clients  
3. Edit iOS client
4. Add/Update redirect_uri with EXACT string from step 1
5. Save

### Issue: Safari shows "invalid address"
**Root Cause:** Custom URL scheme not registered OR redirect URI format wrong  
**Solution:**
1. Verify Info.plist has correct CFBundleURLSchemes
2. Check if `:` should be `://` (space matters!)
3. Test with `localhost:8080` as alternative (for debugging only)

### Issue: Code expires in Step 3.2
**Root Cause:** Authorization codes expire after ~10 minutes  
**Solution:** Don't wait between 3.1 and 3.2. Do them quickly.

---

## FASE 5: INTEGRATION CHECKLIST FOR APP FIX

After confirming OAuth works in Bruno:

### In OAuthConfig.swift:
- [ ] `client_id` matches Google Console exactly
- [ ] `redirectURI` formula generates correct string
- [ ] Test by printing at runtime: `print(OAuthConfig.redirectURI)`

### In Info.plist:
- [ ] `CFBundleURLSchemes` array contains exact _reversed_ URI
- [ ] Format check: `com.googleusercontent.apps.25887787070-g1q6h2806850edpgllg3eboeot43e79p:/oauthredirect`

### In OAuthManager.swift:
- [ ] `startLogin()` passes correct code_challenge & code_challenge_method
- [ ] `handleOAuthCallback()` extracts auth code correctly
- [ ] `exchangeCodeForTokens()` includes code_verifier in body ⚠️ CRITICAL

---

## 🔍 DEBUG LOGGING

Add to OAuthManager.swift:

```swift
func startLogin() {
    // ... existing code ...
    
    let challenge = codeChallenge
    let verifier = codeVerifier
    
    print("🔐 OAuth Debug:")
    print("  Client ID: \(OAuthConfig.clientID)")
    print("  Redirect URI: \(OAuthConfig.redirectURI)")
    print("  Code Verifier Length: \(verifier.count)")
    print("  Code Challenge: \(challenge)")
    print("  Scope: \(OAuthConfig.scopes.joined(separator: " "))")
    
    // Build auth URL
    let authURL = // ... your URL building code
    print("  Auth URL: \(authURL.absoluteString)")
    
    // Open Safari
    UIApplication.shared.open(authURL)
}
```

Check Xcode console after each Bruno test - these logs will show exact parameters being sent.

---

## 📊 CREDENTIAL VERIFICATION TABLE

| Component | Current Value | Status | Google Console Value |
|-----------|--------------|--------|---------------------|
| Client ID | `25887787070-g1q6h2806850edpgllg3eboeot43e79p.apps.googleusercontent.com` | ✓ | _(verify)_ |
| Redirect URI | `com.googleusercontent.apps.25887787070-g1q6h2806850edpgllg3eboeot43e79p:/oauthredirect` | ❓ | _(verify)_ |
| Bundle ID | `com.abel.googleshortcuts` | ✓ | _(check)_ |
| Scopes | `gmail.send`, `gmail.readonly`, `userinfo.email` | ✓ | _(check)_ |

---

## 📱 NEXT STEPS

1. **TODAY:** Run Python script, get PKCE values
2. **TODAY:** Make Request 3.1 in Bruno (authorization)
3. **TODAY:** Save success URL or error screenshot
4. **TOMORROW:** Make Request 3.2 (token exchange)
5. **TOMORROW:** Make Request 3.3 (Gmail API test)
6. **VERIFY:** Exact redirect_uri in Google Console
7. **FIX:** Update app if URI format needs change
8. **TEST:** Compile in Codemagic, test on iPhone 13

---

## ⚠️ WINDOWS-SPECIFIC NOTES

Since you're on Windows developing for iOS:
- Use Bruno POST requests (not curl, PowerShell escaping issues)
- Keep authorization code window open during token exchange
- Test with Codemagic builds, not local compilation
- Check build logs for OAuth parameter values

---

**Last Updated:** April 21, 2026  
**Created for:** google-shortcuts OAuth2 debugging
