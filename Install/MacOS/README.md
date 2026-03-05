# macOS Configuration Toolkit

Capture your macOS system configuration and generate automation scripts for new Macs.

## What This Does

1. **Capture** your current Mac setup (apps, settings, preferences)
2. **Generate** a setup script to recreate it on new Macs
3. **Store** captures locally (not in git)

## Quick Start

### 1. Capture Your Current Mac

```bash
cd ~/Git/Gitlab/scrolls/Install/MacOS

# Capture to local storage (NOT git)
./capture-config.sh
```

This creates a timestamped folder in `~/Documents/MacOSConfigs/` with all your settings.

### 2. Generate Setup Script

```bash
# Find your latest capture
LATEST=$(ls -t ~/Documents/MacOSConfigs/ | head -1)

# Generate deployment script
./generate-setup.sh -c ~/Documents/MacOSConfigs/$LATEST
```

This creates `generated-macos-setup.sh` - your automated setup script.

### 3. Use on New Mac

```bash
# 1. Clone scrolls repo on new Mac
git clone <your-repo>

# 2. Copy your generated script to the new Mac
# (USB drive, AirDrop, network share, etc.)

# 3. Run it
chmod +x generated-macos-setup.sh
./generated-macos-setup.sh
```

Done! Your preferences, apps, and settings applied.

## What Gets Captured

### System Preferences
- ✅ Dock settings (size, position, auto-hide)
- ✅ Finder preferences (show extensions, path bar, etc.)
- ✅ Trackpad/Mouse settings
- ✅ Screenshot preferences
- ✅ Global UI settings (dark mode, etc.)
- ✅ Safari, Terminal, Menu Bar configs

### Applications & Packages
- ✅ Homebrew formulae and casks (`Brewfile`)
- ✅ App Store applications (via `mas-cli`)
- ✅ All installed apps list
- ✅ Homebrew taps and services

### Development Tools
- ✅ Xcode/CLI tools
- ✅ Git, Python, Node, Ruby versions
- ✅ Shell configuration (.zshrc, .bashrc)
- ✅ Installed fonts

### System Configuration
- ✅ LaunchAgents and LaunchDaemons
- ✅ Login items
- ✅ Default shell
- ✅ Network settings
- ✅ System version and hardware info

## Scripts

### `capture-config.sh`
Captures your complete macOS configuration.

**Usage:**
```bash
./capture-config.sh [-o output_dir]

# Default output: ~/Documents/MacOSConfigs/
# Custom output:
./capture-config.sh -o ~/Backups/MacConfigs
```

**What it creates:**
- 12+ files with system settings
- Brewfile for package restoration
- defaults (preferences) exports
- Summary README

### `generate-setup.sh`
Generates deployment script from capture.

**Usage:**
```bash
./generate-setup.sh -c <capture_dir> [-o output_file]

# Example:
./generate-setup.sh -c ~/Documents/MacOSConfigs/2026-02-19_143022
```

**Output:**
- `generated-macos-setup.sh` - Complete setup script

## Where to Store Captures

**Recommended:**
```
~/Documents/MacOSConfigs/
├── 2026-02-19_my-mac/               # Your main config
├── 2026-03-15_after-sonoma/         # After OS update
└── automation/
    └── generated-macos-setup.sh     # Generated script
```

**Don't commit captures to git** - They can contain sensitive data and bloat the repo.

## Workflow for New Mac

```bash
# 1. Fresh macOS install (or factory reset)

# 2. Install Command Line Tools
xcode-select --install

# 3. Clone scrolls repo
git clone <your-repo>
cd scrolls/Install/MacOS

# 4. Copy your generated setup script
# (from old Mac, USB, cloud storage, etc.)

# 5. Run it
./generated-macos-setup.sh

# 6. Logout/login for all settings to take effect

# 7. Manually install App Store apps
mas install <app_id>

# 8. Sync dotfiles from scrolls/Configs/Shell/
```

## Regular Maintenance

**Before major OS update:**
```bash
# Snapshot current state
./capture-config.sh
```

**After installing new apps:**
```bash
# Capture updated state
./capture-config.sh

# Regenerate setup script
./generate-setup.sh -c ~/Documents/MacOSConfigs/LATEST
```

**Monthly backup:**
```bash
# Keep snapshots
./capture-config.sh -o ~/Documents/MacOSConfigs/backup-$(date +%Y-%m)
```

## Important Notes

### Homebrew Bundle
The generated `Brewfile` can restore all your Homebrew packages:
```bash
# On new Mac:
brew bundle --file=Brewfile
```

### App Store Apps
Requires `mas-cli` for automation:
```bash
brew install mas

# List installed apps with IDs
mas list

# Install on new Mac
mas install 497799835  # Xcode
```

