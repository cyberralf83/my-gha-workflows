# GitHub Actions Docker Workflow Setup

One simple script to set up Docker CI/CD workflows for your GitHub repositories.

## Quick Start

Run this one command in your repository:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/cyberralf83/my-gha-workflows/main/setup.sh)
```

Or download and run locally:

```bash
curl -fsSL -o setup.sh https://raw.githubusercontent.com/cyberralf83/my-gha-workflows/main/setup.sh
chmod +x setup.sh
./setup.sh
```

## What This Does

The setup script creates a GitHub Actions workflow that:

- ✅ Builds Docker images for your application
- ✅ Pushes images to Docker Hub
- ✅ Supports multi-platform builds (ARM64, AMD64)
- ✅ Automatically sets up GitHub secrets
- ✅ Triggers on push to main/develop branches and version tags
- ✅ Can be manually triggered via GitHub UI or CLI

## Workflow Options

When you run the script, you'll choose one of two deployment types:

### Option A: Simple Inline Workflow

Creates a single workflow file with all steps embedded.

**Best for:** Most use cases - simple, clear, and easy to maintain

**Pros:**
- All code in one file
- Easy to understand and customize
- No external dependencies
- Can be manually triggered to rebuild anytime

**Cons:**
- Must update each repo individually if used across multiple repos

### Option B: Remote Shared Workflow

References a centralized shared workflow from an external repository.

**Best for:** Managing multiple repositories with consistent workflows

**Pros:**
- Update once, apply everywhere
- Centralized workflow management
- Consistent across all repos

**Cons:**
- Requires separate shared workflow repository (must be public)
- External dependency

## Prerequisites

- Git repository with a remote on GitHub
- Dockerfile in your repository
- Docker Hub account
- [GitHub CLI](https://cli.github.com/) (required for automatic setup)

## Interactive Setup Process

The script will ask you for:

1. **Deployment Type** - Choose A or B (default: A)
2. **Docker Hub Username** - Your Docker Hub username (auto-detected from GitHub)
3. **Docker Hub Token** - Access token from Docker Hub
4. **Docker Image Name** - Full image name (default: `username/repo-name`)
5. **Dockerfile Path** - Location of Dockerfile (default: `./Dockerfile`)
6. **Build Context** - Docker build context (default: `.`)
7. **Target Platforms** - Platforms to build (default: `linux/amd64,linux/arm64`)

## Features

### Auto-Detection
- Automatically detects your GitHub username from git remote
- Prepopulates Docker Hub username
- Prepopulates image name as `username/repo-name`

### Smart Validation
- Two attempts for each required input before exiting
- Automatic lowercase conversion for image names (Docker requirement)
- Clear error messages and helpful prompts

### Full Automation
- Sets GitHub secrets automatically
- Commits and pushes workflow files
- Provides helpful next-step commands

## What Gets Created

Depending on your choice:

**Option A:**
- `.github/workflows/ci.yml` - Complete workflow with all steps

**Option B:**
- `.github/workflows/ci.yml` - CI workflow that references remote shared workflow

**Plus GitHub Secrets (both options):**
- `DOCKERHUB_USERNAME` - Your Docker Hub username
- `DOCKERHUB_TOKEN` - Your Docker Hub access token

## Creating a Docker Hub Access Token

1. Log in to [Docker Hub](https://hub.docker.com/)
2. Go to **Account Settings** → **Security** → **Access Tokens**
3. Click **New Access Token**
4. Give it a description (e.g., "GitHub Actions")
5. Set permissions to **Read, Write, Delete**
6. Click **Generate**
7. Copy the token (you won't see it again!)

## Triggering the Workflow

The workflow automatically runs when you:

- **Push to main or develop** → Builds with tag based on branch
- **Push a version tag** → Builds with that tag (e.g., `v1.0.0`)
- **Manual trigger** → Use GitHub UI or run `gh workflow run ci.yml`

Example:

```bash
# Trigger on push to main (tags as 'latest')
git push origin main

# Create and push a version tag
git tag v1.0.0
git push origin v1.0.0

# Manual trigger
gh workflow run ci.yml
```

## Manual Secret Configuration

If you don't have GitHub CLI installed:

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add both secrets:
   - `DOCKERHUB_USERNAME` - Your Docker Hub username
   - `DOCKERHUB_TOKEN` - Your Docker Hub access token

## Troubleshooting

### "Not in a git repository" error

Run the script from your repository root:

```bash
cd /path/to/your/repo
./setup.sh
```

### "No remote origin found" error

Add a GitHub remote:

```bash
git remote add origin https://github.com/username/repo.git
```

### "repository name must be lowercase" error

The script now automatically converts image names to lowercase. If you see this error, your workflow was created with an older version. Re-run the setup script.

### Workflow fails with "authentication required"

Check your GitHub secrets:

```bash
gh secret list
```

If missing, re-run the setup script or add them manually.

### Multi-platform build fails

Try building for single platform only:

```
Target platforms: linux/amd64
```

### "workflow_dispatch trigger" error

This should be fixed in the latest version. The workflow files now include `workflow_dispatch:` trigger. Re-run the setup script to update.

## Advanced Usage

### Customizing the Workflow

After setup, you can edit the workflow files in `.github/workflows/` to:
- Add additional build steps
- Change trigger conditions
- Add notifications
- Integrate with other services

### Using with Option B (Shared Workflows)

For Option B, you need a separate public repository with the shared workflow:

1. Create a public repo (e.g., `my-workflows`)
2. Add `.github/workflows/docker-build-push.yml` with the reusable workflow
3. Reference it in your app repos using the setup script

The reusable workflow should follow the `workflow_call` pattern with inputs for image-name, image-tag, dockerfile-path, build-context, and platforms.

## Repository Structure

```
my-gha-workflows/
├── setup.sh              # Unified setup script
├── README.md             # This file
└── .gitattributes        # Git configuration
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
