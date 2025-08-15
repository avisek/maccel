# maccel on NixOS: Complete Solutions Summary

This document provides a comprehensive overview of all possible approaches to make maccel work on NixOS declaratively.

## 🎯 Recommended Solution: Full NixOS Module

**Location**: `maccel-nixos-module.nix`

This is the most comprehensive and NixOS-native approach that handles all aspects declaratively:

### ✅ What it Provides:

- **Complete Integration**: Kernel module, CLI tools, TUI, udev rules, permissions
- **Declarative Configuration**: All settings managed through NixOS options
- **Automatic Building**: Builds against your specific kernel version
- **Parameter Persistence**: Handles configuration persistence across reboots
- **Security**: Proper group management and permission handling
- **Debug Support**: Optional debug builds for troubleshooting

### 📋 Usage:

```nix
hardware.maccel = {
  enable = true;
  parameters = {
    sensMultiplier = 1.0;
    acceleration = 0.3;
    mode = "linear";
  };
};
```

### 🔧 Installation Methods:

1. **Flake-based** (modern): `flake.nix`
2. **Direct import**: Download and import module
3. **Local clone**: Git clone and reference

---

## 🔄 Alternative Approach 1: Overlay + Service

For users who prefer a more modular approach:

```nix
# overlay.nix
final: prev: {
  maccel = prev.callPackage ./maccel-package.nix {};
}

# configuration.nix
{
  nixpkgs.overlays = [ (import ./overlay.nix) ];

  environment.systemPackages = [ pkgs.maccel ];
  boot.kernelModules = [ "maccel" ];

  systemd.services.maccel-setup = {
    # Custom service configuration
  };
}
```

### ✅ Pros:

- More granular control
- Can be mixed with other approaches
- Easier to understand for Nix beginners

### ❌ Cons:

- Manual service configuration required
- No declarative parameter management
- More setup required

---

## 🔄 Alternative Approach 2: Custom Derivation

For minimal setups or specialized use cases:

```nix
# maccel-minimal.nix
{ pkgs, ... }:

let
  maccel-kernel = pkgs.linuxKernel.packages.linux.callPackage ./maccel-driver.nix {};
  maccel-cli = pkgs.rustPlatform.buildRustPackage { /* ... */ };
in {
  boot.extraModulePackages = [ maccel-kernel ];
  environment.systemPackages = [ maccel-cli ];

  # Manual configuration required for:
  # - Group creation
  # - Udev rules
  # - Parameter persistence
}
```

### ✅ Pros:

- Minimal footprint
- Full control over each component
- Good for learning Nix packaging

### ❌ Cons:

- Significant manual configuration
- No automatic parameter management
- More maintenance overhead

---

## 🔄 Alternative Approach 3: DKMS-style Module

Using NixOS's support for DKMS-like modules:

```nix
{
  boot.kernelModules = [ "maccel" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [
    (callPackage ({ stdenv, kernel, fetchFromGitHub }:
      stdenv.mkDerivation {
        # DKMS-style derivation
      }
    ) {})
  ];
}
```

### ✅ Pros:

- Familiar to DKMS users
- Simple kernel module handling
- Good for kernel-only needs

### ❌ Cons:

- Doesn't handle CLI tools
- No parameter management
- Missing system integration

---

## 🔄 Alternative Approach 4: Home Manager Integration

For user-specific installations:

```nix
# home.nix
{ pkgs, ... }:

{
  home.packages = [ pkgs.maccel-cli ];

  # User-level configuration
  xdg.configFile."maccel/config.toml".text = ''
    sensitivity = 1.0
    acceleration = 0.3
  '';
}
```

### ✅ Pros:

- User-specific configuration
- No root permissions needed for CLI
- Good for multi-user systems

### ❌ Cons:

- Still needs system-level kernel module
- Limited to user space tools
- Requires separate system configuration

---

## 🏗️ Development Approaches

### For Module Development:

```bash
# Use the development shell
nix develop

# Test individual components
nix-build -A maccel-kernel-module
nix-build -A maccel-tools

# Update hashes automatically
./update-hashes.sh
```

### For Custom Builds:

```nix
# Override specific options
hardware.maccel = {
  enable = true;
  debug = true;  # Enable for development
};

# Or use custom source
nixpkgs.overlays = [(final: prev: {
  maccel-src = prev.fetchFromGitHub {
    owner = "your-fork";
    repo = "maccel";
    # ... your custom version
  };
})];
```

---

## 📊 Comparison Matrix

| Approach              | Complexity | Features    | Maintenance | Declarative |
| --------------------- | ---------- | ----------- | ----------- | ----------- |
| **Full Module**       | Medium     | Complete    | Low         | Full        |
| **Overlay + Service** | Medium     | Good        | Medium      | Partial     |
| **Custom Derivation** | High       | Basic       | High        | Minimal     |
| **DKMS-style**        | Low        | Kernel only | Medium      | Partial     |
| **Home Manager**      | Low        | User tools  | Low         | User-level  |

---

## 🎯 Recommendations by Use Case

### 🏢 **Production Systems**

→ Use the **Full NixOS Module** for complete declarative management

### 🧪 **Development/Testing**

→ Use the **Full Module with debug enabled** or **Custom Derivation** for flexibility

### 👤 **Personal Systems**

→ Use the **Full NixOS Module** with user group assignment

### 🏫 **Multi-user Systems**

→ Combine **Full Module** (system) + **Home Manager** (user configs)

### 🔬 **Learning/Educational**

→ Start with **Custom Derivation** to understand components, then move to **Full Module**

---

## 🚀 Getting Started

1. **Quick Start**: Copy `maccel-nixos-module.nix` and `maccel-configuration-example.nix`
2. **Update Hashes**: Run `./update-hashes.sh`
3. **Configure**: Set your preferred parameters in `hardware.maccel.parameters`
4. **Deploy**: `sudo nixos-rebuild switch`
5. **Use**: Run `maccel tui` to configure or `maccel get param sens-mult` to check values

---

## 🔧 Troubleshooting All Approaches

### Common Issues:

1. **Wrong hashes**: Use `update-hashes.sh` or `nix-prefetch-git`
2. **Kernel incompatibility**: Ensure kernel headers are available
3. **Permission errors**: Check group membership with `groups`
4. **Module not loading**: Check `dmesg | grep maccel`
5. **Build failures**: Enable debug mode or check `journalctl -xe`

### Debug Commands:

```bash
# Check module status
lsmod | grep maccel

# Check service status
systemctl status maccel-set-defaults

# Check logs
journalctl -u maccel-set-defaults
dmesg | grep maccel

# Check permissions
ls -la /sys/module/maccel/parameters/
groups
```

---

## 📚 Additional Resources

- **NixOS Manual**: [Writing Modules](https://nixos.org/manual/nixos/stable/#sec-writing-modules)
- **Nixpkgs Manual**: [Linux Kernel](https://nixos.org/manual/nixpkgs/stable/#sec-linux-kernel)
- **maccel Documentation**: [Official Guide](https://www.maccel.org/)
- **NixOS Wiki**: [Kernel Modules](https://nixos.wiki/wiki/Linux_kernel)

The **Full NixOS Module** approach provides the most complete, maintainable, and NixOS-native solution for integrating maccel into your system declaratively.
