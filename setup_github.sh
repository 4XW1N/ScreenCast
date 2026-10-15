#!/bin/bash
# GitHub Setup & Push Script for Linux
# Run this script and follow the prompts

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== ScreenCast GitHub Setup ===${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "README.md" ] || [ ! -d "Android" ] || [ ! -d "iOS" ]; then
    echo -e "${RED}Error: Run this from /home/aswin/ScreenCast directory${NC}"
    exit 1
fi

# Step 1: Check Git config
echo -e "${YELLOW}Step 1: Checking Git configuration...${NC}"
GIT_NAME=$(git config --global user.name 2>/dev/null || echo "")
GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

if [ -z "$GIT_NAME" ] || [ -z "$GIT_EMAIL" ]; then
    echo -e "${YELLOW}Git user not configured. Let's set it up:${NC}"
    read -p "Enter your GitHub username: " GIT_NAME
    read -p "Enter your GitHub email: " GIT_EMAIL
    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"
    echo -e "${GREEN}✓ Git user configured${NC}"
else
    echo -e "${GREEN}✓ Git user: $GIT_NAME <$GIT_EMAIL>${NC}"
fi

# Step 2: Check for SSH key
echo ""
echo -e "${YELLOW}Step 2: Checking SSH key...${NC}"
SSH_KEY="$HOME/.ssh/id_ed25519"
if [ -f "$SSH_KEY" ]; then
    echo -e "${GREEN}✓ SSH key exists: $SSH_KEY${NC}"
else
    echo -e "${YELLOW}No SSH key found. Creating one...${NC}"
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY" -N ""
    echo -e "${GREEN}✓ SSH key created${NC}"
fi

# Step 3: Show public key for GitHub
echo ""
echo -e "${YELLOW}Step 3: Add this SSH key to GitHub:${NC}"
echo -e "${BLUE}----------------------------------------${NC}"
cat "$SSH_KEY.pub"
echo -e "${BLUE}----------------------------------------${NC}"
echo ""
echo "1. Copy the key above (including 'ssh-ed25519 ...')"
echo "2. Go to: https://github.com/settings/keys"
echo "3. Click 'New SSH key' → Paste → Save"
echo ""

read -p "Press Enter after you've added the key to GitHub..."

# Step 4: Test SSH connection
echo -e "${YELLOW}Step 4: Testing SSH connection...${NC}"
if ssh -T git@github.com -o ConnectTimeout=10 -o BatchMode=yes 2>&1 | grep -q "successfully"; then
    echo -e "${GREEN}✓ SSH connection works!${NC}"
else
    echo -e "${YELLOW}SSH test returned (this is normal if key just added):${NC}"
    ssh -T git@github.com -o ConnectTimeout=10 -o BatchMode=yes 2>&1 || true
    echo ""
    read -p "Does it say 'Hi username! You've successfully authenticated'? (y/n): " SSH_OK
    if [ "$SSH_OK" != "y" ]; then
        echo -e "${RED}Please add the SSH key to GitHub first, then re-run this script.${NC}"
        exit 1
    fi
fi

# Step 5: Get repo name
echo ""
echo -e "${YELLOW}Step 5: Repository setup${NC}"
read -p "GitHub repository name (default: ScreenCast): " REPO_NAME
REPO_NAME=${REPO_NAME:-ScreenCast}

read -p "Make it private? (y/n, default: n): " IS_PRIVATE
IS_PRIVATE=${IS_PRIVATE:-n}

# Step 6: Initialize git repo
echo ""
echo -e "${YELLOW}Step 6: Initializing local git repo...${NC}"
if [ ! -d ".git" ]; then
    git init
    echo -e "${GREEN}✓ Git repo initialized${NC}"
else
    echo -e "${GREEN}✓ Already a git repo${NC}"
fi

# Step 7: Create .gitignore if missing
if [ ! -f ".gitignore" ]; then
    cat > .gitignore << 'EOF'
# Build outputs
/build/
/Android/app/build/
/iOS/build/
/server/node_modules/

