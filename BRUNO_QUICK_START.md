# 🚀 Bruno HTTP Client Quick Start

**What is Bruno?** Free, offline-first HTTP client (like Postman)  
**Why for OAuth2?** Test API calls WITHOUT writing code

---

## 📥 Installation (2 min)

1. Download: https://www.usebruno.com/downloads
2. Windows version available
3. Extract and run `bruno.exe`
4. Create new collection: "Google OAuth2"

---

## How to Make a GET Request (Test Authorization)

### Step 1: Create Request

```
1. Bruno window opens
2. Click "New" → "New Request"  
3. Name: "Step 1 - Get Authorization Code"
```

### Step 2: Set Method & URL

```
Method: DROP-DOWN → Select "GET"

URL: https://accounts.google.com/o/oauth2/v2/auth?
     client_id=25887787070-g1q6h2806850edpgllg3eboeot43e79p.apps.googleusercontent.com&
     redirect_uri=com.googleusercontent.apps.25887787070-g1q6h2806850edpgllg3eboeot43e79p:/oauthredirect&
     response_type=code&
     scope=email%20profile%20https://www.googleapis.com/auth/gmail.send&
     code_challenge=<PASTE_YOUR_CODE_CHALLENGE_HERE>&
     code_challenge_method=S256
```

### Step 3: Send

```
Click big "Send" button (right side)
```

### Step 4: See Response

**Option A: Browser Opens**
```
Safari/Chrome opens with Google login
Sign in
↓
Gets redirected (check address bar for errors)
```

**Option B: Error in Bruno**
```
Shows error JSON response:
{
  "error": "redirect_uri_mismatch",
  "error_description": "..."
}
```

**If redirect_uri_mismatch:**
- ❌ Means redirect_uri is WRONG
- Go back to step 1 of plan
- Fix Google Console

**If Login Succeeds:**
- ✅ Watch Safari address bar
- Look for: `com.googleusercontent.apps.../oauthredirect?code=XXXXX`
- Copy the `XXXXX` part (authorization code)

---

## How to Make a POST Request (Exchange Code for Token)

### Step 1: Create Request

```
1. Click "New" → "New Request"
2. Name: "Step 2 - Exchange Code for Token"
```

### Step 2: Set Method & URL

```
Method: DROP-DOWN → Select "POST"

URL: https://oauth2.googleapis.com/token
```

### Step 3: Add Headers

```
Click "Headers" tab
Add new header:
  Name: Content-Type
  Value: application/x-www-form-urlencoded
```

### Step 4: Add Body (Form Data)

```
Click "Body" tab
Select: "form-urlencoded" (not JSON!)

Add fields:
  Field 1:
    name: code
    value: <PASTE_AUTHORIZATION_CODE_FROM_STEP_1>
  
  Field 2:
    name: client_id
    value: 25887787070-g1q6h2806850edpgllg3eboeot43e79p.apps.googleusercontent.com
  
  Field 3:
    name: redirect_uri
    value: com.googleusercontent.apps.25887787070-g1q6h2806850edpgllg3eboeot43e79p:/oauthredirect
  
  Field 4:
    name: grant_type
    value: authorization_code
  
  Field 5:
    name: code_verifier
    value: <PASTE_YOUR_CODE_VERIFIER_HERE>
```

### Step 5: Send

```
Click "Send"
```

### Step 6: See Response

**Success Response:**
```json
{
  "access_token": "ya29.a0AfH6SMBx...",
  "expires_in": 3599,
  "refresh_token": "1//0eH5...",
  "scope": "email profile https://www.googleapis.com/auth/gmail.send...",
  "token_type": "Bearer"
}
```

**Error Response Examples:**

| Error | Meaning | Fix |
|-------|---------|-----|
| `invalid_grant` | code_verifier wrong or expired | Regenerate PKCE, do step 1 again |
| `redirect_uri_mismatch` | Still wrong! | Fix Google Console |
| `unauthorized_client` | Client ID wrong | Check Google Console |

---

## Test Gmail API with Token (Verify It Works)

### Step 1: Create Request

```
Name: "Step 3 - Test Gmail Profile"
```

### Step 2: Set Method & URL

```
Method: GET

URL: https://gmail.googleapis.com/gmail/v1/users/me/profile
```

### Step 3: Add Authorization Header

```
Click "Headers" tab
Add new header:
  Name: Authorization
  Value: Bearer <PASTE_ACCESS_TOKEN_FROM_STEP_2>
```

### Step 4: Send

```
Click "Send"
```

