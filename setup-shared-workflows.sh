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

# Ask for shared workflows repo
read -p "📦 Shared workflows repo (e.g., your-username/my-workflows): " WORKFLOWS_REPO
if [ -z "$WORKFLOWS_REPO" ]; then
    echo "❌ Workflows repo cannot be empty"
    exit 1
fi

# Ask for workflows branch/tag
read -p "🔗 Workflows version/branch (default: main): " WORKFLOWS_VERSION
WORKFLOWS_VERSION="${WORKFLOWS_VERSION:-main}"

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
echo "📝 Creating .github/workflows/ci.yml..."
echo ""

# Create .github/workflows directory
mkdir -p .github/workflows

# Create ci.yml that references the shared workflow
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

echo "✅ Created .github/workflows/ci.yml"

echo ""
echo "======================================"
echo "Next Steps:"
echo "======================================"
echo ""
echo "1️⃣  Add GitHub secrets to this repository:"
echo "   - Go to Settings → Secrets and variables → Actions"
echo "   - Add DOCKERHUB_USERNAME: (your Docker Hub username)"
echo "   - Add DOCKERHUB_TOKEN: (your Docker Hub access token)"
echo ""
echo "   Or use GitHub CLI:"
echo "   $ gh secret set DOCKERHUB_USERNAME --body 'your-username'"
echo "   $ gh secret set DOCKERHUB_TOKEN --body 'your-token'"
echo ""
echo "2️⃣  Commit and push:"
echo "   $ git add .github/workflows/ci.yml"
echo "   $ git commit -m 'Add Docker CI/CD workflow'"
echo "   $ git push"
echo ""
echo "3️⃣  The workflow will run on next push to main/develop or git tag!"
echo ""
echo "======================================"
echo "ℹ️  Using shared workflows repo: $WORKFLOWS_REPO@$WORKFLOWS_VERSION"
echo "======================================"
