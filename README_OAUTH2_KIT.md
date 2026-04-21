# 📚 OAuth2 Debugging Kit - File Index

**Version:** April 21, 2026  
**Purpose:** Fix "invalid address" Safari error in Google Shortcuts iOS app  
**Status:** Ready to use - 6 comprehensive guides

---

## 📋 Files Created

### 1. **QUICK_FIX_PLAN.md** ⭐ START HERE
- **Duration:** 30 minutes
- **Purpose:** Step-by-step timeline for diagnosing and fixing
- **What it does:**
  - Minute 0-5: Verify redirect_uri in Google Console
  - Minute 5-10: Fix mismatches if found
  - Minute 15-20: Generate PKCE values
  - Minute 20-25: Test in Bruno
  - Minute 25-30: Report findings
- **When to use:** First step every time

---

### 2. **REDIRECT_URI_VERIFICATION.md** ⭐ CRITICAL
- **Duration:** 5 minutes to verify
- **Purpose:** Deep dive into redirect_uri matching
- **Contains:**
  - Character-by-character comparison checklist
  - Info.plist verification
  - Common format mistakes (and solutions)
  - 🎯 Final verification flow diagram
  - Debug logging points to add to code
- **When to use:** When URL formats seem wrong

---

### 3. **OAUTH2_DEBUG_GUIDE.md** 📖 COMPREHENSIVE
- **Duration:** Reference material (30-60 min full reading)
- **Purpose:** Complete OAuth2 flow documentation
- **Sections:**
  - Phase 1: Google Cloud Console verification
  - Phase 2: Manual OAuth2 flow with Bruno
  - Phase 3: Bruno request templates (GET, POST, test)
  - Phase 4: Common issues & solutions
  - Phase 5: Integration checklist for app fix
  - Debug logging code samples
  - Credential verification table
- **When to use:** When something fails, search for solution

---

### 4. **BRUNO_QUICK_START.md** 🔧 HOW-TO
- **Duration:** 20 minutes to understand
- **Purpose:** Bruno HTTP client tutorial
- **Teaches:**
  - Installation (2 min)
  - Creating GET requests (auth flow)
  - Creating POST requests (token exchange)
  - Testing Gmail API with token
  - Visual guide to Bruno interface
  - Common mistakes and solutions
  - Exact copy-paste steps for each request
- **When to use:** First time using Bruno, or forgotten how

---

### 5. **generate_pkce.py** 🐍 EXECUTABLE
- **Language:** Python 3
- **Purpose:** Generate PKCE code_verifier and code_challenge
- **What it produces:**
  ```
  code_verifier: <43-128 char random string>
  code_challenge: <SHA256 hash of verifier>
  ```
- **How to run:**
  ```powershell
  cd "d:\Abel\Documents\Proyectos\google-shortcuts"
  python3 generate_pkce.py
  ```
- **Output:** Ready-to-use values for Bruno requests

---

### 6. **bruno-oauth2-collection.json** 📦 BRUNO IMPORT
- **Format:** Bruno collection JSON
- **Purpose:** Pre-configured OAuth2 requests
- **Contains:**
  - Step 1: Get Authorization Code (GET)
  - Step 2: Exchange Code for Token (POST)
  - Step 3: Get Gmail Profile (test token)
  - Step 4: List Gmail Messages
  - Step 5: Get Message Details
  - Step 6: Refresh Access Token
- **Variables:** Placeholders for tokens, codes, etc.
- **How to use:**
  ```
  1. Open Bruno
  2. Click "Import"
  3. Select this JSON file
  4. Fill in variables before each request
  ```

---

## 🎯 How They Work Together

```
START
  ↓
Read: QUICK_FIX_PLAN.md (timeline)
  ↓
Follow: REDIRECT_URI_VERIFICATION.md (verify match)
  ↓
If not matching:
  → Fix Google Console or app config
  → OAUTH2_DEBUG_GUIDE.md → "Phase 1" section
  ↓
Generate: Run generate_pkce.py
  ↓
Test: BRUNO_QUICK_START.md (how to use client)
  ↓
Use: bruno-oauth2-collection.json (pre-made requests)
  ↓
Reference: OAUTH2_DEBUG_GUIDE.md (if error occurs)
  ↓
SUCCESS!
```

---

## 📂 File Locations

All files are in:
```
d:\Abel\Documents\Proyectos\google-shortcuts\
```

Specific files:
```
├── QUICK_FIX_PLAN.md                (start here)
├── REDIRECT_URI_VERIFICATION.md      (checklist)
├── OAUTH2_DEBUG_GUIDE.md             (reference)
├── BRUNO_QUICK_START.md              (how-to)
├── generate_pkce.py                  (executable)
└── bruno-oauth2-collection.json      (bruno import)
```

