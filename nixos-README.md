# maccel NixOS Integration

First-class NixOS support for [maccel](https://github.com/Gnarus-G/maccel) with automatic updates and zero maintenance.

## 🚀 **Quick Start**

Add to your `configuration.nix`:

```nix
{
  # Import the module
  imports = [ ./path/to/maccel/nixos/module.nix ];

  # Configure maccel
  hardware.maccel = {
    enable = true;
    parameters = {
      sensMultiplier = 1.0;
      acceleration = 0.3;
      mode = "linear";
    };
  };

  # Add your user to maccel group
  users.users.yourusername.extraGroups = [ "maccel" ];
}
```

Then rebuild: `sudo nixos-rebuild switch`

## ✨ **Key Benefits**

- ✅ **Zero maintenance** - no hash management required
- ✅ **Automatic updates** - always uses latest maccel version
- ✅ **Fast boot** - parameters set directly at kernel module load
- ✅ **Declarative** - entire configuration in NixOS files
- ✅ **Reproducible** - same config produces same result every time

## 📋 **Installation Methods**

### **Method 1: Direct Download**

```bash
# Download the module
curl -O https://raw.githubusercontent.com/Gnarus-G/maccel/main/nixos/module.nix

# Add to your configuration.nix
imports = [ ./module.nix ];
```

### **Method 2: Git Submodule**

```bash
# Add as submodule
git submodule add https://github.com/Gnarus-G/maccel.git modules/maccel

# Reference in configuration.nix
imports = [ ./modules/maccel/nixos/module.nix ];

# Update for latest version
git submodule update --remote modules/maccel
```

### **Method 3: Nix Flakes**

**flake.nix:**

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    maccel.url = "github:Gnarus-G/maccel";
    maccel.flake = false;
  };

  outputs = { nixpkgs, maccel, ... }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        "${maccel}/nixos/module.nix"
        {
          hardware.maccel.enable = true;
          # your config...
        }
      ];
    };
  };
}
```

## ⚙️ **Configuration Options**

### **Basic Setup**

```nix
hardware.maccel = {
  enable = true;                 # Enable maccel
  debug = false;                 # Debug mode (shows parameters)
  buildTools = false;            # CLI tools (optional)

  parameters = {
    # Your acceleration settings
  };
};
```

### **Common Parameters**

```nix
parameters = {
  sensMultiplier = 1.0;          # Base sensitivity multiplier
  yxRatio = 1.0;                 # Y/X axis ratio
  inputDpi = 1000.0;             # Mouse DPI normalization
  angleRotation = 0.0;           # Input rotation (degrees)
  mode = "linear";               # Acceleration curve type
};
```

### **Linear Mode** (`mode = "linear"`)

```nix
parameters = {
  mode = "linear";
  acceleration = 0.3;            # Acceleration strength
  offset = 2.0;                  # Speed threshold
  outputCap = 2.0;               # Maximum sensitivity cap
};
```

### **Natural Mode** (`mode = "natural"`)

```nix
parameters = {
  mode = "natural";
  decayRate = 0.1;               # Decay rate
  limit = 1.5;                   # Maximum acceleration
  offset = 2.0;                  # Speed threshold
};
```

### **Synchronous Mode** (`mode = "synchronous"`)

```nix
parameters = {
  mode = "synchronous";
  gamma = 1.0;                   # Transition speed around midpoint
  smooth = 0.5;                  # Suddenness of sensitivity increase
  motivity = 1.5;                # Max sensitivity (min = 1/motivity)
  syncSpeed = 5.0;               # Middle sensitivity between min/max
};
```

## 🔧 **Advanced Usage**

### **CLI Tools** (Optional)

Enable CLI tools for runtime parameter changes:

```nix
hardware.maccel = {
  enable = true;
  buildTools = true;  # Enable CLI tools
  parameters = {
    # Your base parameters
  };
};

# After rebuild, use:
# maccel tui                    # Interactive terminal UI
# maccel get param sens-mult    # Check current values
# maccel set param accel 0.5    # Temporary runtime changes
```

### **Debug Mode**

Enable debug mode to see applied parameters:

```nix
hardware.maccel = {
  enable = true;
  debug = true;  # Enable debug mode
  parameters = {
    # Your parameters
  };
};

