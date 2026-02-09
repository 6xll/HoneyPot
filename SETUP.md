# Cowrie Integration Instructions

## How to Copy Cowrie Source Code Into Your Project

Instead of using Cowrie as a git submodule (which can be complex to manage), we recommend copying the Cowrie source directly into your repository. This gives you full control over the version and makes the project self-contained.

### Method 1: Manual Copy (Recommended)

1. **Clone Cowrie to a temporary location:**
   ```bash
   git clone https://github.com/cowrie/cowrie.git /tmp/cowrie-temp
   ```

2. **Copy Cowrie into your project:**
   ```bash
   # From your project root
   cp -r /tmp/cowrie-temp/* ./cowrie/
   
   # Remove the .git directory to avoid nested repositories
   rm -rf ./cowrie/.git
   ```

3. **Clean up the temporary clone:**
   ```bash
   rm -rf /tmp/cowrie-temp
   ```

4. **Add Cowrie to your repository:**
   ```bash
   git add cowrie/
   git commit -m "Add Cowrie honeypot source code (version X.X.X)"
   ```

### Method 2: Download Specific Release

If you want a specific version of Cowrie:

1. **Download a release:**
   ```bash
   # Replace X.X.X with the desired version
   wget https://github.com/cowrie/cowrie/archive/refs/tags/vX.X.X.tar.gz
   tar -xzf vX.X.X.tar.gz
   ```

2. **Copy to your project:**
   ```bash
   mkdir -p cowrie
   cp -r cowrie-X.X.X/* ./cowrie/
   rm -rf cowrie-X.X.X vX.X.X.tar.gz
   ```

3. **Commit to your repository:**
   ```bash
   git add cowrie/
   git commit -m "Add Cowrie honeypot version X.X.X"
   ```

## Why Not Use a Git Submodule?

While git submodules are a common way to include external repositories, they have some drawbacks:

- **Complexity**: Submodules require special git commands and can confuse team members
- **Update friction**: Updating submodules requires multiple steps
- **Deployment issues**: CI/CD pipelines need special handling for submodules
- **Version drift**: Different checkouts might have different submodule versions

By copying the source directly:
- ✅ Simpler deployment
- ✅ Complete version control
- ✅ Easier to understand project structure
- ✅ No special git commands needed
- ✅ Better for CI/CD pipelines

## Updating Cowrie

When you want to update Cowrie to a newer version:

1. **Check current version:**
   ```bash
   cat cowrie/README.md | head -n 10
   ```

2. **Download new version to temp location:**
   ```bash
   git clone https://github.com/cowrie/cowrie.git /tmp/cowrie-new
   ```

3. **Backup your configuration (if you modified Cowrie):**
   ```bash
   cp cowrie/cowrie.cfg cowrie.cfg.backup
   ```

4. **Replace with new version:**
   ```bash
   rm -rf cowrie/
   cp -r /tmp/cowrie-new ./cowrie
   rm -rf cowrie/.git
   rm -rf /tmp/cowrie-new
   ```

5. **Restore your configuration:**
   ```bash
   cp cowrie.cfg.backup cowrie/cowrie.cfg
   ```

6. **Commit the update:**
   ```bash
   git add cowrie/
   git commit -m "Update Cowrie to version Y.Y.Y"
   ```

## Alternative: Skip Copying Cowrie

If you prefer not to copy Cowrie source into your repository, you can use the official Cowrie Docker image (which is what we do in docker-compose.yml). The Docker image already contains Cowrie, so you don't need the source code locally.

### Benefits of Using Docker Image:
- No source code to manage
- Always get the latest stable version
- Smaller repository size

### To use only the Docker image:
- Simply use `docker-compose up -d` - Cowrie will be pulled automatically
- You only need the configuration files (cowrie.cfg) in your repository
- The `cowrie/` directory is not needed

## Directory Structure

After setup, your project should look like this:

```
HoneyPot/
├── cowrie/                          # (Optional) Cowrie source code
│   ├── bin/
│   ├── src/
│   ├── docs/
│   └── ...
├── cowrie-config/
│   └── cowrie.cfg                   # Cowrie configuration
├── grafana/
│   ├── dashboards/
│   │   └── cowrie-overview.json     # Pre-built dashboard
│   └── provisioning/
│       ├── datasources/
│       │   └── victorialogs.yaml    # VictoriaLogs datasource
│       └── dashboards/
│           └── dashboards.yaml      # Dashboard provisioning
├── docker-compose.yml               # Main orchestration file
├── promtail-config.yaml             # Log scraping configuration
├── README.md                        # Main documentation
├── SETUP.md                         # This file
└── .gitignore                       # Ignore patterns
```

## Next Steps

After copying Cowrie (or deciding to use the Docker image), follow the [README.md](README.md) Quick Start guide to launch your honeypot monitoring stack.
