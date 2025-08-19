# 🐭 maccel NixOS Flake

Zero-maintenance NixOS module for maccel mouse acceleration driver. No manual downloads, no hash management required!

## 🚀 Quick Start

Add to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    maccel.url = "github:yourusername/maccel-nixos";  # Replace with actual repo URL
  };

  outputs = { nixpkgs, maccel, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        maccel.nixosModules.default
        {
          hardware.maccel = {
            enable = true;
            parameters = {
              sensMultiplier = 1.0;
              acceleration = 0.3;
              mode = "linear";
            };
          };
        }
      ];
    };
  };
}
```

Then rebuild: `sudo nixos-rebuild switch --flake .`

## ✨ Features

- ✅ **Zero maintenance** - automatically works with latest maccel updates
- ✅ **No CLI dependency** - parameters set directly in kernel module
- ✅ **Flake-native** - no manual file downloads needed
- ✅ **Fast boot** - no systemd services required
- ✅ **Optional CLI tools** - add `buildTools = true` if needed

## 📋 Configuration Options

### Basic Setup

```nix
hardware.maccel = {
  enable = true;                    # Enable maccel driver
  buildTools = false;               # CLI tools (optional)
  debug = false;                    # Debug output (optional)
};
```

### All Parameters

```nix
hardware.maccel = {
  enable = true;
  parameters = {
    # Common (all modes)
    sensMultiplier = 1.0;          # Base sensitivity multiplier
    yxRatio = 1.0;                 # Y/X axis ratio
    inputDpi = 1000.0;             # Mouse DPI for normalization
    angleRotation = 0.0;           # Rotation in degrees
    mode = "linear";               # "linear", "natural", "synchronous", "no_accel"

    # Linear mode
    acceleration = 0.3;            # Linear acceleration factor
    offset = 2.0;                  # Acceleration threshold
    outputCap = 2.0;               # Maximum sensitivity cap

    # Natural mode
    decayRate = 0.1;               # Decay rate
    limit = 1.5;                   # Acceleration limit

    # Synchronous mode
    gamma = 1.0;                   # Transition speed
    smooth = 0.5;                  # Sensitivity increase suddenness
    motivity = 1.5;                # Max sensitivity (min = 1/motivity)
    syncSpeed = 5.0;               # Middle sensitivity value
  };
};
```

## 🎯 Usage Patterns

### Gaming Setup

```nix
hardware.maccel = {
  enable = true;
  buildTools = true;  # Enable CLI for tweaking
  parameters = {
    sensMultiplier = 1.2;
    acceleration = 0.5;
    offset = 1.5;
    outputCap = 3.0;
    mode = "linear";
  };
};
```

### Work/Productivity

```nix
hardware.maccel = {
  enable = true;
  buildTools = false;  # No CLI needed
  parameters = {
    sensMultiplier = 1.0;
    acceleration = 0.2;
    mode = "natural";
    decayRate = 0.15;
    limit = 1.3;
  };
};
```

### Server/Minimal

```nix
hardware.maccel = {
  enable = true;
  buildTools = false;
  parameters = {
    sensMultiplier = 1.0;
    acceleration = 0.1;
    mode = "linear";
  };
};
```

## 🔧 Advanced Usage

### With Home Manager

```nix
# In your flake inputs
home-manager.url = "github:nix-community/home-manager";
maccel.url = "github:yourusername/maccel-nixos";

# In your configuration
home-manager.users.myuser = {
  home.file.".maccel-gaming".text = ''
    #!/bin/bash
    maccel set param accel 0.7
    maccel set mode linear
  '';
};
```

### Multiple Hosts

```nix
nixosConfigurations = {
  desktop = nixpkgs.lib.nixosSystem {
    modules = [
      maccel.nixosModules.default
      { hardware.maccel = { enable = true; /* gaming config */ }; }
    ];
  };

  laptop = nixpkgs.lib.nixosSystem {
    modules = [
      maccel.nixosModules.default
      { hardware.maccel = { enable = true; /* work config */ }; }
    ];
  };
};
```

### Version Pinning

```nix
# Pin to specific commit for stability
maccel.url = "github:yourusername/maccel-nixos?ref=abc123";

# Or use follows for consistency
maccel = {
  url = "github:yourusername/maccel-nixos";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

## 🔍 Verification

After rebuilding, verify it's working:

```bash
# Check module is loaded
lsmod | grep maccel

# Check parameters are applied
cat /sys/module/maccel/parameters/SENS_MULT

# Use CLI tools (if buildTools = true)
maccel get param sens-mult
maccel tui

# Enable debug and check logs
systemctl status maccel-info  # (if debug = true)
```

## 📦 Available Exports

This flake provides:

- `nixosModules.default` - The main NixOS module
- `nixosModules.maccel` - Same as default
- `packages.kernel-module` - Just the kernel module
- `packages.cli-tools` - Just the CLI/TUI tools
- `overlays.default` - Overlay for nixpkgs

## 🆚 Comparison with Other Approaches

| Method              | Maintenance | Speed   | Dependencies |
| ------------------- | ----------- | ------- | ------------ |
| **This Flake** ⭐   | Zero        | Fastest | Minimal      |
| Traditional Install | High        | Slow    | Many         |
| Manual Module       | Medium      | Fast    | Some         |

## 🎉 Benefits

1. **No file downloads** - everything via flake inputs
2. **Auto-updates** - works with latest maccel commits
3. **Reproducible** - same input = same result
4. **Fast** - direct kernel parameters, no services
5. **Optional features** - CLI tools only when needed
6. **Standard** - follows Nix/NixOS best practices

Perfect for both beginners who want it to "just work" and experts who want full control! 🚀
