# maccel NixOS Module

A declarative NixOS module for the maccel mouse acceleration driver. This module provides a fully declarative way to install, configure, and manage the maccel kernel module and tools on NixOS.

## Features

- **Declarative Configuration**: All maccel settings can be configured through NixOS options
- **Automatic Module Building**: Builds the kernel module for your specific kernel version
- **Parameter Persistence**: Handles parameter persistence across reboots
- **CLI/TUI Tools**: Includes the maccel CLI and TUI applications
- **Proper Permissions**: Sets up the maccel group and udev rules automatically
- **Debug Support**: Optional debug builds for troubleshooting

## Installation Methods

> 🚀 **Quick Start**: Want to try maccel immediately without hash complications? Use the [Quick Start Guide (No Hashes)](QUICK-START-NO-HASHES.md) or jump to [Method 2a](#method-2a-development-version-no-hashes-required).

### Method 1: Using Nix Flakes (Recommended)

Add this to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    maccel.url = "github:yourusername/maccel-nixos"; # Update with actual URL
  };

  outputs = { nixpkgs, maccel, ... }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        maccel.nixosModules.maccel
        {
          hardware.maccel.enable = true;
          # Add your other configuration here
        }
      ];
    };
  };
}
```

### Method 2: Direct Import (Production)

Download the module file and import it directly:

```bash
# Download the module
curl -O https://raw.githubusercontent.com/yourusername/maccel-nixos/main/maccel-nixos-module.nix
```

Then in your `configuration.nix`:

```nix
{
  imports = [
    ./maccel-nixos-module.nix
  ];

  hardware.maccel.enable = true;
}
```

### Method 2a: Direct Parameters (No CLI Required) ⭐

**Recommended**: For the fastest, most reliable setup without CLI dependencies:

```bash
# Download the direct parameters version
curl -O https://raw.githubusercontent.com/yourusername/maccel-nixos/main/maccel-nixos-direct.nix
```

Then in your `configuration.nix`:

```nix
{
  imports = [
    ./maccel-nixos-direct.nix  # No CLI needed - direct kernel parameters!
  ];

  hardware.maccel = {
    enable = true;
    parameters = {
      sensMultiplier = 1.0;
      acceleration = 0.3;
      mode = "linear";
    };
  };
}
```

**Benefits**: No CLI dependency, faster boot, more reliable, supports ALL 14 parameters.

### Method 2b: Development Version (No Hashes Required)

For quick testing without dealing with SHA256 hashes:

```bash
# Download the no-hashes development version
curl -O https://raw.githubusercontent.com/yourusername/maccel-nixos/main/maccel-nixos-module-no-hashes.nix
```

Then in your `configuration.nix`:

```nix
{
  imports = [
    ./maccel-nixos-module-no-hashes.nix  # Uses builtins.fetchGit - no hashes needed!
  ];

  hardware.maccel.enable = true;
}
```

**Note**: The CLI tools might fail on first build with a hash error, but the kernel module will work. Copy the correct hash from the error message if you need the CLI tools.

### Method 3: Using Local Clone

```bash
git clone https://github.com/yourusername/maccel-nixos
cd maccel-nixos
```

Then reference the module in your NixOS configuration:

```nix
{
  imports = [
    /path/to/maccel-nixos/maccel-nixos-module.nix
  ];

  hardware.maccel.enable = true;
}
```

## Configuration Options

The module provides the following configuration options under `hardware.maccel`:

### Basic Options

```nix
hardware.maccel = {
  enable = true;              # Enable the maccel driver
  debug = false;              # Enable debug build (default: false)
  autoload = true;            # Auto-load module at boot (default: true)
};
```

### Parameter Configuration

Set default parameters that will be applied when the module loads:

```nix
hardware.maccel = {
  enable = true;
  parameters = {
    sensMultiplier = 1.0;     # Sensitivity multiplier (default: null)
    acceleration = 0.3;       # Linear acceleration factor (default: null)
    offset = 2.0;            # Input offset (default: null)
    outputCap = 2.0;         # Maximum output multiplier (default: null)
    mode = "linear";         # Mode: "linear", "natural", or "synchronous" (default: null)
  };
};
```

### User Permissions

Add users to the maccel group to use CLI tools without sudo:

```nix
# Add specific user
users.users.yourusername.extraGroups = [ "maccel" ];

