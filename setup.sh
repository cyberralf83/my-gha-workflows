#!/bin/bash

# GitHub Actions Docker Workflow Setup Script
# This script sets up GitHub Actions workflows for building and pushing Docker images

set -e

echo "======================================"
echo "Docker Workflow Setup"
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
if [[ $GIT_REMOTE_URL =~ github\.com[:/]([^/]+)/([^/.]+)(\.git)?$ ]]; then
    REPO_OWNER="${BASH_REMATCH[1]}"
    CURRENT_REPO="${BASH_REMATCH[2]}"
    DEFAULT_USERNAME="$REPO_OWNER"
    echo "✅ Auto-detected: $REPO_OWNER/$CURRENT_REPO"
else
    echo "⚠️  Could not auto-detect GitHub repository"
    DEFAULT_USERNAME=""
fi
echo ""

# Create .github/workflows directory
mkdir -p .github/workflows
echo "✅ Created .github/workflows directory"
echo ""

# Ask for workflow deployment type
echo "======================================"
echo "Workflow Deployment Type"
echo "======================================"
echo ""
echo "Choose your Docker CI/CD workflow setup:"
echo ""
echo "  A) Simple inline workflow"
echo "     ✓ All steps in one file (.github/workflows/ci.yml)"
echo "     ✓ Easy to understand and modify"
echo "     ✓ Best for single repository"
echo ""
echo "  B) Local reusable workflow"
echo "     ✓ Creates reusable workflow + CI workflow"
echo "     ✓ Can be referenced by other workflows in same repo"
echo "     ✓ Better organization for complex repos"
echo ""
echo "  C) Remote shared workflow"
echo "     ✓ References external shared workflow repository"
echo "     ✓ Centralized updates across multiple repos"
echo "     ✓ Best for managing many repositories"
echo ""

ATTEMPT=1
while [ $ATTEMPT -le 2 ]; do
    read -p "Select deployment type [A/B/C] (default: A): " DEPLOYMENT_TYPE
    DEPLOYMENT_TYPE="${DEPLOYMENT_TYPE:-A}"
    DEPLOYMENT_TYPE=$(echo "$DEPLOYMENT_TYPE" | tr '[:lower:]' '[:upper:]')

    if [[ "$DEPLOYMENT_TYPE" != "A" && "$DEPLOYMENT_TYPE" != "B" && "$DEPLOYMENT_TYPE" != "C" ]]; then
        if [ $ATTEMPT -eq 2 ]; then
            echo "❌ Invalid choice. Please select A, B, or C. Exiting."
            exit 1
        else
            echo "⚠️  Invalid choice. Please select A, B, or C."
            ATTEMPT=$((ATTEMPT + 1))
        fi
    else
        break
    fi
done
echo ""

# Ask for remote workflow repo details (only for option C)
if [ "$DEPLOYMENT_TYPE" == "C" ]; then
    read -p "🔗 Shared workflow repository (e.g., username/my-workflows): " WORKFLOWS_REPO
    if [ -z "$WORKFLOWS_REPO" ]; then
        echo "❌ Workflow repository cannot be empty"
        exit 1
    fi
    read -p "🔗 Workflow version/branch (default: main): " WORKFLOWS_VERSION
    WORKFLOWS_VERSION="${WORKFLOWS_VERSION:-main}"
    echo ""
fi

# Ask for Docker Hub credentials
echo "======================================"
echo "Docker Hub Credentials"
echo "======================================"
echo ""

# Ask for Docker Hub username
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

# Ask for Docker Hub token
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

# Ask for Docker image name
DEFAULT_APP_NAME="$DOCKERHUB_USERNAME/$REPO_NAME"
ATTEMPT=1
while [ $ATTEMPT -le 2 ]; do
    read -p "🐳 Docker image name (default: $DEFAULT_APP_NAME): " APP_NAME
    APP_NAME="${APP_NAME:-$DEFAULT_APP_NAME}"

    if [ -z "$APP_NAME" ]; then
        if [ $ATTEMPT -eq 2 ]; then
            echo "❌ Image name cannot be empty. Exiting."
            exit 1
        else
            echo "⚠️  Image name cannot be empty. Please try again."
            ATTEMPT=$((ATTEMPT + 1))
        fi
    else
        break
    fi
