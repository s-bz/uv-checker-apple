# Fastlane for UV Sense

This directory contains Fastlane configuration for UV Sense app store management.

## Setup

1. Install Fastlane:
   ```bash
   sudo gem install fastlane -NV
   ```

2. Ensure you have the App Store Connect API key file:
   ```
   fastlane/AuthKey_8VSJP9VH9U.p8
   ```

## Available Lanes

### `fastlane upload_metadata`
Uploads app metadata (description, keywords, etc.) to App Store Connect without uploading a binary.

### `fastlane download_metadata` 
Downloads current metadata from App Store Connect to local files.

### `fastlane validate_metadata`
Validates metadata locally without uploading to App Store Connect.

## Metadata

All metadata is stored in `fastlane/metadata/en-US/` and includes:

- `name.txt` - App name
- `subtitle.txt` - App subtitle 
- `description.txt` - App Store description
- `keywords.txt` - App Store keywords
- `promotional_text.txt` - Promotional text
- `release_notes.txt` - What's new text
- `support_url.txt` - Support website
- `marketing_url.txt` - Marketing website 
- `privacy_url.txt` - Privacy policy URL

## Usage

To upload metadata changes:
```bash
cd /Users/samb/GitHub/UVchecker
fastlane upload_metadata
```

To download current App Store metadata:
```bash
cd /Users/samb/GitHub/UVchecker  
fastlane download_metadata
```

## Authentication

This setup uses App Store Connect API key authentication with:
- Key ID: `8VSJP9VH9U`
- Issuer ID: `96360dc0-b595-4e99-97d8-0f5672d1f012`
- Team ID: `YH2Y8LT5HT`
- App ID: `com.infuseproduct.UVchecker`