---

## 🚀 3 Different Entry Points

### 🏃 Entry Point A: "I have 30 minutes right now"
1. Open: `QUICK_FIX_PLAN.md`
2. Follow timeline (minutes 0-30)
3. Generate PKCE with `generate_pkce.py`
4. Test in Bruno using `BRUNO_QUICK_START.md`
5. Report findings

### 🚶 Entry Point B: "I want to understand everything"
1. Read: `OAUTH2_DEBUG_GUIDE.md` (complete reference)
2. Follow: All 5 phases completely
3. Use: `bruno-oauth2-collection.json` for requests
4. Reference: `REDIRECT_URI_VERIFICATION.md` for format checks

### 🎯 Entry Point C: "Just tell me what's wrong"
1. Open: `REDIRECT_URI_VERIFICATION.md`
2. Follow: Verification flow diagram
3. Compare: 3 sources (Google Console, app, Info.plist)
4. If WRONG: Fix the mismatch
5. If RIGHT: Use `QUICK_FIX_PLAN.md` for next steps

---

## ✅ Checklist: Ready to Debug?

Before starting:

- [ ] Have access to Google Cloud Console
- [ ] Know your iOS Client ID
- [ ] Have Bruno HTTP client installed
- [ ] Have Python 3 available (for PKCE generation)
- [ ] Can access OAuthConfig.swift in your project
- [ ] Know what "invalid address" error you're seeing

---

## 📊 Expected Outcomes

### If redirect_uri is WRONG:
✅ Fix will be simple:
1. Update Google Console
2. Or fix Info.plist
3. Recompile
4. ✓ Done

### If redirect_uri is RIGHT:
✅ Bruno tests will show where problem actually is:
- Missing URL scheme in Info.plist?
- Wrong PKCE parameter?
- OAuth2 flow logic error?

### If everything is CORRECT:
✅ Bruno POST to token endpoint will return:
```json
{
  "access_token": "ya29...",
  "refresh_token": "1//0...",
  ...
}
```

Then issue is in app's token handling, not OAuth2 config.

---

## 🔍 Key Concepts

### redirect_uri (THE CRITICAL PART)
- Must be registered exact match in Google Console
- Must be listed in app's Info.plist URL schemes
- Must match what OAuthConfig.redirectURI computes
- Format: `com.googleusercontent.apps.25887787070-g1q6h2806850edpgllg3eboeot43e79p:/oauthredirect`
- ⚠️ NO SPACES, NO TYPOS, NO EXTRA SLASHES

### PKCE (Proof Key for Code Exchange)
- Increases security for iOS apps
- Two values: code_verifier and code_challenge
- Generated randomly each time
- Must be kept consistent through OAuth flow

### Bruno Collection
- Reusable HTTP requests for testing
- No code needed
- Just fill in parameters
- Can test entire OAuth flow manually

---

## 🐛 Most Common Mistakes

1. ❌ `redirect_uri` has extra space or typo
2. ❌ `redirect_uri` in Google Console ≠ app value
3. ❌ Info.plist missing URL scheme entirely
4. ❌ Using `://` instead of `:/` (double slash wrong!)
5. ❌ Copying code_verifier wrong in Bruno request
6. ❌ Letting auth code expire before exchanging it

---

## 📞 If Stuck

**Where to look in order:**

1. ❌ "Invalid address" error?
   → `REDIRECT_URI_VERIFICATION.md`

2. ❌ Don't know how to use Bruno?
   → `BRUNO_QUICK_START.md`

3. ❌ Bruno request fails?
   → `OAUTH2_DEBUG_GUIDE.md` → "Phase 4: Common Issues"

4. ❌ Not sure what to do next?
   → `QUICK_FIX_PLAN.md` → Follow timeline

5. ❌ Want to understand entire flow?
   → `OAUTH2_DEBUG_GUIDE.md` → Read all phases

---

## 🎓 Learning Path

If you're new to OAuth2, best order:

1. **Overview:** Read `QUICK_FIX_PLAN.md` intro (2 min)
2. **Deep dive:** Read `REDIRECT_URI_VERIFICATION.md` (5 min)
3. **Tutorial:** Read `BRUNO_QUICK_START.md` (10 min)
4. **Practice:** Run through Bruno steps (15 min)
5. **Reference:** Keep `OAUTH2_DEBUG_GUIDE.md` open (as needed)

---

**READY TO START?**

👉 **Next step:** Open `QUICK_FIX_PLAN.md` and follow minutes 0-5

---

**Last Updated:** April 21, 2026  
**Difficulty:** Intermediate (but guides are beginner-friendly)  
**Time to Solution:** 30-60 minutes depending on issue severity
