# GitHub Repository Setup Guide

## 1. Create the Repository on GitHub

### Option A: Using GitHub Web Interface
1. Go to [GitHub.com](https://github.com) and sign in
2. Click the **"+"** icon in the top right → **"New repository"**
3. Fill in the details:
   - **Repository name**: `beear-cars-wash` (or `beear_cars_wash`)
   - **Description**: "B2B on-site car wash service mobile app for Beear Cars Wash"
   - **Visibility**: Choose **Private** (recommended for business apps) or **Public**
   - **Initialize repository**: 
     - ❌ **DO NOT** check "Add a README file"
     - ❌ **DO NOT** check "Add .gitignore" (we already have one)
     - ❌ **DO NOT** check "Choose a license" (we'll add it manually)
4. Click **"Create repository"**

### Option B: Using GitHub CLI (if installed)
```bash
gh repo create beear-cars-wash --private --description "B2B on-site car wash service mobile app"
```

## 2. Initialize Git and Push Code

### Step 1: Initialize Git (if not already done)
```bash
cd c:\Users\aicoIntern5\beear_cars_wash
git init
```

### Step 2: Add All Files
```bash
git add .
```

### Step 3: Create Initial Commit
```bash
git commit -m "Initial commit: Project bootstrap with Flutter, Firebase setup, and core architecture"
```

### Step 4: Add Remote Repository
Replace `YOUR_USERNAME` with your GitHub username:
```bash
git remote add origin https://github.com/YOUR_USERNAME/beear-cars-wash.git
```

Or if using SSH:
```bash
git remote add origin git@github.com:YOUR_USERNAME/beear-cars-wash.git
```

### Step 5: Push to GitHub
```bash
git branch -M main
git push -u origin main
```

## 3. Add License

### Recommended License: MIT License

**Why MIT?**
- Simple and permissive
- Allows commercial use
- Good for business applications
- Widely recognized and trusted

### Steps to Add License:

1. Create `LICENSE` file in the root directory:
```bash
# In the project root
New-Item -ItemType File -Path LICENSE
```

2. Add MIT License content (see below)

3. Commit and push:
```bash
git add LICENSE
git commit -m "Add MIT License"
git push
```

### MIT License Template

```
MIT License

Copyright (c) 2025 Beear Cars Wash

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### Alternative Licenses (if needed)

- **Apache 2.0**: More detailed, includes patent grant
- **Proprietary**: For closed-source commercial apps (no license file, just copyright notice)

## 4. Update .gitignore

Make sure your `.gitignore` includes (Flutter should have created this):

```
# Firebase config files (IMPORTANT - keep these private!)
android/app/src/dev/google-services.json
android/app/src/prod/google-services.json
ios/Runner/GoogleService-Info-Dev.plist
ios/Runner/GoogleService-Info-Prod.plist

# Android signing keys
android/key.properties
android/app/keystore.jks
*.jks
*.keystore

# Other standard Flutter ignores
...
```

## 5. Create README.md

Create a basic README.md in the root:

```markdown
# Beear Cars Wash

B2B on-site car wash service mobile app for Beear Cars Wash.

## Tech Stack

- Flutter 3.x
- Firebase (Auth, Firestore, Cloud Messaging)
- Riverpod (State Management)
- Google Maps

## Setup

See [docs/PHASE_1_COMPLETE.md](docs/PHASE_1_COMPLETE.md) for setup instructions.

## License

MIT License - see [LICENSE](LICENSE) file for details.
```

## 6. Future Git Workflow

### Daily Workflow
```bash
# Check status
git status

# Add changes
git add .

# Commit with descriptive message
git commit -m "Feature: Add authentication flow"

# Push to remote
git push
```

### Branch Strategy (Recommended)
```bash
# Create feature branch
git checkout -b feature/authentication

# Work on feature, commit changes
git add .
git commit -m "Implement login screen"

# Push branch
git push -u origin feature/authentication

# Create Pull Request on GitHub, then merge to main
```

## 7. Important Notes

### ⚠️ Never Commit:
- Firebase config files (`google-services.json`, `GoogleService-Info.plist`)
- Android signing keys (`.jks`, `.keystore`)
- API keys or secrets
- `local.properties` (Android SDK paths - personal to each machine)

### ✅ Always Commit:
- Source code
- Configuration files (without secrets)
- Documentation
- License file

## 8. Troubleshooting

### If you get "remote origin already exists":
```bash
git remote remove origin
git remote add origin https://github.com/YOUR_USERNAME/beear-cars-wash.git
```

### If you need to update remote URL:
```bash
git remote set-url origin https://github.com/YOUR_USERNAME/beear-cars-wash.git
```

### To check current remote:
```bash
git remote -v
```