# IDE
.idea/
.vscode/
*.swp
*.swo
.DS_Store

# Local config
local.properties
*.p12
*.mobileprovision

# Secrets
*.env
*.key
EOF
    echo -e "${GREEN}✓ .gitignore created${NC}"
fi

# Step 8: Commit
echo -e "${YELLOW}Step 7: Creating initial commit...${NC}"
git add .
git status
echo ""
read -p "Commit message (default: 'Initial commit: ScreenCast Android+iOS screen casting'): " COMMIT_MSG
COMMIT_MSG=${COMMIT_MSG:-"Initial commit: ScreenCast Android+iOS screen casting"}
git commit -m "$COMMIT_MSG" || echo "Nothing to commit"

# Step 9: Create GitHub repo via API or manual
echo ""
echo -e "${YELLOW}Step 8: Create GitHub repository${NC}"
echo "Choose one:"
echo "  1) Auto-create via GitHub CLI (gh) - RECOMMENDED"
echo "  2) Manual - I'll create it on github.com"
read -p "Choice (1 or 2): " CREATE_METHOD

if [ "$CREATE_METHOD" = "1" ]; then
    # Check for gh CLI
    if command -v gh &> /dev/null; then
        echo -e "${YELLOW}Creating repo via GitHub CLI...${NC}"
        if [ "$IS_PRIVATE" = "y" ]; then
            gh repo create "$REPO_NAME" --private --source=. --remote=origin --push
        else
            gh repo create "$REPO_NAME" --public --source=. --remote=origin --push
        fi
        echo -e "${GREEN}✓ Repository created and pushed!${NC}"
    else
        echo -e "${RED}GitHub CLI (gh) not installed.${NC}"
        echo "Install: sudo apt install gh  (Ubuntu/Debian)"
        echo "Or: brew install gh  (if you have homebrew)"
        echo ""
        echo "Then run: gh auth login"
        CREATE_METHOD=2
    fi
fi

if [ "$CREATE_METHOD" = "2" ]; then
    echo ""
    echo -e "${YELLOW}Manual steps:${NC}"
    echo "1. Go to: https://github.com/new"
    echo "2. Repository name: $REPO_NAME"
    echo "3. Private: $([ "$IS_PRIVATE" = "y" ] && echo "Yes" || echo "No")"
    echo "4. DON'T initialize with README, .gitignore, or license"
    echo "5. Click 'Create repository'"
    echo ""
    read -p "Press Enter after creating the repo..."
    
    # Add remote and push
    echo -e "${YELLOW}Adding remote and pushing...${NC}"
    git remote remove origin 2>/dev/null || true
    git remote add origin "git@github.com:$GIT_NAME/$REPO_NAME.git"
    git branch -M main
    git push -u origin main
    echo -e "${GREEN}✓ Pushed to GitHub!${NC}"
fi

# Step 10: Show next steps
echo ""
echo -e "${GREEN}=== DONE! ===${NC}"
echo ""
echo -e "${BLUE}Your repo: https://github.com/$GIT_NAME/$REPO_NAME${NC}"
echo ""
echo -e "${YELLOW}Next - Trigger GitHub Actions builds:${NC}"
echo "1. Go to: https://github.com/$GIT_NAME/$REPO_NAME/actions"
echo "2. Click 'Build iOS App' → 'Run workflow' → 'Run workflow'"
echo "3. Click 'Build Android App' → 'Run workflow' → 'Run workflow'"
echo ""
echo -e "${YELLOW}For signed iOS builds (TestFlight):${NC}"
echo "1. Go to Settings → Secrets → Actions"
echo "2. Add these secrets:"
echo "   - DEVELOPMENT_TEAM (your Team ID)"
echo "   - APP_STORE_CONNECT_ISSUER_ID"
echo "   - APP_STORE_CONNECT_API_KEY_ID"
echo "   - APP_STORE_CONNECT_API_PRIVATE_KEY (base64 encoded .p8 file)"
echo ""
echo -e "${GREEN}Happy coding! 🚀${NC}"