# Shared Workflows Repository Setup

This guide walks you through setting up a central repository for reusable GitHub Actions workflows.

## Step 1: Create the Shared Workflows Repository

On GitHub:

1. Create a new repository named `my-workflows` (or whatever you prefer)
2. Make it **Public** (required for workflows to be accessible from other repos)
3. Clone it locally:
   ```bash
   git clone https://github.com/your-username/my-workflows.git
   cd my-workflows
   ```

## Step 2: Add the Reusable Workflow

Create the directory structure and add the workflow:

```bash
mkdir -p .github/workflows
```

Copy `docker-build-push.yml` to `.github/workflows/docker-build-push.yml`

Directory structure:
```
my-workflows/
├── .github/
│   └── workflows/
│       └── docker-build-push.yml
└── README.md
```

## Step 3: Commit and Push

```bash
git add .github/workflows/
git commit -m "Add Docker build and push workflow"
git push origin main
```

## Step 4: Use in Your App Repositories

In each of your app repos (e.g., `my-app`), create `.github/workflows/ci.yml`:

```yaml
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
    uses: your-username/my-workflows/.github/workflows/docker-build-push.yml@main
    with:
      image-name: ${{ vars.DOCKERHUB_USERNAME }}/my-app
      image-tag: ${{ github.ref_name == 'main' && 'latest' || github.ref_name }}
      dockerfile-path: './Dockerfile'
      build-context: '.'
      platforms: 'linux/amd64,linux/arm64'
    secrets:
      DOCKERHUB_USERNAME: ${{ secrets.DOCKERHUB_USERNAME }}
      DOCKERHUB_TOKEN: ${{ secrets.DOCKERHUB_TOKEN }}
```

**Important:** Change `your-username/my-workflows` to your actual GitHub username and repo name.

## Step 5: Add Docker Hub Secrets to Each App Repo

Even though the workflow is shared, each app repo still needs its own secrets:

1. Go to your app repo → Settings → Secrets and variables → Actions
2. Add:
   - `DOCKERHUB_USERNAME`
   - `DOCKERHUB_TOKEN`

## Advantages of This Setup

✅ **Single source of truth** - Update the workflow in one place  
✅ **Consistency** - All your repos use the same build logic  
✅ **Easy updates** - No need to modify each repo individually  
✅ **Scalable** - Add as many repos as you want

## File Reference Format

The reference format is:
```
{owner}/{repo}/.github/workflows/{filename}@{version}
```

Examples:
```yaml
# Using main branch
uses: your-username/my-workflows/.github/workflows/docker-build-push.yml@main

# Using a specific version tag
uses: your-username/my-workflows/.github/workflows/docker-build-push.yml@v1.0.0

# Using a specific commit SHA
uses: your-username/my-workflows/.github/workflows/docker-build-push.yml@abc123def456
```

## Tips

- **Keep the workflow repo public** - GitHub requires this for external access
- **Version your workflows** - Create git tags like `v1.0.0` for stable versions
- **Document inputs** - The workflow already has descriptions for all inputs
- **Test before deploying** - Test changes in the workflows repo before using in production

## Updating Workflows

To update the workflow for all repos:

1. Edit `.github/workflows/docker-build-push.yml` in `my-workflows` repo
2. Commit and push
3. All repos using `@main` will automatically use the new version (on next run)

To use a stable version instead:
- Create a git tag in `my-workflows`: `git tag v1.0.0`
- Update app repos to use `@v1.0.0` instead of `@main`
- Changes to `main` won't affect repos using the tag

## Example: Multiple App Repos Using Same Workflow

```
my-workflows/              (shared, public repo)
├── .github/workflows/
│   └── docker-build-push.yml

my-app-1/                  (app repo 1)
├── .github/workflows/
│   └── ci.yml            (uses: my-username/my-workflows/...)

my-app-2/                  (app repo 2)
├── .github/workflows/
│   └── ci.yml            (uses: my-username/my-workflows/...)

my-app-3/                  (app repo 3)
├── .github/workflows/
│   └── ci.yml            (uses: my-username/my-workflows/...)
```

All three apps use the same workflow from `my-workflows` repo!

---

**Need help?** Check GitHub's documentation on reusable workflows:  
https://docs.github.com/en/actions/using-workflows/reusing-workflows
