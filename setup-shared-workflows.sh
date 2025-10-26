#!/bin/bash

# Quick Setup for Using Shared Workflows Repository
# This script sets up a CI workflow that references a shared workflows repo

set -e

echo "======================================"
echo "Shared Workflows Integration Setup"
echo "======================================"
echo ""

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: Not in a git repository. Please run this from your repository root."
    exit 1
fi

# Get repository name for defaults
REPO_NAME=$(basename "$(git rev-parse --show-toplevel)")
echo "📁 Repository: $REPO_NAME"
echo ""

# Auto-detect current GitHub repository
REMOTE_URL=$(git config --get remote.origin.url || echo "")
if [ -z "$REMOTE_URL" ]; then
    echo "❌ Error: No remote origin found. Please add a remote first."
    exit 1
fi

# Parse the repository owner/name from the remote URL
# Handles both HTTPS and SSH formats
if [[ "$REMOTE_URL" =~ github\.com[:/]([^/]+)/([^/.]+)(\.git)?$ ]]; then
    REPO_OWNER="${BASH_REMATCH[1]}"
    REPO_NAME="${BASH_REMATCH[2]}"
    WORKFLOWS_REPO="$REPO_OWNER/$REPO_NAME"
    echo "✅ Auto-detected repository: $WORKFLOWS_REPO"
else
    echo "❌ Error: Could not parse GitHub repository from remote URL: $REMOTE_URL"
    exit 1
fi
echo ""

# Ask for workflow deployment type
echo "======================================"
echo "Workflow Deployment Type"
echo "======================================"
echo ""
echo "Choose how to deploy your Docker CI/CD workflow:"
echo ""
echo "  A) Static workflow (self-contained, all steps in your repo)"
echo "     ✓ No external dependencies"
echo "     ✓ Complete control over workflow"
echo "     ✗ Updates require manual changes"
echo ""
echo "  B) Dynamic workflow (references shared workflow repo)"
echo "     ✓ Updates automatically from shared repo"
echo "     ✓ Centralized workflow management"
echo "     ✗ Requires shared workflow repo to be available"
echo ""
read -p "Select deployment type [A/B] (default: B): " DEPLOYMENT_TYPE
DEPLOYMENT_TYPE="${DEPLOYMENT_TYPE:-B}"
DEPLOYMENT_TYPE=$(echo "$DEPLOYMENT_TYPE" | tr '[:lower:]' '[:upper:]')

if [[ "$DEPLOYMENT_TYPE" != "A" && "$DEPLOYMENT_TYPE" != "B" ]]; then
    echo "❌ Invalid choice. Please select A or B."
    exit 1
fi
echo ""

# Ask for workflows branch/tag (only for dynamic deployment)
if [ "$DEPLOYMENT_TYPE" == "B" ]; then
    read -p "🔗 Workflows version/branch (default: main): " WORKFLOWS_VERSION
    WORKFLOWS_VERSION="${WORKFLOWS_VERSION:-main}"
fi

# Ask for Docker app name
read -p "🐳 Docker image name (e.g., username/app-name): " APP_NAME
if [ -z "$APP_NAME" ]; then
    echo "❌ App name cannot be empty"
    exit 1
fi

# Ask for Dockerfile path
read -p "📄 Path to Dockerfile (default: ./Dockerfile): " DOCKERFILE_PATH
DOCKERFILE_PATH="${DOCKERFILE_PATH:-./Dockerfile}"

# Ask for build context
read -p "📍 Build context path (default: .): " BUILD_CONTEXT
BUILD_CONTEXT="${BUILD_CONTEXT:-./}"

# Ask for platforms
read -p "🖥️  Target platforms (default: linux/amd64,linux/arm64): " PLATFORMS
PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64}"

echo ""
echo "======================================"
echo "Docker Hub Credentials"
echo "======================================"
echo ""

# Ask for Docker Hub username
read -p "🔐 Docker Hub username: " DOCKERHUB_USERNAME
if [ -z "$DOCKERHUB_USERNAME" ]; then
    echo "❌ Docker Hub username cannot be empty"
    exit 1
fi

# Ask for Docker Hub token (hidden input)
read -s -p "🔑 Docker Hub token/password: " DOCKERHUB_TOKEN
echo ""
if [ -z "$DOCKERHUB_TOKEN" ]; then
    echo "❌ Docker Hub token cannot be empty"
    exit 1
fi

echo ""
echo "📝 Creating .github/workflows/ci.yml..."
echo ""

# Create .github/workflows directory
mkdir -p .github/workflows

