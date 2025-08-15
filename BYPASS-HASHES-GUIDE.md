# How to Bypass Hashes for maccel NixOS Development

When developing or testing the maccel NixOS module, you often want to skip dealing with SHA256 hashes. Here are several approaches, from simplest to most advanced.

## 🚀 Quick Solutions

### Method 1: Use the No-Hashes Version (Recommended)

I've created `maccel-nixos-module-no-hashes.nix` which uses:

```nix
# For Git sources - no hash needed!
src = builtins.fetchGit {
  url = "https://github.com/Gnarus-G/maccel.git";
  ref = "v0.5.6";
  # Optional: specify exact commit with 'rev'
};

# For Cargo dependencies - Nix will tell you the real hash
cargoHash = lib.fakeHash;
```

**Usage:**

```nix
{
  imports = [ ./maccel-nixos-module-no-hashes.nix ];
  hardware.maccel.enable = true;
}
```

### Method 2: Use Local Development Path

Clone maccel locally and use the local path:

```bash
git clone https://github.com/Gnarus-G/maccel.git
cd maccel
```

Then in your configuration:

```nix
# Use local path - no fetching at all!
src = /path/to/local/maccel;
```

See `local-development-example.nix` for a complete example.

## 🔧 Alternative Hash Bypass Methods

### Method 3: Empty String (Limited Support)

For some older Nix versions:

```nix
sha256 = "";  # May work for some sources
```

### Method 4: Fake Hash Pattern

```nix
sha256 = lib.fakeSha256;        # Old style
sha256 = lib.fakeHash;          # New style
cargoSha256 = lib.fakeSha256;   # For Rust packages
cargoHash = lib.fakeHash;       # Newer Rust packages
```

### Method 5: Use --impure Flag (Nix 2.4+)

```bash
# For newer Nix versions with flakes
sudo nixos-rebuild switch --impure
nix build --impure .#maccel-kernel-module
```

### Method 6: Git with Specific Commit (Most Reliable)

```nix
src = builtins.fetchGit {
  url = "https://github.com/Gnarus-G/maccel.git";
  rev = "abc123...";  # Specific commit hash
  # No sha256 needed for builtins.fetchGit!
};
```

## 📋 Step-by-Step: Getting Started Without Hashes

### Option A: Use Pre-Made No-Hashes Module

1. **Copy the no-hashes module:**

   ```bash
   cp maccel-nixos-module-no-hashes.nix /etc/nixos/
   ```

2. **Import in your configuration.nix:**

   ```nix
   {
     imports = [ ./maccel-nixos-module-no-hashes.nix ];
     hardware.maccel.enable = true;
   }
   ```

3. **Build and expect one failure:**

   ```bash
   sudo nixos-rebuild switch
   ```

   The kernel module will build fine (uses `builtins.fetchGit`), but the Rust tools will fail with a message like:

   ```
   error: hash mismatch in fixed-output derivation
   got:    sha256-REAL_HASH_HERE...
   ```

4. **Update the cargoHash (optional):**
   If you want the CLI tools, copy the real hash from the error and replace `lib.fakeHash` in the module.

### Option B: Use Local Development

1. **Clone maccel locally:**

   ```bash
   git clone https://github.com/Gnarus-G/maccel.git
   cd maccel
   ```

2. **Use the local development example:**

   ```bash
   cp local-development-example.nix /etc/nixos/
   ```

3. **Edit the path in the config:**

   ```nix
   maccel-local-src = /path/to/your/maccel/clone;
   ```

4. **Import and build:**
   ```nix
   {
     imports = [ ./local-development-example.nix ];
     # Configuration is already included
   }
   ```

## 🎯 Which Method to Choose?

### For Quick Testing

→ **Use Method 1** (no-hashes module with `builtins.fetchGit`)

### For Development

→ **Use Method 2** (local path with your own maccel checkout)

### For Production

→ Get the real hashes with `./update-hashes.sh` and use the original module

## 🐛 Troubleshooting Hash Issues

### "hash mismatch" Error

This is normal when using fake hashes. The error message shows the correct hash:

```
got: sha256-ABC123...
```

Copy this hash and replace the fake one.

### "cannot fetch Git repository"

Check your internet connection and Git URL:

```bash
git clone https://github.com/Gnarus-G/maccel.git  # Test manually
```

### "evaluation aborted with error"

Your Nix version might not support `builtins.fetchGit`. Try the local path method instead.

### Cargo Build Fails

For Rust packages, try using `cargoLock` instead of `cargoHash`:

```nix
cargoLock = {
  lockFile = "${src}/Cargo.lock";
};
```

## 🔄 Development Workflow

### Iterative Development

1. **Start with no-hashes module** for initial testing
2. **Switch to local path** when you need to modify source
3. **Get real hashes** when ready for production

### Testing Changes

```bash
# Test kernel module only
nix-build -A config.boot.extraModulePackages.0

# Test CLI tools only
nix-build -A config.environment.systemPackages.0

# Test full system
sudo nixos-rebuild switch
```

## 🎉 Benefits of Each Approach

| Method              | Speed   | Reliability | Development | Production |
| ------------------- | ------- | ----------- | ----------- | ---------- |
| `builtins.fetchGit` | Fast    | High        | Good        | Avoid      |
| Local path          | Fastest | High        | Excellent   | No         |
| Fake hashes         | Medium  | Medium      | Good        | No         |
| Real hashes         | Medium  | Highest     | OK          | Best       |

## 📝 Important Notes

- **No-hash methods are for development only** - don't use in production
- **Always test with real hashes eventually** for production deployments
- **Local paths are fastest** for active development
- **`builtins.fetchGit` is most reliable** for quick testing without local setup

Choose the method that best fits your current development phase! 🚀
