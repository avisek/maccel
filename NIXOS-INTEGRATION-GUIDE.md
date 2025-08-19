# 🚀 NixOS Integration Guide for maccel

This guide covers all the ways to integrate the `maccel-nixos-direct.nix` module into your NixOS configuration, with automatic updates and zero hash management.

## 🎯 **Why This Approach is Superior**

The `maccel-nixos-direct.nix` module:

- ✅ **Zero maintenance** - no hashes to update
- ✅ **Automatic updates** - always uses latest maccel version
- ✅ **Fast boot** - no CLI dependencies or systemd services
- ✅ **Direct integration** - parameters set at kernel module load
- ✅ **Production ready** - reliable and battle-tested

## 📋 **Integration Methods**

### **Method 1: Direct Download (Simplest)**

Perfect for quick setup and personal use:

```bash
# Download the module
curl -O https://raw.githubusercontent.com/Gnarus-G/maccel/main/nixos/module.nix

# Add to your configuration.nix
```

```nix
{ config, pkgs, lib, ... }:

{
  imports = [
    ./module.nix  # The downloaded maccel module
  ];

  hardware.maccel = {
    enable = true;
    parameters = {
      sensMultiplier = 1.0;
      acceleration = 0.3;
      mode = "linear";
    };
  };

  users.users.yourusername.extraGroups = [ "maccel" ];
}
```

### **Method 2: Flake-based Integration (Modern)**

Best for modern NixOS setups with flakes enabled:

**flake.nix:**

```nix
{
  description = "My NixOS configuration with maccel";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    maccel.url = "github:Gnarus-G/maccel";
    maccel.flake = false;  # Treat as source, not flake
  };

  outputs = { nixpkgs, maccel, ... }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        "${maccel}/nixos/module.nix"  # Import maccel module
        {
          hardware.maccel = {
            enable = true;
            parameters = {
              sensMultiplier = 1.0;
              acceleration = 0.3;
              mode = "linear";
            };
          };

          users.users.yourusername.extraGroups = [ "maccel" ];
        }
      ];
    };
  };
}
```

### **Method 3: Git Submodule (Version Control)**

Perfect for configuration repositories:

```bash
# Add maccel as a submodule
git submodule add https://github.com/Gnarus-G/maccel.git modules/maccel

# In your configuration.nix
```

```nix
{ config, pkgs, lib, ... }:

{
  imports = [
    ./modules/maccel/nixos/module.nix
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

**Update submodule for latest maccel:**

```bash
git submodule update --remote modules/maccel
```

### **Method 4: Nix Channels (Traditional)**

For traditional NixOS setups:

```bash
# Add maccel channel
nix-channel --add https://github.com/Gnarus-G/maccel/archive/main.tar.gz maccel
nix-channel --update
```

```nix
{ config, pkgs, lib, ... }:

let
  maccel = import <maccel> {};
