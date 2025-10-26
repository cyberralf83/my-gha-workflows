#!/bin/bash

# Docker Workflow Setup Script
# This script sets up GitHub Actions workflows for building and pushing Docker images

set -e

echo "======================================"
echo "Docker Workflow Setup Script"
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

# Extract GitHub username from remote URL
GIT_REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
if [[ $GIT_REMOTE_URL =~ github\.com[:/]([^/]+)/ ]]; then
    DEFAULT_USERNAME="${BASH_REMATCH[1]}"
else
    DEFAULT_USERNAME=""
fi

# Create .github/workflows directory
mkdir -p .github/workflows
echo "✅ Created .github/workflows directory"

echo ""
echo "======================================"
echo "Docker Hub Credentials"
echo "======================================"
echo ""

# Ask for Docker Hub username with GitHub username as default
ATTEMPT=1
while [ $ATTEMPT -le 2 ]; do
    if [ -n "$DEFAULT_USERNAME" ]; then
        read -p "🔐 Docker Hub username (default: $DEFAULT_USERNAME): " DOCKERHUB_USERNAME
        DOCKERHUB_USERNAME="${DOCKERHUB_USERNAME:-$DEFAULT_USERNAME}"
    else
        read -p "🔐 Docker Hub username: " DOCKERHUB_USERNAME
    fi

    if [ -z "$DOCKERHUB_USERNAME" ]; then
        if [ $ATTEMPT -eq 2 ]; then
            echo "❌ Docker Hub username cannot be empty. Exiting."
            exit 1
        else
            echo "⚠️  Docker Hub username cannot be empty. Please try again."
            ATTEMPT=$((ATTEMPT + 1))
        fi
    else
        break
    fi
done

# Ask for Docker Hub token immediately after username
ATTEMPT=1
while [ $ATTEMPT -le 2 ]; do
    read -sp "🔑 Docker Hub access token (create at https://hub.docker.com/settings/security): " DOCKERHUB_TOKEN
    echo ""

    if [ -z "$DOCKERHUB_TOKEN" ]; then
        if [ $ATTEMPT -eq 2 ]; then
            echo "❌ Token cannot be empty. Exiting."
            exit 1
        else
            echo "⚠️  Token cannot be empty. Please try again."
            ATTEMPT=$((ATTEMPT + 1))
        fi
    else
        break
    fi
done

echo ""
echo "======================================"
echo "Docker Build Configuration"
echo "======================================"
echo ""

# Ask for app name
read -p "🐳 Docker image name (default: $DOCKERHUB_USERNAME/$REPO_NAME): " APP_NAME
APP_NAME="${APP_NAME:-$DOCKERHUB_USERNAME/$REPO_NAME}"

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
echo "📝 Creating workflow files..."
echo ""

# Create docker-build-push.yml (reusable workflow)
cat > .github/workflows/docker-build-push.yml << 'EOF'
name: Build and Push Docker Image

on:
  workflow_call:
    inputs:
      image-name:
        description: 'Docker image name (e.g., myusername/myapp)'
        required: true
        type: string
      image-tag:
        description: 'Docker image tag (e.g., latest, v1.0.0)'
        required: false
        default: 'latest'
        type: string
      dockerfile-path:
        description: 'Path to Dockerfile'
        required: false
        default: './Dockerfile'
        type: string
      build-context:
        description: 'Build context path'
        required: false
        default: '.'
        type: string
      platforms:
        description: 'Target platforms (e.g., linux/amd64,linux/arm64)'
        required: false
        default: 'linux/amd64'
        type: string
    secrets:
      DOCKERHUB_USERNAME:
        description: 'Docker Hub username'
        required: true
      DOCKERHUB_TOKEN:
        description: 'Docker Hub access token'
        required: true

jobs:
  build-and-push:
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
          context: ${{ inputs.build-context }}
          file: ${{ inputs.dockerfile-path }}
          platforms: ${{ inputs.platforms }}
          push: true
          tags: ${{ inputs.image-name }}:${{ inputs.image-tag }}
EOF
echo "✅ Created .github/workflows/docker-build-push.yml"

# Create ci.yml (workflow that calls the reusable one)
cat > .github/workflows/ci.yml << EOF
name: CI/CD Pipeline

on:
  push:
    branches:
      - main
      - develop
    tags:
      - 'v*'
  workflow_dispatch:

jobs:
  build-and-push-docker:
    uses: .\/.github\/workflows\/docker-build-push.yml@main
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
echo "Setting up GitHub Secrets & Deploying"
echo "======================================"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI not installed. Install it from https://cli.github.com"
    echo ""
    echo "Manual setup required:"
    echo "1. Create Docker Hub access token at https://hub.docker.com/settings/security"
    echo "2. Add secrets at Settings → Secrets and variables → Actions"
    echo "   - DOCKERHUB_USERNAME: $DOCKERHUB_USERNAME"
    echo "   - DOCKERHUB_TOKEN: (your access token)"
    echo "3. Run: git add .github/workflows/ && git commit -m 'Add Docker workflows' && git push"
    exit 1
fi

# Set up GitHub secrets
echo "🔐 Setting up GitHub secrets..."
echo ""

# Set Docker Hub username secret
gh secret set DOCKERHUB_USERNAME --body "$DOCKERHUB_USERNAME"
echo "✅ DOCKERHUB_USERNAME secret set"

# Set Docker Hub token secret (already collected earlier)
gh secret set DOCKERHUB_TOKEN --body "$DOCKERHUB_TOKEN"
echo "✅ DOCKERHUB_TOKEN secret set"

echo ""
echo "📤 Committing and pushing workflow files to GitHub..."
git add .github/workflows/
git commit -m "Add Docker build and push workflows"
git push

echo ""
echo "✅ Workflows pushed to GitHub!"

echo ""
echo "🚀 Triggering CI/CD workflow..."
# Wait a moment for GitHub to process the push
sleep 2
gh workflow run ci.yml

echo ""
echo "======================================"
echo "✨ Setup Complete!"
echo "======================================"
echo ""
echo "🎯 Your Docker workflow has been:"
echo "   ✅ Created and configured"
echo "   ✅ Pushed to GitHub"
echo "   ✅ Triggered to run"
echo ""
echo "📊 View workflow status:"
echo "   $ gh run list --workflow=ci.yml"
echo ""
echo "🔍 Watch live logs:"
echo "   $ gh run watch"
echo ""