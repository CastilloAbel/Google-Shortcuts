# Actions App Analysis - Sindre Sorhus
**App Store:** [https://apps.apple.com/es/app/actions/id1586435171](https://apps.apple.com/es/app/actions/id1586435171)  
**Developer Website:** [https://sindresorhus.com/actions](https://sindresorhus.com/actions)  
**Developer:** Sindre Sorhus  
**Price:** Free (no ads)  
**Platforms:** iOS, macOS, visionOS  
**Total Actions:** 180+

---

## 1. Overview & Value Proposition

### What Makes Actions Valuable:

1. **Fills Critical Gaps in Shortcuts**
   - Provides actions that "should come with the OS by default"
   - Extends Apple's native Shortcuts with 180+ powerful actions
   - Highly maintained and constantly updated with community feedback

2. **Deeply Integrated with Shortcuts App**
   - Actions appear as native Shortcuts actions after app launch + device restart
   - Not exclusive - all actions work within the standard Shortcuts app
   - No workaround needed once installed

3. **Device Capabilities Exposed**
   - Access to system-level data normally restricted by iOS/macOS
   - Low-level hardware information (battery, device motion, Bluetooth, etc.)
   - Networking and connectivity state
   - User and device preferences

---

## 2. Action Categories & Comprehensive List

### A. **Text & String Manipulation** (15+ actions)
- `Ask for Input with Dialog` - Dialog with text field, buttons, timeout, custom icons
- `Ask for Duration` - Input dialog for duration values
- `Ask for Text with Timeout` - Time-limited text input
- `Format Text List` - Convert lists to natural language ("A, B, and C")
- `Format Person Name` - Format names by different conventions
- `Remove Emojis` - Strip emoji characters
- `Remove Non-Printable Characters` - Clean text data
- `Trim Whitespace` - Remove leading/trailing whitespace
- `Transform Text` - Multiple transformations:
  - Camel case, Pascal case, Snake case, Constant case, Dash case
  - Slugify, Strip punctuation, Strip HTML, Strip diacritics
  - JSON Escape, Transliterate (Latin, Arabic, Cyrillic, Greek, Hebrew, Hangul, Hiragana, Thai, Mandarin)
- `Transform Text with JavaScript` - Custom JS transformations
- `Spell Out Number` - Convert numbers to words
- `Truncate Text` - Shorten text intelligently
- `Write or Edit Text` - Text editing interface
- `Parse CSV` / `Generate CSV` - CSV handling
- `Parse Markdown Table` / `Make Markdown Table` - Markdown table operations
- `Remove Duplicate Lines` - Text deduplication
- `Reverse Lines` - Reverse text line order

### B. **List & Dictionary Operations** (20+ actions)
- `Add to List` - Append items to lists
- `Combine Lists` - Merge multiple lists
- `Filter List` - Filter with conditions
- `Filter List of Dictionaries` - Advanced dictionary filtering
- `Sort List` / `Sort List of Dictionaries` - Sort by various criteria
- `Remove Duplicates from List` - Deduplication
- `Remove from List` - Remove specific items
- `Shuffle List` - Randomize list order
- `Reverse List` - Reverse order
- `Transform Lists` - Transform list items
- `Truncate List` - Limit list size
- `Get Index of List Item` - Find position
- `Merge Dictionaries` - Combine dictionaries
- `Invert Dictionary` - Swap keys and values
- `Remove Dictionary Values` - Delete specific values
- `Set Dictionary Value Using JSONPath` - JSONPath operations
- `Get Values Using JSONPath` - Extract nested values
- `Pretty Print Dictionaries` - Format output
- `Sort Months` - Specialized month sorting

### C. **Number & Math Operations** (15+ actions)
- `Clamp Number` - Constrain to range
- `Round Number to Decimal Places` - Precise rounding
- `Round Number to Multiple` - Round to nearest multiple
- `Truncate Number` - Remove decimals
- `Convert Number Base` - Binary, Octal, Decimal, Hexadecimal
- `Hex Encode` - Hexadecimal encoding
- `Generate Random Data` - Random value generation
- `Generate Random Text` - Custom random strings
- `Generate Random Number from Seed` - Seeded randomness
- `Get Random Boolean` - Random true/false
- `Get Random Color` - Random color generation
- `Get Random Date and Time` - Random timestamps
- `Get Random Emoticon` - Random emoji
- `Get Random Floating-Point Number` - Random decimals
- `Format Number as Ordinal` - (1st, 2nd, 3rd)
- `Format Number — Compact` - Abbreviate large numbers (1M, 2K)
- `Format Currency` - Currency formatting

### D. **Date & Time Operations** (10+ actions)
- `Convert Date to Unix Timestamp` - Timestamp conversion
- `Convert Unix Timestamp to Date` - Reverse conversion
- `Convert Date to Reference Timestamp` - Reference timestamp
- `Convert Reference Timestamp to Date` - Reference conversion
- `Get Dates in Range` - Generate date sequences (e.g., all Mondays in a month)
- `Create Duration` - Duration object creation
- `Format Duration` - Format time durations
- `Format Date Difference` - Difference calculations
- `Get Random Date and Time` - Random date generation
- `Is Time` - Time validation
- `Is Time In Range` - Check if time within range
- `Is Day` - Check specific day type
- `Wait Milliseconds` - Precise timing control

### E. **File Operations** (15+ actions)
- `Download File` - Fetch and save files
- `Write or Edit Text` - File content creation/editing
- `Overwrite File` - Replace file contents
- `Get File Path` - File path handling
- `Set Creation and Modification Date of File` - File metadata
- `Get File Extension Visibility` (macOS) - Check extension visibility
- `Set File Icon` (macOS) - Custom file icons
- `Get File Tags` / `Set File Tags` - File tagging (macOS)
- `Get Uniform Type Identifier` / `Set Uniform Type Identifier` - File type info
- `Create URL Shortcut File` - .url/.webloc shortcut files (macOS)
- `Create Temporary Folder` - Temporary storage
- `Scan Documents` (iOS) - Document scanning
- `Encrypt File` / `Encrypt Text` - Encryption operations
- `Convert Text File Encoding` - UTF-8, Shift-JIS, Windows-1252, etc.
- `Overwrite File` - File replacement

### F. **Network & URL Operations** (15+ actions)
- `Create URL` - URL construction
- `Edit URL` - Modify URL components
- `Download File` - Network file retrieval
- `Get Contents of URL (Extended)` - Enhanced HTTP requests:
  - Complete response details
  - Status codes, headers
  - All HTTP methods
  - Timeout support
- `Open URLs in Safari` - Browser opening
- `Open URLs with App` (macOS) - App-specific opening
- `Get Title of URL` - Extract page title
- `Get Meta Tags of URL` - Extract metadata (title, description, Open Graph, etc.)
- `Get Image URLs from Web Page` - Extract image URLs without downloading
- `Get Images from Web Page` - Download and return page images
- `Get Query Item Value from URL` - Extract URL parameters
- `Get Query Items from URL` - All query parameters
- `Get Query Items from URL as Dictionary` - Query as key-value pairs
- `Is Web Server Reachable` - Server connectivity check
- `Get Host Reachable` / `Is Host Reachable` - Network reachability
- `Is Online` - Internet connection check

### G. **Device Information & Status** (25+ actions)
**Battery & Power:**
- `Get Battery State` - Detailed battery info (level, charging, etc.)
- `Is Low Power Mode On` - Check low power mode status
- `Get Device Details (Extended)` - Comprehensive device info:
  - Uptime (with/without sleep)
  - Active processor count
  - Physical memory
  - Thermal state
  - Total/available storage
  - Time zone, hostname
  - Battery condition (macOS)
  - Serial number (macOS)

**Connectivity:**
- `Is Bluetooth On` - Bluetooth status
- `Get Bluetooth Device` - Specific device info
- `Get Bluetooth Devices` - All paired devices
- `Is Wi-Fi On` (macOS) - WiFi status
- `Join Wi-Fi` (iOS) - Connect to WiFi network
- `Find Wi-Fi Network` (macOS) - Available networks
- `Is Connected to VPN` (iOS) - VPN connection status
- `Is Cellular Data On` - Mobile data status
- `Is Cellular Low Data Mode On` - Low data mode check

**Device State & Sensors:**
- `Get Device Orientation` - Current orientation
- `Is Device Orientation` - Check specific orientation
- `Get Device Motion Activity` - Activity type (walking, running, cycling, etc.)
- `Get Device Motion Data` (iOS) - Motion sensor data
- `Get Compass Heading` (iOS) - Direction/compass heading
- `Get Elevation` (iOS) - Altitude data
- `Is Device Moving` - Motion detection
- `Is Shaking Device` - Shake gesture detection
- `Is Device Locked` - Lock screen status
- `Get High-Resolution Timestamp` - Nanosecond precision timing

**Audio & Media:**
- `Get Audio Playback Destination` (iOS) - Which device audio plays on
- `Is Audio Playing` (iOS) - Current playback status
- `Is Silent Mode On` (iOS) - Silent switch status

**Calling & Communication:**
- `Is Call Active` (iOS) - Phone call detection

**User & System Settings:**
- `Get User Details` - User information:
  - Username (macOS), Full name
  - Given name, Family name, Initials
  - Shell, Language code
  - Idle time (macOS), Administrator status (macOS)
- `Is Accessibility Feature On` - Accessibility status check
- `Is Dark Mode On` - Dark mode detection
- `Is Screen Locked` (macOS)
- `Is Screen Saver Active` - Screensaver status
- `Get Default Browser` (macOS) - Default browser app

**Location & Maps:**
- `Convert Coordinates to Location` - Geocoding
- `Convert Location to Geo URI` - Location URIs
- `Find Points of Interest` - Nearby places by query
- `Calculate Distance` - Distance between locations
- `Calculate Bearing` - Compass direction between coordinates
- `Get Map Image of Location` - Map visualization
- `Find Music Playlist` (iOS) - Music library playlists
- `Find Workout` (iOS) - Health app workouts (type, duration, metrics)
- `Is Location Services Enabled` - Location permission check

### H. **Image & Visual Operations** (15+ actions)
- `Create Color Image` - Solid color image generation
- `Create Gradient Color Image` - Gradient creation
- `Blur Images` - Image blurring
- `Invert Images` - Color inversion
- `Get Average Color` - Extract dominant color
- `Get Average Color of Image` - Per-image color extraction
- `Get Dominant Colors of Image` - Multiple color extraction
- `Overlay Image (Extended)` - Image compositing:
  - Blend modes
  - Opacity control
  - Rotation, flipping
  - Precise positioning
- `Get Image Capture Date` / `Set Image Capture Date` - EXIF manipulation
- `Get Image Location` / `Set Image Location` - Geolocation metadata
- `Get Image URLs from Web Page` - Web scraping (images)
- `Get Images from Web Page` - Download page images
- `Scan QR Codes in Image` - QR code detection/decoding
- `Scan Barcodes in Image` - Barcode recognition
- `Pick Color` - System color picker
- `Sample Color from Screen` (macOS) - Eyedropper
- `Get SF Symbol Image` - Apple's SF Symbol library access
- `Get All System Colors` - macOS system color palette
- `Get System Color` - Specific system colors
- `Show Black Screen` (iOS) - Black screen display
- `Get Raw Media Metadata` - Detailed media information
- `Get Media Metadata` - Standard media info
- `Flash Screen` (macOS) - Screen flash effect

### I. **Color Operations** (5+ actions)
- `Color` - Color value handling
- `Pick Color` - Color picker
- `Get Random Color` - Random color generation
- `Get All System Colors` - System color access
- `Get Average Color` / `Get Dominant Colors of Image` - Color extraction

### J. **Utility & Automation** (20+ actions)
- `Boolean` - Boolean logic
- `Get Boolean from Input` - Parse boolean values
- `Toggle Boolean` - Flip boolean state
- `Authenticate` - Authentication flow
- `Generate Haptic Feedback` (iOS) - Vibration control
- `Show Notification` - Display native notifications
- `Create Menu Item` - Dynamic menu creation
- `Choose from List (Extended)` - Enhanced list selection
- `Calculate with Soulver` - Advanced calculations
- `Generate UUID` - Unique identifier generation
- `Generate Emojis` - Emoji generation
- `Get Emojis` - Emoji library access
- `Global Variable` - Variable storage & management
- `Keychain` - Secure credential storage:
  - API keys, tokens, passwords
  - Synced across devices
  - Secure storage
- `Manage Shortcut Lock` - Prevent concurrent execution
- `Counter` - Atomic counter for concurrency:
  - Avoid race conditions
  - Rate limiting
  - Progress tracking
- `Hide Shortcuts App` - Background execution
- `Open URLs in Safari` - Browser control
- `Get Related Words` - Thesaurus/word relations
- `Get Sentences from Text` - Text parsing
- `Get Paragraphs from Text` - Text segmentation

### K. **Notification & Communication** (5+ actions)
- `Show Notification` - Native notifications
- `Send Distributed Notification` (macOS) - Inter-app notifications
- `Wait for Distributed Notification` (macOS) - Event listening
- `Ask for Input with Dialog` - Dialog boxes
- `Show Black Screen` (iOS) - Visual alerts

### L. **System Printing & Hardware** (macOS-only)
- `Get Printers` (macOS) - Available printers
- `Get/Set Default Printer` (macOS) - Printer management

### M. **Special / Advanced** (10+ actions)
- `Use System Font in Rich Text` - Rich text formatting
- `Named Clipboard` (macOS) - Multiple clipboard management
- `Get Running Apps` (macOS) - Process listing
- `Get Modifier Key State` (macOS) - Keyboard modifier state
- `Play Alert Sound` (macOS) - System sounds
- `Is Camera On` (macOS) - Camera in use detection
- `Is Microphone On` (macOS) - Microphone monitoring
- `Make Live Photo from Video` - Live photo creation
- `Ask for Duration` - Duration picker

---

## 3. Device & System Capabilities Exposed

### **Hardware Access:**
- ✅ Battery status (level, charging, health)
- ✅ Device motion (accelerometer, gyroscope)
- ✅ Compass/heading data
- ✅ Elevation/altitude
- ✅ Thermal state
- ✅ Camera/microphone status (macOS)
- ✅ Bluetooth device listing & status
- ✅ WiFi network information
- ✅ Device orientation
- ✅ Storage capacity (total & available)
- ✅ Memory information (RAM, processors)

### **Network & Connectivity:**
- ✅ WiFi status & network details
- ✅ Cellular data state
- ✅ VPN connection status
- ✅ Internet connectivity check
- ✅ Host/server reachability
- ✅ Low data mode status

### **User & System Settings:**
- ✅ Dark mode detection
- ✅ Low power mode status
- ✅ Accessibility features status
- ✅ Silent mode (iOS)
- ✅ Location services enabled
- ✅ User information (name, username, language)
- ✅ Device lock status
- ✅ Screen saver active status
- ✅ Time zone, hostname, uptime

### **Sensors & Location:**
- ✅ GPS/geolocation
- ✅ Device motion activity (walking, running, cycling, etc.)
- ✅ Shake detection
- ✅ Motion data (acceleration)
- ✅ Compass heading
- ✅ Elevation data

### **Media & Content:**
- ✅ Image EXIF data (date, location)
- ✅ Audio playback destination
- ✅ Health app integration (workouts, metrics)
- ✅ Music library (playlists)
- ✅ QR code/barcode scanning
- ✅ Image metadata & color analysis

### **Limitations (NOT Possible):**
- ❌ Orientation lock status
- ❌ Flashlight control/status
- ❌ Ambient light sensor info
- ❌ Flight mode status
- ❌ Hotspot status/control
- ❌ All audio destinations (only current)
- ❌ CarPlay connection status
- ❌ Notifications in CarPlay
- ❌ Media volume control
- ❌ Advanced accessibility checks (reduce white point)
- ❌ Wireless charging detection
- ❌ General system settings changes (Apple restriction)

---

## 4. How Actions Are Organized

### **Integration with Shortcuts:**
1. **Seamless Integration**
   - ALL actions appear as native categories in the Shortcuts app
   - Not exclusive - freely available to any shortcut
   - Located alongside Apple's built-in actions

2. **Organization in Shortcuts App:**
   - Actions grouped by functional category
   - Searchable by name
   - Full documentation/descriptions available in Shortcuts

3. **Action Metadata:**
   - Each action has parameters and return types
   - Tooltip descriptions in Shortcuts builder
   - Examples available via Shortcuts UI

4. **Categories (Logical Grouping):**
   - **Text & Formatting**
   - **List & Dictionary**
   - **Math & Numbers**
   - **Date & Time**
   - **File Operations**
   - **Network & URLs**
   - **Device Info & System**
   - **Images & Colors**
   - **Media & Scanning**
   - **Utilities & Helpers**
   - **Automation & Control**

---

## 5. Availability: Shortcuts App Integration

### **Key Points:**
- ✅ **Available in Shortcuts** - NOT exclusive to Actions app
- ✅ **Native Integration** - Actions appear as first-class Shortcuts actions
- ✅ **Cross-Platform** - iOS, macOS, visionOS support
- ✅ **No Workarounds** - Direct integration via URL schemes
- ✅ **Always Up-to-Date** - Automatic updates ensure new actions available

### **How to Use:**
1. Install "Actions" app from App Store
2. Launch the app once
3. Restart device (iOS bug workaround)
4. All 180+ actions automatically appear in Shortcuts app
5. Use like any other Shortcuts action

---

## 6. Why Actions App is Valuable as Shortcuts Complement

### **Gap Filling:**
1. **Native Shortcuts Lacks:**
   - Deep device information access
   - Advanced text transformations
   - URLPath/JSONPath querying
   - Atomic operations (counters, locks)
   - Keychain access for secrets
   - Comprehensive date range generation
   - Advanced image manipulation

2. **Pro Features Provided:**
   - Secure credential storage (Keychain)
   - Concurrency control (atomic counters, locks)
   - Advanced data manipulation (JSONPath, CSV, Markdown)
   - System monitoring (battery, motion, connectivity)
   - Device status checks
   - Enhanced HTTP capabilities
   - Image metadata manipulation

### **Development Support:**
- **Active Development** - Constant updates with community feedback
- **180+ Actions** - Massively expanded action library
- **Responsive Dev** - Sindre Sorhus actively addresses requests
- **Free & No Ads** - No monetization barriers
- **Open Source** - Transparent, community-driven
- **Quality** - Highly rated (5/5 on App Store)

### **Use Cases Enabled:**
1. **System Monitoring Automations**
   - Battery-based triggers
   - Motion-triggered actions
   - Network state automations
   - Location-based logic

2. **Data Processing**
   - JSON/CSV transformation
   - Advanced text processing
   - Markdown generation
   - Dictionary operations

3. **Secure Workflows**
   - API key storage
   - Token management
   - Password handling

4. **Advanced Integrations**
   - Web scraping (image/meta extraction)
   - QR/barcode scanning
   - HTTP with full control

5. **Timing & Concurrency**
   - Millisecond precision timing
   - Race condition prevention
   - Counter-based rate limiting

---

## 7. Comparison with Toolbox Pro (Shortcut Competitor)

### **Toolbox Pro for Shortcuts:**
- Similar concept (additional actions)
- Paid ($9.99)
- Partially exclusive features
- Company: Simon B. Støvring

### **Actions App (This Analysis):**
- Free with no ads
- All actions available in native Shortcuts
- By Sindre Sorhus (prolific Apple dev)
- More actively maintained
- Focus on missing native capabilities

---

## 8. Integration Recommendations for Gmail Shortcuts iOS App

### **Applicable Patterns:**
1. **Use Keychain Action** for secure token storage
2. **Implement Concurrency Controls** using Counter/Lock actions
3. **Leverage Device Motion** for gesture-based triggers
4. **Access Battery State** for intelligent task scheduling
5. **Query Network Status** before heavy operations
6. **Use Haptic Feedback** for user feedback
7. **Generate UUIDs** for operation tracking
8. **Store Global Variables** for state management

### **Features to Consider:**
- Dark mode detection for UI adaptation
- Location services status check
- VPN detection for security decisions
- Device motion for shake/gesture recognition
- Wifi network detection for quality decisions
- Notification integration for alerts
- Clipboard operations for data exchange

---

## 9. Complete Action Count Summary

- **Total Actions:** 180+
- **Text Operations:** 15+
- **List/Dictionary:** 20+
- **Numbers/Math:** 15+
- **Date/Time:** 10+
- **File Ops:** 15+
- **Network/URL:** 15+
- **Device Info:** 25+
- **Image/Visual:** 15+
- **Colors:** 5+
- **Utility/Automation:** 20+
- **Notifications:** 5+
- **System/Hardware:** 5+ (macOS specific)
- **Advanced:** 10+

---

## 10. Sources

- **App Store:** https://apps.apple.com/es/app/actions/id1586435171
- **Developer Site:** https://sindresorhus.com/actions
- **GitHub Privacy Policy:** https://github.com/sindresorhus/privacy-policy/blob/main/actions.md
- **Actions GPT Bot:** https://chatgpt.com/g/g-6746353a017881918cceb0761aea3bfe-actions-app-companion
- **Raw Data (MD):** https://gist.github.com/sindresorhus/fbba65a774fb9da915e624807a02a6d2