### Step 5: See Response

**Success:**
```json
{
  "emailAddress": "your.email@gmail.com",
  "messagesTotal": 1234,
  "threadsTotal": 456,
  "historyId": "123456789"
}
```

**If this works:**
✅ OAuth2 is WORKING correctly  
✅ Problem is app-side (Info.plist or URL routing)

**If "unauthorized":**
❌ Access token expired or scopes wrong

---

## Visual Guide: Bruno Interface

```
┌─────────────────────────────────────────┐
│ 🔴 Bruno                                │
├─────────────────────────────────────────┤
│  [New] [Open] [Save]   GET ▼ | [Send] │  ← Method dropdown
├─────────────────────────────────────────┤
│                                         │
│ 📝 URL: https://accounts.google.com...  │  ← Paste URL here
│                                         │
├─────────────────────────────────────────┤
│ [Body] [Headers] [Params] [Auth]        │  ← Tabs
├─────────────────────────────────────────┤
│                                         │
│ Add Headers/Body here ↓                 │
│                                         │
│ Content-Type: application/x-www-form.. │
│                                         │
├─────────────────────────────────────────┤
│ Response: (shows after Send)            │
│ {                                       │
│   "access_token": "ya29.a0..."          │
│   "expires_in": 3599                    │
│   ...                                   │
│ }                                       │
└─────────────────────────────────────────┘
```

---

## ⚠️ Common Mistakes in Bruno

### ❌ Mistake 1: Headers in URL
```
WRONG: URL?Content-Type=application/json
RIGHT: Add Header separately in Headers tab
```

### ❌ Mistake 2: JSON Body for URL-encoded Request
```
WRONG (for POST to /token):
{
  "code": "4/0...",
  "client_id": "..."
}

RIGHT (for POST to /token):
Select "form-urlencoded" and add fields
code: 4/0...
client_id: ...
```

### ❌ Mistake 3: Missing code_verifier
```
WRONG: POST /token without code_verifier
RIGHT: Always include code_verifier in body with POST
```

### ❌ Mistake 4: Copy-Pasting with Spaces
```
WRONG: Paste "ya29.a0... ... " with extra spaces
RIGHT: Use Bruno variables or triple-check no spaces
```

---

## 💾 Save Your Work (Optional)

```
1. Click "Save" (top left)
2. All requests saved in collection
3. Next time, just open them and update values
```

---

## 🎯 Exact Copy-Paste Steps

### For Step 1 - Get Auth Code

1. Python script: `python3 generate_pkce.py`
2. Do you have two values? (code_verifier, code_challenge)
3. Create GET request in Bruno
4. Build URL:
```
https://accounts.google.com/o/oauth2/v2/auth?client_id=25887787070-g1q6h2806850edpgllg3eboeot43e79p.apps.googleusercontent.com&redirect_uri=com.googleusercontent.apps.25887787070-g1q6h2806850edpgllg3eboeot43e79p:/oauthredirect&response_type=code&scope=email%20profile%20https://www.googleapis.com/auth/gmail.send%20https://www.googleapis.com/auth/gmail.readonly&code_challenge=<PASTE_CODE_CHALLENGE_VALUE>&code_challenge_method=S256
```
5. Click Send
6. Browser opens, sign in
7. Browser redirects, copy code from URL

### For Step 2 - Exchange Code for Token

1. Create POST request in Bruno
2. URL: `https://oauth2.googleapis.com/token`
3. Add Header:
   - Name: `Content-Type`
   - Value: `application/x-www-form-urlencoded`
4. Add Body fields (form-urlencoded):
   - `code` = `<CODE_FROM_STEP_1>`
   - `client_id` = `25887787070-g1q6h2806850edpgllg3eboeot43e79p.apps.googleusercontent.com`
   - `redirect_uri` = `com.googleusercontent.apps.25887787070-g1q6h2806850edpgllg3eboeot43e79p:/oauthredirect`
   - `grant_type` = `authorization_code`
   - `code_verifier` = `<CODE_VERIFIER_FROM_PYTHON>`
5. Click Send
6. Get tokens in response

---

## 📞 Troubleshoot Bruno Issues

**Q: "Can't connect to server"**
A: Check internet connection, URL is correct

**Q: Response is HTML (error page)**
A: Check headers/parameters, might have typo

**Q: "401 Unauthorized"**
A: Access token expired or wrong format

**Q: "Empty response"**
A: Server error. Check scopes are correct

---

**Ready? Open Bruno and start with Step 1!**
