# OAuth2 Redirect URI Verification Checklist

## ⚠️ CRITICAL: redirect_uri MUST match EXACTLY

Your app's redirect_uri is computed by `OAuthConfig.redirectURI`:

```swift
static var redirectURI: String {
    let reversed = clientID.replacingOccurrences(of: ".apps.googleusercontent.com", with: "")
    return "com.googleusercontent.apps.\(reversed):/oauthredirect"
}
```

This generates:
```
com.googleusercontent.apps.25887787070-g1q6h2806850edpgllg3eboeot43e79p:/oauthredirect
```

---

## STEP 1: Verify Google Cloud Console Registration

### 🔗 Go to Google Cloud Console
1. Open: https://console.cloud.google.com/apis/credentials
2. Ensure you're in the correct **Project**
3. Find and click on Client ID: `25887787070-g1q6h2806850edpgllg3eboeot43e79p.apps.googleusercontent.com`

### ✅ SECTION: Authorized redirect URIs

Look for this section in your iOS client credentials:

```
Authorized redirect URIs:
├─ com.googleusercontent.apps.25887787070-g1q6h2806850edpgllg3eboeot43e79p:/oauthredirect
```

**IF NOT PRESENT:** Add it exactly as shown above

**IF DIFFERENT FORMAT:** Update it immediately

---

## STEP 2: Character-by-Character Comparison

| Position | Your Format | Status | Notes |
|----------|------------|---------|-------|
| Start | `com.googleusercontent.apps.` | ✓ | Fixed prefix |
| Middle | `25887787070-g1q6h2806850edpgllg3eboeot43e79p` | ? | Extract from clientID |
| Scheme | `:` | ✓ | Single colon only |
| Path | `/oauthredirect` | ✓ | Single slash, no double slash |
| Query params | None | ✓ | No `?` or `&` allowed |
| Protocol | None | ✓ | NO `http://` or `https://` |
| Trailing slash | None | ✓ | NO trailing `/` |

---

## STEP 3: Info.plist URL Scheme Registration

Your app declares this in **Info.plist**:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLName</key>
    <string>com.abel.googleshortcuts</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>googleshortcuts</string>
      <string>com.googleusercontent.apps.25887787070-g1q6h2806850edpgllg3eboeot43e79p:/oauthredirect</string>
    </array>
  </dict>
</array>
```

### ✅ Checklist:
- [ ] `CFBundleURLSchemes` array has the custom scheme
- [ ] Scheme matches: `com.googleusercontent.apps.25887787070-g1q6h2806850edpgllg3eboeot43e79p:/oauthredirect`
- [ ] No typos in the long identifier
- [ ] Colon `:` and single slash `/` are correct

---

## STEP 4: How iOS URL Scheme Routing Works

When Google redirects after auth:
```
com.googleusercontent.apps.25887787070-g1q6h2806850edpgllg3eboeot43e79p:/oauthredirect?code=4/0...&state=...
```

iOS does this:
1. ✓ Reads URL scheme: `com.googleusercontent.apps.25887787070-g1q6h2806850edpgllg3eboeot43e79p`
2. ✓ Matches to Info.plist `CFBundleURLSchemes`
3. ✓ App comes to foreground
4. ✓ Route to `UIScene` with URL
5. ✓ Your code extracts `code` parameter

**If any part fails, Safari shows "Cannot open page" or "Invalid address"**

---

## STEP 5: Debug Points in OAuthManager.swift

Add these logging statements to verify parameters:

```swift
// In startLogin()
print("🔍 OAuth Debug - Authorization Request:")
print("  Client ID: \(OAuthConfig.clientID)")
print("  Redirect URI: \(OAuthConfig.redirectURI)")  // PRINT THIS!

