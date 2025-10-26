# GitHub Actions Docker Workflow Setup

Automated setup script for deploying Docker build and push workflows to your GitHub repositories.

## Quick Start

Run this one-line command in your repository to set up Docker CI/CD:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/cyberralf83/my-gha-workflows/main/setup-shared-workflows.sh)
```

The script will interactively guide you through the setup process.

## What This Does

This setup script automates the creation of a GitHub Actions workflow that:

- ✅ Builds Docker images for your application
- ✅ Pushes images to Docker Hub
- ✅ Supports multi-platform builds (ARM64, AMD64)
- ✅ Automatically sets up GitHub secrets
- ✅ Triggers on push to main/develop branches and version tags

## Deployment Options

### Option A: Static Workflow (Self-Contained)

Creates a complete workflow file directly in your repository with all build steps embedded.

**Pros:**
- No external dependencies
- Complete control over the workflow
- Works even if the shared workflow repo is unavailable

**Cons:**
- Updates require manual changes to each repository
- Harder to maintain consistency across multiple repos

**Use when:** You want full control and don't plan to use this workflow across multiple repositories.

### Option B: Dynamic Workflow (Shared Reference)

Creates a workflow that references a centralized shared workflow from this repository.

**Pros:**
- Updates automatically from the shared repo
- Centralized workflow management
- Easy to maintain consistency across multiple repos
- Update once, apply everywhere

**Cons:**
- Requires the shared workflow repo to be accessible
- Depends on external repository

**Use when:** You manage multiple repositories and want centralized workflow updates.

## Prerequisites

- Git repository with a remote origin on GitHub
- Dockerfile in your repository
- Docker Hub account
- (Optional) [GitHub CLI](https://cli.github.com/) for automatic secret configuration

## What Gets Created

The script creates:

1. **`.github/workflows/ci.yml`** - Your GitHub Actions workflow file
2. **GitHub Secrets** (if gh CLI is available):
   - `DOCKERHUB_USERNAME` - Your Docker Hub username
   - `DOCKERHUB_TOKEN` - Your Docker Hub access token

## Interactive Setup Process

When you run the script, you'll be prompted for:

1. **Deployment Type** - Choose between Static (A) or Dynamic (B) workflow
2. **Workflow Version** - Branch or tag to use (Dynamic only, default: main)
3. **Docker Image Name** - Full image name (e.g., `username/app-name`)
4. **Dockerfile Path** - Location of your Dockerfile (default: `./Dockerfile`)
5. **Build Context** - Docker build context path (default: `.`)
6. **Target Platforms** - Platforms to build for (default: `linux/amd64,linux/arm64`)
7. **Docker Hub Username** - Your Docker Hub username
8. **Docker Hub Token** - Your Docker Hub access token (hidden input)

## Manual Installation

If you prefer to download and review the script first:

```bash
# Download the script
curl -fsSL -o setup-shared-workflows.sh https://raw.githubusercontent.com/cyberralf83/my-gha-workflows/main/setup-shared-workflows.sh

# Make it executable
chmod +x setup-shared-workflows.sh

# Run it
./setup-shared-workflows.sh
```

## Example Usage

### Static Workflow Setup

```bash
$ bash <(curl -fsSL https://raw.githubusercontent.com/cyberralf83/my-gha-workflows/main/setup-shared-workflows.sh)

======================================
Shared Workflows Integration Setup
======================================

📁 Repository: my-app
✅ Auto-detected repository: myusername/my-app

======================================
Workflow Deployment Type
======================================

Choose how to deploy your Docker CI/CD workflow:

  A) Static workflow (self-contained, all steps in your repo)
  B) Dynamic workflow (references shared workflow repo)

Select deployment type [A/B] (default: B): A

🐳 Docker image name: myusername/my-app
📄 Path to Dockerfile: ./Dockerfile
📍 Build context path: .
🖥️  Target platforms: linux/amd64,linux/arm64
🔐 Docker Hub username: myusername
🔑 Docker Hub token/password: ********

✅ Created .github/workflows/ci.yml
✅ DOCKERHUB_USERNAME secret set successfully
✅ DOCKERHUB_TOKEN secret set successfully

======================================
✅ Setup Complete!
======================================

📋 Deployment Summary:
   Repository: myusername/my-app
   Deployment Type: Static workflow (self-contained)
   Docker Image: myusername/my-app
   Platforms: linux/amd64,linux/arm64
