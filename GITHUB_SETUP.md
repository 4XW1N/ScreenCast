# GitHub Setup Guide (Linux)

## Quick Start - Automated Script

```bash
cd /home/aswin/ScreenCast
./setup_github.sh
```

This script will:
1. Configure Git user
2. Generate SSH key (if needed)
3. Show you the public key to add to GitHub
4. Create the repository
5. Push your code

---

## Manual Steps (if script fails)

### 1. Configure Git
```bash
git config --global user.name "Your GitHub Username"
git config --global user.email "your@email.com"
```

### 2. Generate SSH Key
```bash
ssh-keygen -t ed25519 -C "your@email.com"
# Press Enter 3 times (accept defaults, no passphrase)
```

### 3. Add SSH Key to GitHub
```bash
cat ~/.ssh/id_ed25519.pub
# Copy the ENTIRE output
```
Then:
1. Go to **GitHub.com → Settings (top right) → SSH and GPG keys**
2. Click **"New SSH key"**
3. Title: "Linux Machine" (or whatever)
4. Paste the key → **"Add SSH key"**

### 4. Test Connection
```bash
ssh -T git@github.com
# Should say: "Hi username! You've successfully authenticated..."
```

### 5. Create GitHub Repo
1. Go to: **https://github.com/new**
2. Repository name: `ScreenCast`
3. **Uncheck** "Add a README file"
4. **Uncheck** "Add .gitignore"
5. Click **"Create repository"**

### 6. Push Code
```bash
cd /home/aswin/ScreenCast

# Initialize (if not done)
git init
git add .
git commit -m "Initial commit: ScreenCast Android+iOS screen casting"

# Add remote (replace YOURUSER with your GitHub username)
git remote add origin git@github.com:YOURUSER/ScreenCast.git
git branch -M main
git push -u origin main
```

---

## GitHub CLI Alternative (easiest if installed)

```bash
# Install GitHub CLI
sudo apt update && sudo apt install gh  # Ubuntu/Debian
# OR
sudo dnf install gh  # Fedora
# OR
sudo pacman -S github-cli  # Arch

# Login
gh auth login
# Choose: GitHub.com → SSH → Upload key → Login with browser

# Create repo and push in ONE command
cd /home/aswin/ScreenCast
gh repo create ScreenCast --public --source=. --remote=origin --push
```

---

## After Push - Trigger Builds

1. Go to: `https://github.com/YOURUSER/ScreenCast/actions`
2. Click **"Build iOS App"** → **"Run workflow"** → **"Run workflow"**
3. Click **"Build Android App"** → **"Run workflow"** → **"Run workflow"**

### For Signed iOS (TestFlight)
Add these **Repository Secrets** (Settings → Secrets → Actions → New repository secret):

| Secret Name | Value |
|-------------|-------|
| `DEVELOPMENT_TEAM` | Your 10-char Team ID (from Apple Developer) |
| `APP_STORE_CONNECT_ISSUER_ID` | From App Store Connect → Users → Keys |
| `APP_STORE_CONNECT_API_KEY_ID` | Key ID from above |
| `APP_STORE_CONNECT_API_PRIVATE_KEY` | Run: `base64 -i AuthKey_XXXX.p8 \| tr -d '\n'` |

---

## Troubleshooting

### "Permission denied (publickey)"
- SSH key not added to GitHub correctly
- Run: `ssh-add ~/.ssh/id_ed25519`
- Check: `ssh -vT git@github.com`

### "Repository not found"
- Wrong username in remote URL
- Check: `git remote -v`
- Fix: `git remote set-url origin git@github.com:CORRECT_USER/ScreenCast.git`

### "Push rejected"
- Repo has files you don't have locally
- Fix: `git pull origin main --rebase` then `git push`

### Need HTTPS instead of SSH?
```bash
git remote set-url origin https://github.com/YOURUSER/ScreenCast.git
# Then use Personal Access Token as password
# Generate at: https://github.com/settings/tokens
```

---

## Verify Everything Works

```bash
# Check remotes
git remote -v

# Check latest commit
git log --oneline -1

# Check GitHub Actions
# https://github.com/YOURUSER/ScreenCast/actions
```