### Manual Configuration
Some things can't be automated:
- ❌ iCloud/Apple ID sign-in
- ❌ App-specific settings (use app export features)
- ❌ Keychain items
- ❌ Browser bookmarks/extensions
- ❌ Time Machine backups

## Pro Tips

1. **Create an alias** in your `.zshrc`:
   ```bash
   alias capmac='~/Git/Gitlab/scrolls/Install/MacOS/capture-config.sh'
   ```

2. **Keep Brewfile synced** separately if you want:
   ```bash
   # Generate fresh Brewfile
   brew bundle dump --file=~/Brewfile --force
   ```

3. **Export App Store app list** for reference:
   ```bash
   mas list > ~/macos-app-store-apps.txt
   ```

4. **Test in VM** or on secondary Mac first:
   - Use Parallels Desktop, VMware Fusion, or UTM
   - Test full deployment before committing to main machine

5. **Version your setup script** in gutter_bonez:
   ```bash
   cp generated-macos-setup.sh ~/Git/Gitlab/gutter_bonez/roles/macos/
   ```

## Troubleshooting

**"Permission denied" when running scripts**
```bash
chmod +x capture-config.sh
chmod +x generate-setup.sh
```

**"Homebrew not found"**
→ Install first: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

**"mas-cli not installed"**
```bash
brew install mas
```

**"Can't find my captures"**
→ Default location: `~/Documents/MacOSConfigs/`

**Generated script doesn't work**
→ Review it first! Some settings are user-specific
→ Test in VM before production use

**Settings don't apply immediately**
→ Many macOS preferences require logout/restart
→ Run `killall Dock` and `killall Finder` to restart them

## Security

- ✅ Pre-commit hook blocks secrets (if git hooks installed)
- ✅ Captures stay local (never committed)
- ✅ `.gitignore` prevents accidents
- ⚠️ Review generated scripts before sharing
- ⚠️ Brewfile may contain private taps

## What Doesn't Get Automated

- ❌ Keychain passwords/certificates
- ❌ Application-specific settings (most apps)
- ❌ iCloud/Apple ID configuration
- ❌ FileVault setup
- ❌ Touch ID fingerprints
- ❌ Wi-Fi passwords
- ❌ VPN configurations (export separately)

## Files in This Repo

```
Install/MacOS/
├── capture-config.sh       # Capture system state
├── generate-setup.sh       # Generate deployment script
├── README.md              # This file
└── .gitignore            # Keeps captures local
```

## Philosophy

**Tools in git, data stays local.**

- ✅ Scripts and documentation are version controlled
- ❌ Captures and generated files stay on your machine
- 🚀 Share scripts, not your personal Mac config

This keeps the repo clean and prevents accidental exposure of system details.

## Integration with Homebrew

The toolkit generates a `Brewfile` which is Homebrew's native format:

```ruby
# Example Brewfile
tap "homebrew/bundle"
tap "homebrew/cask-fonts"

brew "git"
brew "vim"
brew "tmux"

cask "iterm2"
cask "visual-studio-code"
cask "docker"

mas "Xcode", id: 497799835
```

Restore with: `brew bundle --file=Brewfile`

## Comparison with Windows Toolkit

| Feature | macOS | Windows |
|---------|-------|---------|
| Capture script | ✅ Bash | ✅ PowerShell |
| Package manager | Homebrew | winget/chocolatey |
| System prefs | defaults | Registry |
| Auto-install apps | ✅ (Brewfile) | ❌ (manual) |
| GUI preferences | ✅ Most | ✅ Most |
| Local storage | ✅ | ✅ |

## Real Workflow Example

```bash
# ========================================
# On your current Mac
# ========================================

cd ~/Git/Gitlab/scrolls/Install/MacOS

# Capture everything
./capture-config.sh

# Output:
# [+] Capturing macOS configuration to: ~/Documents/MacOSConfigs/2026-02-19_143022
# [*] Capturing system information...
# [*] Capturing Homebrew packages...
# ... (12 files captured)

# Generate automation
./generate-setup.sh -c ~/Documents/MacOSConfigs/2026-02-19_143022

# Output: generated-macos-setup.sh created

# Copy to USB drive for new Mac
cp generated-macos-setup.sh /Volumes/USB/

# ========================================
# On new Mac
# ========================================

# 1. Install Command Line Tools
xcode-select --install

# 2. Copy script from USB
cp /Volumes/USB/generated-macos-setup.sh ~/

# 3. Run it
chmod +x ~/generated-macos-setup.sh
~/generated-macos-setup.sh

# 4. Logout/login
# 5. Done!
```

---

**Keep it simple**: One capture, generate script, deploy to new Macs.

**For Control D QA infrastructure use.**