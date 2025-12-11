# Branch Protection Setup Guide

This guide explains how to configure branch protection rules for the main branch to ensure CI checks pass before merging.

## Prerequisites

- Repository admin access
- GitHub Actions CI workflow configured (`.github/workflows/ci.yml`)

## Setting Up Branch Protection Rules

### Via GitHub Web Interface

1. **Navigate to Repository Settings**
   - Go to your repository on GitHub
   - Click on "Settings" tab
   - Select "Branches" from the left sidebar

2. **Add Branch Protection Rule**
   - Click "Add rule" or "Add branch protection rule"
   - In "Branch name pattern", enter: `main`

3. **Configure Protection Rules**

   Enable the following options:

   #### Required Status Checks
   - ✅ **Require status checks to pass before merging**
   - ✅ **Require branches to be up to date before merging**
   
   Select the following status checks as required:
   - `Lint Code`
   - `Run Tests with Coverage`
   - `Build Docker Image`
   - `CI Status Check`

   #### Pull Request Requirements
   - ✅ **Require a pull request before merging**
   - Set "Required number of approvals before merging" to: `1` (recommended)
   - ✅ **Dismiss stale pull request approvals when new commits are pushed**

   #### Additional Protections
   - ✅ **Require conversation resolution before merging**
   - ✅ **Do not allow bypassing the above settings**
   - ✅ **Restrict who can push to matching branches** (optional, for team environments)

4. **Save Changes**
   - Click "Create" or "Save changes" at the bottom

## Verification

After setting up branch protection:

1. Create a test branch:
   ```bash
   git checkout -b test-branch-protection
   echo "test" >> README.md
   git add README.md
   git commit -m "Test branch protection"
   git push origin test-branch-protection
   ```

2. Create a Pull Request to `main`

3. Verify that:
   - CI workflow runs automatically
   - Merge button is disabled until all checks pass
   - Status checks are visible in the PR

## Branch Protection via GitHub CLI

Alternatively, you can set up branch protection using the GitHub CLI:

```bash
# Install GitHub CLI if not already installed
# https://cli.github.com/

# Authenticate
gh auth login

# Create branch protection rule
gh api repos/:owner/:repo/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["Lint Code","Run Tests with Coverage","Build Docker Image","CI Status Check"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true}' \
  --field restrictions=null
```

## Troubleshooting

### Status Checks Not Appearing

If required status checks don't appear in the dropdown:
1. Ensure the CI workflow has run at least once
2. Check that job names in `.github/workflows/ci.yml` match exactly
3. Wait a few minutes and refresh the page

### Cannot Merge Despite Passing Checks

1. Verify all required checks are green
2. Ensure branch is up to date with base branch
3. Check that all conversations are resolved (if enabled)

### Admin Override

Repository admins can temporarily bypass branch protection:
1. This should only be used in emergencies
2. Document the reason for override
3. Re-enable protection immediately after

## Best Practices

1. **Never commit directly to main**
   - Always use feature branches
   - Create pull requests for code review

2. **Keep CI fast**
   - Optimize test execution time
   - Use caching for dependencies
   - Run expensive checks only when necessary

3. **Monitor CI failures**
   - Fix broken builds immediately
   - Don't merge PRs with failing tests
   - Investigate flaky tests

4. **Regular maintenance**
   - Review and update required checks
   - Remove obsolete status checks
   - Update protection rules as team grows

## Related Documentation

- [GitHub Actions CI Workflow](../docs/github-actions.md)
- [CI/CD Overview](../docs/ci-cd-overview.md)
- [Deployment Guide](../docs/deployment-guide.md)