// Expected output:
// Client ID: 25887787070-g1q6h2806850edpgllg3eboeot43e79p.apps.googleusercontent.com
// Redirect URI: com.googleusercontent.apps.25887787070-g1q6h2806850edpgllg3eboeot43e79p:/oauthredirect
```

```swift
// In handleOAuthCallback(url:)
func handleOAuthCallback(url: URL) {
    print("🔄 OAuth Callback URL received:")
    print("  Full URL: \(url.absoluteString)")
    print("  Scheme: \(url.scheme ?? "MISSING")")
    print("  Host: \(url.host ?? "MISSING")")
    print("  Path: \(url.path)")
    print("  Query params: \(url.query ?? "MISSING")")
    
    // If these look wrong, redirect_uri is mismatched
}
```

---

## STEP 6: Common Mismatches & Solutions

### ❌ WRONG - Double Slash
```
com.googleusercontent.apps.25887787070-g1q6h2806850edpgllg3eboeot43e79p://oauthredirect
```
**Problem:** Google won't recognize it  
**Fix:** Single slash only: `:/oauthredirect`

---

### ❌ WRONG - With HTTP Protocol
```
http://com.googleusercontent.apps.25887787070-g1q6h2806850edpgllg3eboeot43e79p:/oauthredirect
```
**Problem:** Not a valid custom URL scheme  
**Fix:** Remove `http://` entirely

---

### ❌ WRONG - Trailing Slash
```
com.googleusercontent.apps.25887787070-g1q6h2806850edpgllg3eboeot43e79p:/oauthredirect/
```
**Problem:** Exact match fails  
**Fix:** Remove trailing slash

---

### ❌ WRONG - Typo in Suffix
```
com.googleusercontent.apps.25887787070-g1q6h2806850edpgllg3eboeot43e79p:/oauth_redirect  ← underscore!
```
**Problem:** Registered as `oauthredirect` (no underscore) in Google Console  
**Fix:** Must be `oauthredirect` (no special chars)

---

### ❌ WRONG - Space or Hidden Characters
```
com.googleusercontent.apps.25887787070-g1q6h2806850edpgllg3eboeot43e79p:/oauthredirect  
                                                                          ^ invisible space!
```
**Problem:** Copy-paste error  
**Fix:** Manual type or verify no extra whitespace

---

## 🎯 FINAL VERIFICATION FLOW

```
┌─────────────────────────────────────────────┐
│ 1. Google Cloud Console                      │
│    Registered URI:                            │
│    com.googleapis.../oauthredirect           │
│                                              │
│    ✓ Copy exact value                        │
└──────────────┬──────────────────────────────┘
               │
               ↓
┌─────────────────────────────────────────────┐
│ 2. Info.plist CFBundleURLSchemes             │
│    <string>com.googleapis.../oauthredirect  │
│    </string>                                 │
│                                              │
│    ✓ MUST match step 1 exactly              │
└──────────────┬──────────────────────────────┘
               │
               ↓
┌─────────────────────────────────────────────┐
│ 3. OAuthConfig.swift redirectURI             │
│    Computed: com.googleapis.../oauthredirect│
│                                              │
│    ✓ MUST match steps 1 & 2                 │
└──────────────┬──────────────────────────────┘
               │
               ↓
┌─────────────────────────────────────────────┐
│ 4. OAuthManager.swift startLogin()           │
│    Uses OAuthConfig.redirectURI              │
│                                              │
│    ✓ Should compile & print correct value  │
└──────────────┬──────────────────────────────┘
               │
               ↓
┌─────────────────────────────────────────────┐
│ 5. Browser Authorization                    │
│    Opens URL with redirect_uri parameter    │
│                                              │
│    ✓ Should redirect back to app           │
│    ✗ If error, check all 4 above           │
└─────────────────────────────────────────────┘
```

---

## 📋 Pre-Testing Checklist

Before testing with Bruno or the app:

- [ ] Logged into Google Cloud Console
- [ ] Found correct iOS Client ID
- [ ] Copied exact redirect_uri from Google Console
- [ ] Compared with `OAuthConfig.redirectURI` computed value
- [ ] Compared with Info.plist `CFBundleURLSchemes`
- [ ] All three values are IDENTICAL
- [ ] No extra spaces, slashes, or typos
- [ ] Added debug logging to OAuthManager
- [ ] Python PKCE script executed successfully
- [ ] Have `code_verifier` and `code_challenge` ready

---

## 🚀 Next Action

1. **Complete steps 1-3 above**
2. **Screenshot or note the exact redirect_uri from Google Console**
3. **Compare with app values**
4. **Report findings:**
   - `redirect_uri` from Google Console: `_________`
   - `redirectURI` from app: `_________`
   - Match? YES / NO

**If YES**: Proceed with Bruno testing  
**If NO**: Update Google Console or app to match
