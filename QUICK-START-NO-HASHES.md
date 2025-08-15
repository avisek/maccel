# 🚀 Quick Start: maccel on NixOS (No Hashes Required!)

Get maccel working on NixOS in minutes without dealing with hash complications.

## ⚡ Super Quick Setup (2 Steps)

### 1. Copy the Development Module

```bash
# Download the no-hashes version
curl -O https://raw.githubusercontent.com/yourusername/maccel-nixos/main/maccel-nixos-module-no-hashes.nix

# Or if you're in the maccel repo already:
# cp maccel-nixos-module-no-hashes.nix /etc/nixos/
```

### 2. Add to Your NixOS Configuration

Edit your `/etc/nixos/configuration.nix`:

```nix
{ config, pkgs, lib, ... }:

{
  imports = [
    # ... your existing imports
    ./maccel-nixos-module-no-hashes.nix  # Add this line
  ];

  # Enable maccel
  hardware.maccel = {
    enable = true;

    # Optional: Set default parameters
    parameters = {
      sensMultiplier = 1.0;
      acceleration = 0.3;
      mode = "linear";
    };
  };

  # Add your user to maccel group (replace 'yourusername')
  users.users.yourusername.extraGroups = [ "maccel" ];

  # ... rest of your configuration
}
```

### 3. Build and Deploy

```bash
sudo nixos-rebuild switch
```

## ✅ What Happens

- ✅ **Kernel module builds** (uses `builtins.fetchGit` - no hash needed)
- ❌ **CLI tools might fail** on first build (shows correct hash in error)
- ✅ **Mouse acceleration works** even if CLI fails

## 🔧 If CLI Tools Fail (Optional Fix)

If you see an error like:

```
hash mismatch in fixed-output derivation '/nix/store/...-source'
got: sha256-RealHashHere...
```

1. **Copy the real hash** from the error message
2. **Edit the module** and replace `lib.fakeHash` with the real hash:
   ```nix
   cargoHash = "sha256-RealHashHere...";
   ```
3. **Rebuild**: `sudo nixos-rebuild switch`

## 🎯 Test It Works

```bash
# Check module is loaded
lsmod | grep maccel

# Test CLI (if it built successfully)
maccel get param sens-mult

# Test TUI interface
maccel tui
```

## 💡 What's Different?

This development version uses:

- **`builtins.fetchGit`** instead of `fetchFromGitHub` (no hash required)
- **`lib.fakeHash`** for Rust dependencies (shows real hash on first failure)
- **Same functionality** as the production version

## 🔄 Next Steps

- **For development**: Keep using this version
- **For production**: Run `./update-hashes.sh` and switch to the full module
- **For local development**: See `local-development-example.nix`

---

**That's it!** 🎉 You now have a working maccel installation on NixOS without dealing with hashes!