# Check debug output:
# systemctl status maccel-info
# journalctl -u maccel-info
```

### **Multiple Profiles**

Switch between different configurations:

```nix
# Gaming profile
hardware.maccel.parameters = {
  sensMultiplier = 1.2;
  acceleration = 0.8;
  offset = 1.0;
  outputCap = 4.0;
  mode = "linear";
};

# Change to productivity profile by editing config and:
# sudo nixos-rebuild switch
```

## 🔄 **How Automatic Updates Work**

The module uses `builtins.fetchGit` with `ref = "main"` to automatically fetch the latest maccel version:

```nix
src = builtins.fetchGit {
  url = "https://github.com/Gnarus-G/maccel.git";
  ref = "main";  # Always gets latest commit
  # No hash required - Nix handles integrity!
};
```

**Update behavior:**

- `nixos-rebuild switch` checks for new commits
- If newer version available, rebuilds automatically
- No user intervention or hash management required

**Pin to specific version** (optional):

```nix
# Add to the module's src:
rev = "abc123...";  # Pin to specific commit
```

## 🚨 **Troubleshooting**

### **Module Not Loading**

```bash
# Check if module is loaded
lsmod | grep maccel

# Check for errors
dmesg | grep maccel

# Verify module file exists
find /nix/store -name "maccel.ko"
```

### **Permission Issues**

```bash
# Check group membership
groups  # Should show 'maccel'

# Add user to group if needed
sudo usermod -aG maccel $USER
# Log out and back in
```

### **Parameters Not Applied**

```bash
# Check applied parameters
cat /sys/module/maccel/parameters/SENS_MULT

# Enable debug mode and check
systemctl status maccel-info
```

### **Build Failures**

```bash
# Check if kernel headers are available
ls /lib/modules/$(uname -r)/build

# Enable debug mode for detailed logs
hardware.maccel.debug = true;
```

## 📈 **Migration from Traditional Installation**

### **From Shell Script Installation**

1. **Uninstall existing maccel:**

   ```bash
   sudo /opt/maccel/uninstall.sh
   ```

2. **Add NixOS configuration:**

   ```nix
   hardware.maccel = {
     enable = true;
     parameters = {
       # Your existing parameters here
       sensMultiplier = 1.0;  # Check your current values
       acceleration = 0.3;    # with: cat /sys/module/maccel/parameters/*
       mode = "linear";
     };
   };
   ```

3. **Apply configuration:**
   ```bash
   sudo nixos-rebuild switch
   ```

### **From DKMS Installation**

1. **Remove DKMS module:**

   ```bash
   sudo dkms remove maccel/$(dkms status | grep maccel | cut -d: -f2 | cut -d, -f1)
   sudo rmmod maccel
   ```

2. **Follow NixOS setup above**

## 🎯 **Use Case Examples**

### **Gaming Setup**

```nix
hardware.maccel.parameters = {
  sensMultiplier = 1.2;
  acceleration = 0.8;
  offset = 1.0;
  outputCap = 4.0;
  mode = "linear";
};
```

### **Productivity/Design Work**

```nix
hardware.maccel.parameters = {
  sensMultiplier = 1.0;
  acceleration = 0.2;
  offset = 3.0;
  outputCap = 1.8;
  mode = "natural";
  decayRate = 0.05;
  limit = 1.3;
};
```

### **No Acceleration**

```nix
hardware.maccel.parameters = {
  sensMultiplier = 1.5;  # Just sensitivity adjustment
  mode = "no_accel";
};
```

## 🛠️ **Development**

### **Testing Local Changes**

```nix
# Point to local maccel repository
src = /path/to/local/maccel/repo;
```

### **Building CLI Tools**

```nix
hardware.maccel.buildTools = true;
```

## 🔗 **Links**

- [maccel homepage](https://www.maccel.org/)
- [maccel repository](https://github.com/Gnarus-G/maccel)
- [NixOS manual](https://nixos.org/manual/nixos/stable/)
- [Report issues](https://github.com/Gnarus-G/maccel/issues)

## 📄 **License**

This NixOS integration follows the same license as maccel: [GPL-2.0-or-later](https://github.com/Gnarus-G/maccel/blob/main/LICENSE).