# Or add all wheel users to maccel group
users.users = lib.mapAttrs (name: user:
  if lib.elem "wheel" user.extraGroups
  then user // { extraGroups = user.extraGroups ++ [ "maccel" ]; }
  else user
) config.users.users;
```

## Complete Example Configuration

```nix
{ config, pkgs, lib, ... }:

{
  imports = [
    ./maccel-nixos-module.nix
  ];

  # Enable maccel with custom settings
  hardware.maccel = {
    enable = true;
    debug = false;              # Set to true for debugging
    autoload = true;

    # Set default parameters
    parameters = {
      sensMultiplier = 1.0;
      acceleration = 0.3;
      offset = 2.0;
      outputCap = 2.0;
      mode = "linear";
    };
  };

  # Add your user to the maccel group
  users.users.yourusername.extraGroups = [ "maccel" ];
}
```

## Usage

After enabling the module and rebuilding your system:

```bash
# Rebuild your NixOS configuration
sudo nixos-rebuild switch

# The kernel module should be loaded automatically
lsmod | grep maccel

# Use the CLI tools (no sudo needed if you're in the maccel group)
maccel get param sens-mult
maccel set param accel 0.5
maccel tui  # Opens the terminal UI
```

## What the Module Handles

The module automatically takes care of:

1. **Kernel Module**: Builds and installs the maccel.ko kernel module for your specific kernel
2. **CLI/TUI Tools**: Installs the maccel command-line and terminal UI applications
3. **System Group**: Creates the `maccel` group for permission management
4. **Udev Rules**: Sets up udev rules for proper device permissions
5. **Parameter Persistence**: Creates directories and scripts for parameter persistence across reboots
6. **Module Loading**: Optionally loads the module at boot time
7. **Default Parameters**: Applies your configured default parameters when the module loads

## Directory Structure

The module creates and manages these directories:

- `/var/lib/maccel/logs` - Log files from udev scripts
- `/var/lib/maccel/resets` - Parameter reset scripts for persistence

## Troubleshooting

### Getting Source Hashes

**Quick Solution**: Use the [no-hashes development module](#method-2a-development-version-no-hashes-required) to skip this step entirely!

For production deployment, you'll need to update the SHA256 hashes:

```bash
# Automatic hash updating (recommended)
./update-hashes.sh

# Manual hash fetching
nix-prefetch-git https://github.com/Gnarus-G/maccel.git --rev v0.5.6

# For the Rust dependencies (after first build attempt)
# The error message will show the correct hash to use
```

### Debug Mode

Enable debug mode for troubleshooting:

```nix
hardware.maccel = {
  enable = true;
  debug = true;  # This enables debug symbols and logging
};
```

Then check kernel logs:

```bash
dmesg | grep maccel
journalctl -f  # Watch live logs
```

### Module Not Loading

Check if the module is available:

```bash
# Check if module file exists
find /nix/store -name "maccel.ko" 2>/dev/null

# Try loading manually
sudo modprobe maccel

# Check for load errors
dmesg | tail
```

### Permission Issues

Ensure you're in the maccel group:

```bash
groups  # Should show 'maccel' in the list
sudo usermod -aG maccel $USER  # Add manually if needed
# Then log out and back in
```

## Building from Source

The module builds everything from source, ensuring compatibility with your specific kernel version. The build process:

1. Fetches the maccel source code from GitHub
2. Builds the kernel module against your running kernel
3. Builds the CLI/TUI tools using the Rust toolchain
4. Sets up all necessary system integration

## Comparison with Traditional Installation

| Traditional Install              | NixOS Module                    |
| -------------------------------- | ------------------------------- |
| Manual dependency management     | Automatic dependency resolution |
| DKMS-based building              | Nix-based building              |
| System-wide installation in /usr | Isolated Nix store installation |
| Manual group creation            | Automatic group management      |
| Manual udev rule installation    | Declarative udev rules          |
| Manual parameter persistence     | Automatic persistence setup     |
| Manual module loading            | Declarative module loading      |

## Contributing

To improve this module:

1. Update the SHA256 hashes with correct values
2. Test on different kernel versions
3. Add more configuration options as needed
4. Submit to nixpkgs for wider availability

## License

This module follows the same license as maccel (GPL-2.0-or-later).
