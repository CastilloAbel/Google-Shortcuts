#!/usr/bin/env python3
"""
OAuth2 PKCE Code Generator for Bruno HTTP Client Testing
Run: python3 generate_pkce.py
"""

import secrets
import hashlib
import base64

def generate_pkce():
    """Generate PKCE code_verifier and code_challenge (S256)"""
    
    # Generate random 32 bytes and encode as base64url (without padding)
    code_verifier = base64.urlsafe_b64encode(
        secrets.token_bytes(32)
    ).decode('utf-8').rstrip('=')
    
    # Create SHA256 hash of verifier
    sha256_digest = hashlib.sha256(code_verifier.encode()).digest()
    
    # Encode as base64url (without padding)
    code_challenge = base64.urlsafe_b64encode(
        sha256_digest
    ).decode('utf-8').rstrip('=')
    
    return {
        'code_verifier': code_verifier,
        'code_challenge': code_challenge,
        'code_challenge_method': 'S256'
    }

def main():
    print("\n" + "="*70)
    print("🔐 OAuth2 PKCE Code Generator")
    print("="*70 + "\n")
    
    pkce = generate_pkce()
    
    print("📋 Generated PKCE Values:\n")
    print(f"code_verifier:")
    print(f"  {pkce['code_verifier']}")
    print(f"\n  Length: {len(pkce['code_verifier'])} characters ✓\n")
    
    print(f"code_challenge:")
    print(f"  {pkce['code_challenge']}")
    print(f"\n  Method: {pkce['code_challenge_method']} ✓\n")
    
    print("="*70)
    print("📝 INSTRUCTIONS FOR BRUNO:\n")
    
    print("1. STEP 1 - Get Authorization Code")
    print("   URL (copy-paste into browser):\n")
    
    auth_url = (
        f"https://accounts.google.com/o/oauth2/v2/auth?"
        f"client_id=25887787070-g1q6h2806850edpgllg3eboeot43e79p.apps.googleusercontent.com&"
        f"redirect_uri=com.googleusercontent.apps.25887787070-g1q6h2806850edpgllg3eboeot43e79p:/oauthredirect&"
        f"response_type=code&"
        f"scope=email%20profile%20https://www.googleapis.com/auth/gmail.send%20https://www.googleapis.com/auth/gmail.readonly&"
        f"code_challenge={pkce['code_challenge']}&"
        f"code_challenge_method={pkce['code_challenge_method']}"
    )
    
    # Print with line breaks for readability
    print(auth_url)
    print("\n   When you see Safari error or redirect, check address bar for code parameter\n")
    
    print("2. STEP 2 - Exchange Code for Token (Bruno POST Request)")
    print("   URL: https://oauth2.googleapis.com/token")
    print("   Body (x-www-form-urlencoded):\n")
    
    token_body = f"""code=<PASTE_CODE_FROM_STEP_1>
client_id=25887787070-g1q6h2806850edpgllg3eboeot43e79p.apps.googleusercontent.com
redirect_uri=com.googleusercontent.apps.25887787070-g1q6h2806850edpgllg3eboeot43e79p:/oauthredirect
grant_type=authorization_code
code_verifier={pkce['code_verifier']}"""
    
    print(token_body)
    print("\n" + "="*70)
    print("✅ SAVE THESE VALUES!\n")
    
    print(f"code_verifier: {pkce['code_verifier']}")
    print(f"code_challenge: {pkce['code_challenge']}\n")
    
    print("These expire after OAuth2 session completes.")
    print("Run this script again to generate new values.\n")
    print("="*70 + "\n")

if __name__ == '__main__':
    main()
