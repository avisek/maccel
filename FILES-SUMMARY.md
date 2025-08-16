# 📁 Complete maccel NixOS Files Summary

Here's everything you need to get maccel working on NixOS, with options for both production and development.

## 🎯 Core Module Files

### Production (Recommended - Direct Parameters) ⭐

- **`maccel-nixos-direct.nix`** - Direct parameter approach (NO CLI required!)
  - Bypasses CLI completely - writes parameters directly to kernel
  - Fastest boot, most reliable, minimal dependencies
  - Uses traditional Linux kernel module parameters
  - Same configuration syntax, cleaner implementation

### Production (Full Functionality)

- **`maccel-nixos-module.nix`** - Complete NixOS module with CLI integration
  - Requires correct SHA256 hashes and working CLI
  - Includes full CLI/TUI toolchain
  - Slower boot due to systemd services

### Development (No Hashes Required)

- **`maccel-nixos-module-no-hashes.nix`** - Development module without hashes
  - Uses `builtins.fetchGit` (no source hash needed)
  - Uses `lib.fakeHash` for cargo (shows correct hash on failure)
  - Perfect for quick testing

## 🔧 Configuration Examples

### Standard Configuration

- **`maccel-direct-example.nix`** - Direct approach configuration ⭐

  - Uses direct parameter approach (fastest, most reliable)
  - No CLI dependency, no systemd services
  - Same simple configuration syntax

- **`maccel-configuration-example.nix`** - CLI-based configuration
  - Shows both module options (production/development)
  - Complete parameter examples with CLI integration
  - User group setup

### Development Configuration

- **`local-development-example.nix`** - Local development setup
  - Uses local maccel checkout
  - No network fetching required
  - Best for active development

## 📚 Documentation

### Getting Started

- **`QUICK-START-NO-HASHES.md`** - 2-step setup guide ⭐

  - Get running in minutes
  - No hash complications
  - Perfect for first-time users

- **`README-nixos.md`** - Complete installation guide
  - All installation methods
  - Configuration options
  - Troubleshooting

### Advanced Guides

- **`DIRECT-APPROACH-GUIDE.md`** - Direct parameters approach ⭐

  - How to bypass CLI entirely
  - Technical details of fixed-point conversion
  - Migration guide from CLI approach

- **`APPROACHES-COMPARISON.md`** - Complete comparison of all methods

  - Direct vs CLI vs Development approaches
  - Detailed pros/cons matrix
  - Recommendations by use case

- **`BYPASS-HASHES-GUIDE.md`** - Comprehensive hash bypass methods

  - Multiple approaches explained
  - Development workflow
  - Troubleshooting hash issues

- **`SOLUTIONS-SUMMARY.md`** - All possible approaches

  - Comparison of methods
  - Use case recommendations
  - Alternative solutions

- **`IMPLEMENTATION-CHECKLIST.md`** - Verification checklist
  - Step-by-step validation
  - Testing procedures
  - Production readiness

## 🛠️ Tools & Automation

### Hash Management

- **`update-hashes.sh`** - Automatic hash updater
  - Fetches correct SHA256 values
  - Updates both source and cargo hashes
  - Ready for production use

### Migration Tools

- **`migrate-to-direct.sh`** - Migration script ⭐
  - Migrate from CLI-based to direct approach
  - Automatic backup and conversion
  - Preserves your configuration

### Package Management

- **`flake.nix`** - Nix flake for modern package management
  - Packages as flake outputs
  - Development shell
  - Overlay support

## 🚀 Quick Start Decision Tree

### Just Want It Working? ⭐

→ Use **`maccel-nixos-direct.nix`** - fastest, most reliable, no CLI needed!

### Production Deployment?

→ Use **`maccel-nixos-direct.nix`** (recommended) or **`maccel-nixos-module.nix`** (with CLI)

### Quick Testing?

→ Use **`QUICK-START-NO-HASHES.md`** + **`maccel-nixos-module-no-hashes.nix`**

### Developing/Testing?

→ Use **`local-development-example.nix`** with local maccel checkout

### Learning All Options?

→ Read **`APPROACHES-COMPARISON.md`** + **`DIRECT-APPROACH-GUIDE.md`**

## 📋 File Usage Matrix

| File                                | Hash Required | Network Required | CLI Required | Best For      | Complexity |
| ----------------------------------- | ------------- | ---------------- | ------------ | ------------- | ---------- |
| `maccel-nixos-direct.nix` ⭐        | ❌ No         | ✅ Yes           | ❌ No        | Production    | Low        |
| `maccel-nixos-module.nix`           | ✅ Yes        | ✅ Yes           | ✅ Yes       | Full Features | Medium     |
| `maccel-nixos-module-no-hashes.nix` | ❌ No         | ✅ Yes           | ✅ Yes       | Quick Testing | Low        |
| `local-development-example.nix`     | ❌ No         | ❌ No            | ❌ No        | Development   | Medium     |
| `flake.nix`                         | ✅ Yes        | ✅ Yes           | ✅ Yes       | Modern Nix    | High       |

## 🎯 Recommended Combinations

### First-Time User ⭐

```bash
curl -O maccel-nixos-direct.nix
# Use directly - no hashes, no CLI dependency!
```

### Production (Recommended)

```bash
curl -O maccel-nixos-direct.nix
# Fastest, most reliable approach
```

### Production (Full Features)

```bash
curl -O maccel-nixos-module.nix
curl -O update-hashes.sh
./update-hashes.sh
# Includes CLI/TUI tools
```

### Developer

```bash
git clone maccel-repo
# Use local-development-example.nix
```

### Modern Nix User

```nix
# Use flake.nix with proper hashes
inputs.maccel.url = "github:...";
```

## 🔄 Migration Path

### Recommended Path ⭐

1. **Start**: `maccel-nixos-direct.nix` (immediate production use)
2. **Optional**: Add `buildTools = true` if CLI needed later

### Alternative Path

1. **Test**: `maccel-nixos-module-no-hashes.nix` (quick testing)
2. **Develop**: `local-development-example.nix` (modifications)
3. **Deploy**: `maccel-nixos-direct.nix` (production) or `maccel-nixos-module.nix` (full features)
4. **Scale**: `flake.nix` (infrastructure)

### Migration from CLI-based

1. **Run**: `./migrate-to-direct.sh` (automatic migration)
2. **Rebuild**: `sudo nixos-rebuild switch`

## ✅ What Each Method Gets You

### Core Functionality (All Methods)

- ✅ Kernel module loaded
- ✅ Mouse acceleration working
- ✅ udev rules installed
- ✅ maccel group created

### Full Functionality (Production Methods)

- ✅ CLI tools working
- ✅ TUI interface
- ✅ Parameter management
- ✅ Configuration persistence

### Development Benefits (Dev Methods)

- ✅ Fast iteration
- ✅ No hash management
- ✅ Local source control
- ✅ Debug support

---

**Choose your path based on your needs!** Each approach is designed for different use cases, from quick testing to production deployment. 🎉
