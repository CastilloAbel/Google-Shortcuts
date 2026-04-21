# 🎯 OAuth2 Quick Fix Plan - 30 Minutes

**Current Issue:** Safari shows "invalid address" error during OAuth2 redirect  
**Root Cause:** Probable `redirect_uri` mismatch between app and Google Cloud Console  
**Time Estimate:** 30 minutes for full diagnosis

---

## ⏱️ Timeline

### MINUTE 0-5: Verification (5 min)

**ACTION 1:** Open Google Cloud Console
- 🔗 Go to: https://console.cloud.google.com/apis/credentials
- Find iOS Client: `25887787070-g1q6h2806850edpgllg3eboeot43e79p.apps.googleusercontent.com`
- Click to edit
- Scroll to "Authorized redirect URIs"
- **SCREENSHOT THIS** - Copy exact text

**ACTION 2:** Check App redirect_uri
- Open: `src/OAuth/OAuthConfig.swift`
- Find: `static var redirectURI`
- **COPY THE COMPUTED VALUE** (what it generates)

**ACTION 3:** Compare
- Are they IDENTICAL?
  - ✅ YES → Skip to MINUTE 7
  - ❌ NO → Go to MINUTE 5-10

---

### MINUTE 5-10: Fix Mismatch (If Needed)

**IF Google Console has WRONG value:**

1. In Google Console, click "Edit"
2. Clear "Authorized redirect URIs"
3. Enter EXACTLY:
   ```
   com.googleusercontent.apps.25887787070-g1q6h2806850edpgllg3eboeot43e79p:/oauthredirect
   ```
4. Click "Save"
5. Wait 30 seconds for it to sync

**ELSE IF App has computation issue:**

1. Open `OAuthConfig.swift`
2. Verify:
   ```swift
   let reversed = clientID.replacingOccurrences(of: ".apps.googleusercontent.com", with: "")
   // Should give: 25887787070-g1q6h2806850edpgllg3eboeot43e79p
   
   return "com.googleusercontent.apps.\(reversed):/oauthredirect"
   // Should give: com.googleusercontent.apps.25887787070-g1q6h2806850edpgllg3eboeot43e79p:/oauthredirect
   ```
3. If looks wrong, fix manually

---

### MINUTE 15-20: Generate PKCE Values

**ACTION:** Run Python script (Windows PowerShell)

```powershell
cd "d:\Abel\Documents\Proyectos\google-shortcuts"
python3 generate_pkce.py
```

**OUTPUT WILL SHOW:**
```
code_verifier: <LONG_STRING>
code_challenge: <ANOTHER_LONG_STRING>
```

**ACTION:** Save both values in a text file or Notepad

---

### MINUTE 20-25: Test in Bruno

**ACTION 1:** Open Bruno HTTP client

**ACTION 2:** Create new request

```
Method: GET
URL: https://accounts.google.com/o/oauth2/v2/auth?
     client_id=25887787070-g1q6h2806850edpgllg3eboeot43e79p.apps.googleusercontent.com&
     redirect_uri=com.googleusercontent.apps.25887787070-g1q6h2806850edpgllg3eboeot43e79p:/oauthredirect&
     response_type=code&
     scope=email%20profile%20https://www.googleapis.com/auth/gmail.send%20https://www.googleapis.com/auth/gmail.readonly&
     code_challenge=<PASTE_CODE_CHALLENGE>&
     code_challenge_method=S256
```

Replace `<PASTE_CODE_CHALLENGE>` with value from Python script

**ACTION 3:** Copy full URL, open in Safari/Chrome

**WATCH:** What happens?
- 🔴 Safari error → Screenshot the error message
- 🟢 Google login screen → Problem was already fixed!
- 🟡 Redirect attempted → Check address bar for error code

---

### MINUTE 25-30: Report Findings

**Share with me:**

1. **Google Console redirect_uri:**
   ```
   ___________________________
   ```

2. **App computed redirectURI:**
   ```
   ___________________________
   ```

3. **Do they match?**
   - YES / NO

4. **Bruno test result:**
   - Error shown: ___________________________
   - Screenshot attached: YES / NO

---

## 🚨 If "invalid address" Still Shows

**Check these in order:**

1. ❌ Redirect URI format has space or typo
   - **Fix:** Match Google Console EXACTLY

2. ❌ Info.plist doesn't have URL scheme
   - **Fix:** Add to CFBundleURLSchemes:
     ```xml
     <string>com.googleusercontent.apps.25887787070-g1q6h2806850edpgllg3eboeot43e79p:/oauthredirect</string>
     ```

3. ❌ Google Console is in wrong project
   - **Fix:** Verify correct project is selected (top-left dropdown)

4. ❌ OAuth2 consent screen not configured
   - **Fix:** Go to Consent screen tab, fill out app info

5. ❌ Client type is wrong
   - **Fix:** Should be "iOS" not "Web" or "Desktop"

---

## 📞 Help Needed?

Provide:
1. Screenshot of Google Console redirect_uri
2. Output of Python script (code_challenge)
3. Bruno GET request response (screenshot of error)
4. App logs (from Codemagic build or local test)

---

## 🔄 Testing Sequence

```
┌──────────────┐
│ Step 1:      │
│ Fix redirect │ ← YOU ARE HERE
│ URI mismatch │
└──────┬───────┘
       ↓
┌──────────────┐
│ Step 2:      │
│ Generate     │
│ PKCE & test  │
│ in Bruno     │
└──────┬───────┘
       ↓
┌──────────────┐
│ Step 3:      │
│ If Bruno     │
│ succeeds,    │
│ update app   │
└──────┬───────┘
       ↓
┌──────────────┐
│ Step 4:      │
│ Re-compile   │
│ in Codemagic│
│ & test app  │
└──────────────┘
```

---

**READY? Start with MINUTE 0-5 now!**