```

### Dynamic Workflow Setup

```bash
Select deployment type [A/B] (default: B): B

🔗 Workflows version/branch (default: main): main
🐳 Docker image name: myusername/my-app
...

📋 Deployment Summary:
   Repository: myusername/my-app
   Deployment Type: Dynamic workflow (uses myusername/my-workflows@main)
   Docker Image: myusername/my-app
   Platforms: linux/amd64,linux/arm64
```

## Triggering the Workflow

The workflow will automatically run when you:

- Push to `main` branch → Builds and pushes with `latest` tag
- Push to `develop` branch → Builds and pushes with `develop` tag
- Create a version tag (e.g., `v1.0.0`) → Builds and pushes with that tag

```bash
# Trigger workflow by pushing to main
git push origin main

# Or create and push a version tag
git tag v1.0.0
git push origin v1.0.0
```

## Manual Secret Configuration

If you don't have GitHub CLI installed, you can set secrets manually:

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add:
   - Name: `DOCKERHUB_USERNAME`, Value: your Docker Hub username
   - Name: `DOCKERHUB_TOKEN`, Value: your Docker Hub access token

## Creating a Docker Hub Access Token

1. Log in to [Docker Hub](https://hub.docker.com/)
2. Go to **Account Settings** → **Security** → **Access Tokens**
3. Click **New Access Token**
4. Give it a description (e.g., "GitHub Actions")
5. Set permissions to **Read, Write, Delete**
6. Click **Generate**
7. Copy the token (you won't see it again!)

## Shared Workflow Repository Structure

For Option B (Dynamic), this repository contains:

```
my-gha-workflows/
├── .github/
│   └── workflows/
│       └── docker-build-push.yml    # Reusable shared workflow
├── setup-shared-workflows.sh         # Setup script
├── README.md                          # This file
└── SHARED_WORKFLOWS_SETUP.md         # Detailed setup guide
```

## Updating the Dynamic Workflow

If you're using Option B (Dynamic):

1. **Update all repos automatically** - Modify the workflow in this repo, and all repos using `@main` will use the updated version on their next run
2. **Use version tags** - Create git tags (e.g., `v1.0.0`) in this repo and reference them in your repos for stable versions

```bash
# In this repo (my-gha-workflows)
git tag v1.0.0
git push origin v1.0.0

# Then in your app repos, reference the tag:
# uses: myusername/my-workflows/.github/workflows/docker-build-push.yml@v1.0.0
```

## Troubleshooting

### "Not in a git repository" error

Make sure you're running the script from the root of your git repository:

```bash
cd /path/to/your/repo
bash <(curl -fsSL https://raw.githubusercontent.com/cyberralf83/my-gha-workflows/main/setup-shared-workflows.sh)
```

### "No remote origin found" error

Add a GitHub remote to your repository:

```bash
git remote add origin https://github.com/username/repo.git
```

### Workflow fails with "authentication required"

Make sure your GitHub secrets are set correctly:

```bash
gh secret list
```

If they're missing, set them manually or run the setup script again.

### Multi-platform build fails

Ensure you have QEMU and Buildx set up (the workflow handles this automatically). If issues persist, try removing ARM64 from the platforms:

```
Platforms: linux/amd64
```

### Dynamic workflow not found (Option B)

Ensure the shared workflow repository:
- Exists and is public
- Contains `.github/workflows/docker-build-push.yml`
- The branch/tag you referenced exists

## Advanced Configuration

### Custom Workflow File

If you want to customize the generated workflow:

1. Run the setup script
2. Edit `.github/workflows/ci.yml` to add custom steps
3. Commit and push

### Multiple Workflows

Run the script multiple times with different configurations to create multiple workflow files:

```bash
# First run - creates ci.yml
./setup-shared-workflows.sh

# Manually rename the file
mv .github/workflows/ci.yml .github/workflows/docker-build.yml

# Run again for a different configuration
./setup-shared-workflows.sh
```

## Support

For issues or questions:

- Check the [GitHub Issues](https://github.com/cyberralf83/my-gha-workflows/issues)
- Review [GitHub Actions Documentation](https://docs.github.com/en/actions)
- Review [Docker Build Push Action](https://github.com/docker/build-push-action)

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

This project is open source and available under the MIT License.