# Create ci.yml based on deployment type
if [ "$DEPLOYMENT_TYPE" == "A" ]; then
    # Option A: Static workflow (self-contained)
    cat > .github/workflows/ci.yml << 'EOF'
name: CI/CD Pipeline

on:
  push:
    branches:
      - main
      - develop
    tags:
      - 'v*'

jobs:
  build-and-push-docker:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Build and push
        uses: docker/build-push-action@v6
        with:
          context: BUILD_CONTEXT_PLACEHOLDER
          file: DOCKERFILE_PATH_PLACEHOLDER
          platforms: PLATFORMS_PLACEHOLDER
          push: true
          tags: IMAGE_NAME_PLACEHOLDER:${{ github.ref_name == 'main' && 'latest' || github.ref_name }}
EOF
    # Replace placeholders with actual values
    sed -i.bak "s|BUILD_CONTEXT_PLACEHOLDER|$BUILD_CONTEXT|g" .github/workflows/ci.yml
    sed -i.bak "s|DOCKERFILE_PATH_PLACEHOLDER|$DOCKERFILE_PATH|g" .github/workflows/ci.yml
    sed -i.bak "s|PLATFORMS_PLACEHOLDER|$PLATFORMS|g" .github/workflows/ci.yml
    sed -i.bak "s|IMAGE_NAME_PLACEHOLDER|$APP_NAME|g" .github/workflows/ci.yml
    rm -f .github/workflows/ci.yml.bak

    DEPLOYMENT_DESC="Static workflow (self-contained)"
else
    # Option B: Dynamic workflow (references shared workflow)
    cat > .github/workflows/ci.yml << EOF
name: CI/CD Pipeline

on:
  push:
    branches:
      - main
      - develop
    tags:
      - 'v*'

jobs:
  build-and-push-docker:
    uses: $WORKFLOWS_REPO/.github/workflows/docker-build-push.yml@$WORKFLOWS_VERSION
    with:
      image-name: $APP_NAME
      image-tag: \${{ github.ref_name == 'main' && 'latest' || github.ref_name }}
      dockerfile-path: '$DOCKERFILE_PATH'
      build-context: '$BUILD_CONTEXT'
      platforms: '$PLATFORMS'
    secrets:
      DOCKERHUB_USERNAME: \${{ secrets.DOCKERHUB_USERNAME }}
      DOCKERHUB_TOKEN: \${{ secrets.DOCKERHUB_TOKEN }}
EOF

    DEPLOYMENT_DESC="Dynamic workflow (uses $WORKFLOWS_REPO@$WORKFLOWS_VERSION)"
fi

echo "✅ Created .github/workflows/ci.yml"

echo ""
echo "======================================"
echo "Setting GitHub Secrets"
echo "======================================"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "⚠️  GitHub CLI (gh) not found. Please install it to set secrets automatically."
    echo "   Visit: https://cli.github.com/"
    echo ""
    echo "   Manual setup:"
    echo "   1. Go to Settings → Secrets and variables → Actions"
    echo "   2. Add DOCKERHUB_USERNAME: $DOCKERHUB_USERNAME"
    echo "   3. Add DOCKERHUB_TOKEN: (your token)"
else
    echo "🔐 Setting DOCKERHUB_USERNAME secret..."
    if echo "$DOCKERHUB_USERNAME" | gh secret set DOCKERHUB_USERNAME; then
        echo "✅ DOCKERHUB_USERNAME secret set successfully"
    else
        echo "❌ Failed to set DOCKERHUB_USERNAME secret"
    fi

    echo "🔐 Setting DOCKERHUB_TOKEN secret..."
    if echo "$DOCKERHUB_TOKEN" | gh secret set DOCKERHUB_TOKEN; then
        echo "✅ DOCKERHUB_TOKEN secret set successfully"
    else
        echo "❌ Failed to set DOCKERHUB_TOKEN secret"
    fi
fi

echo ""
echo "======================================"
echo "✅ Setup Complete!"
echo "======================================"
echo ""
echo "📋 Deployment Summary:"
echo "   Repository: $WORKFLOWS_REPO"
echo "   Deployment Type: $DEPLOYMENT_DESC"
echo "   Docker Image: $APP_NAME"
echo "   Platforms: $PLATFORMS"
echo ""
echo "======================================"
echo "Next Steps:"
echo "======================================"
echo ""
echo "1️⃣  Commit and push the workflow:"
echo "   $ git add .github/workflows/ci.yml"
echo "   $ git commit -m 'Add Docker CI/CD workflow'"
echo "   $ git push"
echo ""
echo "2️⃣  The workflow will run on next push to main/develop or git tag!"
echo ""
echo "======================================"