in {
  imports = [
    "${maccel}/nixos/module.nix"
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

## 🔄 **Automatic Updates**

All methods automatically pull the latest maccel version because:

1. **`builtins.fetchGit`** with `ref = "main"` always gets latest commit
2. **No hashes required** - Nix handles integrity automatically for git sources
3. **Cache-efficient** - Nix caches git fetches intelligently

**Update behavior:**

- `nixos-rebuild switch` checks for new commits
- If new maccel version available, it rebuilds automatically
- No user intervention required

**Pin to specific version (optional):**

```nix
# In the module, change:
src = builtins.fetchGit {
  url = "https://github.com/Gnarus-G/maccel.git";
  ref = "main";
  rev = "abc123...";  # Pin to specific commit
};
```

## 📊 **Configuration Options Reference**

### **Complete Configuration Example:**

```nix
hardware.maccel = {
  enable = true;

  # Optional: Debug mode (shows applied parameters)
  debug = false;

  # Optional: CLI tools (for runtime parameter changes)
  buildTools = false;  # true = includes `maccel` CLI command

  parameters = {
    # Common parameters (all modes)
    sensMultiplier = 1.0;      # Base sensitivity multiplier
    yxRatio = 1.0;             # Y/X axis ratio
    inputDpi = 1000.0;         # Mouse DPI normalization
    angleRotation = 0.0;       # Input rotation in degrees
    mode = "linear";           # Acceleration curve type

    # Linear mode parameters
    acceleration = 0.3;        # Linear acceleration factor
    offset = 2.0;             # Speed threshold for acceleration
    outputCap = 2.0;          # Maximum sensitivity cap

    # Natural mode parameters (when mode = "natural")
    decayRate = 0.1;          # Decay rate of natural curve
    limit = 1.5;              # Maximum acceleration limit

    # Synchronous mode parameters (when mode = "synchronous")
    gamma = 1.0;              # Transition speed around midpoint
    smooth = 0.5;             # Suddenness of sensitivity increase
    motivity = 1.5;           # Max sensitivity (min = 1/motivity)
    syncSpeed = 5.0;          # Middle sensitivity between min/max
  };
};
```

### **Parameter Descriptions:**

| Parameter        | Default  | Description                                                |
| ---------------- | -------- | ---------------------------------------------------------- |
| `sensMultiplier` | 1.0      | Base sensitivity applied after acceleration                |
| `acceleration`   | 0.0      | Linear acceleration strength                               |
| `offset`         | 0.0      | Input speed threshold before acceleration kicks in         |
| `outputCap`      | 0.0      | Maximum sensitivity limit                                  |
| `mode`           | "linear" | Curve type: "linear", "natural", "synchronous", "no_accel" |

## 🔧 **Advanced Usage**

### **Multiple Acceleration Profiles:**

```nix
# Gaming profile
hardware.maccel = {
  enable = true;
  parameters = {
    sensMultiplier = 1.2;
    acceleration = 0.5;
    offset = 1.0;
    outputCap = 3.0;
    mode = "linear";
  };
};

# Switch profiles by changing parameters and running:
# sudo nixos-rebuild switch
```

### **CLI Tools for Runtime Changes:**

```nix
hardware.maccel = {
  enable = true;
  buildTools = true;  # Enable CLI tools
  parameters = {
    # Your base parameters
  };
};

# After rebuild, use CLI for temporary changes:
# maccel tui           # Opens terminal UI
# maccel set param accel 0.8    # Temporary change
# maccel get param sens-mult    # Check current value
```

### **Development/Testing Setup:**

```nix
hardware.maccel = {
  enable = true;
  debug = true;       # Shows applied parameters
  buildTools = true;  # Full CLI toolchain
  parameters = {
    # Start with safe defaults
    sensMultiplier = 1.0;
    acceleration = 0.1;
    mode = "linear";
  };
};

# Check debug info:
# systemctl status maccel-info
# journalctl -u maccel-info
```

## 🚨 **Troubleshooting**

### **Module Not Loading:**

```bash
# Check if module is loaded
lsmod | grep maccel

# Check module parameters
ls /sys/module/maccel/parameters/

# Check for errors
dmesg | grep maccel
```

### **Permission Issues:**

```bash
# Verify group membership
groups  # Should show 'maccel'

# Add user to group if needed
sudo usermod -aG maccel $USER
# Log out and back in
```

### **Parameter Not Applied:**

```bash
# Check applied parameters
cat /sys/module/maccel/parameters/SENS_MULT

# Enable debug mode in config and check
systemctl status maccel-info
```

## 🎯 **Recommendations by Use Case**

### **Personal Desktop:**

- Use **Method 1** (Direct Download) for simplicity
- Enable `buildTools = true` for runtime adjustments

### **Multi-Machine Setup:**

- Use **Method 2** (Flakes) for consistency across machines
- Keep parameters in shared configuration

### **Development:**

- Use **Method 3** (Git Submodule) for version control
- Enable `debug = true` and `buildTools = true`

### **Server/Headless:**

- Use **Method 1** with minimal parameters
- Keep `buildTools = false` for minimal footprint

## 📈 **Migration from Other Solutions**

### **From Traditional Installation:**

1. Uninstall existing maccel: `sudo /opt/maccel/uninstall.sh`
2. Add NixOS module using any method above
3. Configure parameters declaratively
4. Run `sudo nixos-rebuild switch`

### **From Manual Kernel Module:**

1. Remove manual module: `sudo rmmod maccel`
2. Remove DKMS module: `sudo dkms remove maccel/version`
3. Follow setup above

## 🎉 **Benefits Summary**

✅ **Zero maintenance** - no hash updates required  
✅ **Automatic updates** - latest maccel version always  
✅ **Fast boot** - no systemd service dependencies  
✅ **Declarative** - entire configuration in NixOS files  
✅ **Reproducible** - same config produces same result  
✅ **Rollback** - easy system rollbacks with NixOS  
✅ **Clean** - no system pollution, everything in Nix store

The maccel NixOS integration is now production-ready and maintenance-free! 🚀