done

# Convert to lowercase (Docker requires lowercase image names)
APP_NAME_LOWER=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]')
if [ "$APP_NAME" != "$APP_NAME_LOWER" ]; then
    echo "ℹ️  Converted to lowercase: $APP_NAME_LOWER (Docker requires lowercase)"
    APP_NAME="$APP_NAME_LOWER"
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
echo "📝 Creating workflow files..."
echo ""

# Create workflow files based on deployment type
if [ "$DEPLOYMENT_TYPE" == "A" ]; then
    # Option A: Simple inline workflow
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
          username: \${{ secrets.DOCKERHUB_USERNAME }}
          password: \${{ secrets.DOCKERHUB_TOKEN }}

      - name: Build and push
        uses: docker/build-push-action@v6
        with:
          context: $BUILD_CONTEXT
          file: $DOCKERFILE_PATH
          platforms: $PLATFORMS
          push: true
          tags: $APP_NAME:\${{ github.ref_name == 'main' && 'latest' || github.ref_name }}
EOF
    echo "✅ Created .github/workflows/ci.yml (inline)"
    DEPLOYMENT_DESC="Simple inline workflow"

elif [ "$DEPLOYMENT_TYPE" == "B" ]; then
    # Option B: Local reusable workflow
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
    uses: ./.github/workflows/docker-build-push.yml@main
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
    DEPLOYMENT_DESC="Local reusable workflow"

else
    # Option C: Remote shared workflow
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
    DEPLOYMENT_DESC="Remote shared workflow ($WORKFLOWS_REPO@$WORKFLOWS_VERSION)"
fi

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
    echo "1. Go to Settings → Secrets and variables → Actions"
    echo "2. Add DOCKERHUB_USERNAME: $DOCKERHUB_USERNAME"
    echo "3. Add DOCKERHUB_TOKEN: (your token)"
    echo "4. Run: git add .github/workflows/ && git commit -m 'Add Docker workflows' && git push"
    exit 1
fi

# Set up GitHub secrets
echo "🔐 Setting up GitHub secrets..."
echo ""

# Set Docker Hub username secret
if gh secret set DOCKERHUB_USERNAME --body "$DOCKERHUB_USERNAME"; then
    echo "✅ DOCKERHUB_USERNAME secret set"
else
    echo "❌ Failed to set DOCKERHUB_USERNAME secret"
    exit 1
fi

# Set Docker Hub token secret
if echo "$DOCKERHUB_TOKEN" | gh secret set DOCKERHUB_TOKEN; then
    echo "✅ DOCKERHUB_TOKEN secret set"
else
    echo "❌ Failed to set DOCKERHUB_TOKEN secret"
    exit 1
fi

echo ""
echo "📤 Committing and pushing workflow files to GitHub..."
git add .github/workflows/
git commit -m "Add Docker CI/CD workflow ($DEPLOYMENT_DESC)"
git push

echo ""
echo "✅ Workflows pushed to GitHub!"

echo ""
echo "======================================"
echo "✨ Setup Complete!"
echo "======================================"
echo ""
echo "📋 Deployment Summary:"
echo "   Repository: $REPO_OWNER/$CURRENT_REPO"
echo "   Deployment Type: $DEPLOYMENT_DESC"
echo "   Docker Image: $APP_NAME"
echo "   Platforms: $PLATFORMS"
echo ""
echo "🎯 Your Docker workflow has been:"
echo "   ✅ Created and configured"
echo "   ✅ Pushed to GitHub"
echo "   ✅ Ready to run"
echo ""
echo "🚀 The workflow will automatically run when you:"
echo "   • Push to main or develop branch"
echo "   • Create a version tag (e.g., v1.0.0)"
echo "   • Manually trigger via GitHub Actions UI"
echo ""
echo "💡 To trigger the workflow manually:"
echo "   $ gh workflow run ci.yml"
echo ""
echo "📊 View workflow runs:"
echo "   $ gh run list --workflow=ci.yml"
echo ""
echo "🔍 Watch latest run:"
echo "   $ gh run watch"
echo ""
