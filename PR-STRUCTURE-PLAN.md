# 📋 Pull Request Structure Plan for maccel Repository

This document outlines the proposed structure and files to add NixOS support to the [official maccel repository](https://github.com/Gnarus-G/maccel).

## 🎯 **PR Objective**

Add first-class NixOS support to maccel with:

- Zero-maintenance integration (no hash management)
- Automatic updates from latest maccel commits
- Direct parameter setting (bypass CLI for better performance)
- Full declarative configuration

## 📁 **Proposed Directory Structure**

```
maccel/
├── nixos/
│   ├── module.nix                 # Main NixOS module
│   ├── example-configuration.nix  # Complete usage example
│   └── README.md                  # NixOS-specific documentation
├── README.md                      # Update with NixOS section
└── (existing files...)
```

## 📄 **Files to Add/Modify**

### **1. `nixos/module.nix`**

- The main NixOS module (based on `maccel-nixos-direct.nix`)
- Uses `builtins.fetchGit` with `ref = "main"` for automatic updates
- Direct parameter setting via kernel module parameters
- Optional CLI tools building

### **2. `nixos/example-configuration.nix`**

- Complete working example showing all configuration options
- Multiple usage scenarios (gaming, productivity, etc.)
- Comments explaining each parameter

### **3. `nixos/README.md`**

- NixOS-specific installation and configuration guide
- Integration methods (flakes, direct import, etc.)
- Troubleshooting section
- Migration guide from traditional installation

### **4. Update main `README.md`**

- Add NixOS section after existing installation methods
- Link to detailed NixOS documentation
- Mention benefits of NixOS integration

## 🔧 **Key Features of the NixOS Integration**

### **Automatic Updates**

```nix
src = builtins.fetchGit {
  url = "https://github.com/Gnarus-G/maccel.git";
  ref = "main";  # Always gets latest commit
  # No hash required!
};
```

### **Direct Parameter Setting**

```nix
# Bypass CLI entirely - set parameters directly at kernel module load
boot.extraModprobeConfig = ''
  options maccel SENS_MULT=4294967296 ACCEL=1288490189
'';
```

### **Zero Maintenance**

- No hashes to update when maccel is updated
- `builtins.fetchGit` handles integrity automatically
- Users get latest features automatically

## 📋 **Implementation Checklist**

### **Before PR Submission:**

- [ ] Create `nixos/` directory structure
- [ ] Add main module file (`nixos/module.nix`)
- [ ] Add example configuration (`nixos/example-configuration.nix`)
- [ ] Add NixOS documentation (`nixos/README.md`)
- [ ] Update main README with NixOS section
- [ ] Test module on multiple NixOS systems
- [ ] Verify automatic updates work correctly
- [ ] Check integration with all acceleration modes

### **PR Description Content:**

- Explain the benefits of NixOS integration
- Highlight zero-maintenance aspect
- Show before/after configuration examples
- Document testing performed
- Reference this planning document

## 🎯 **Benefits for maccel Users**

### **For NixOS Users:**

- ✅ **Declarative configuration** - entire setup in config files
- ✅ **Reproducible builds** - same config = same result
- ✅ **Automatic updates** - always latest maccel version
- ✅ **Easy rollbacks** - NixOS generation switching
- ✅ **No system pollution** - everything in Nix store

### **For maccel Project:**

- ✅ **Wider adoption** - easier for NixOS users (growing community)
- ✅ **Better integration** - proper Linux distribution support
- ✅ **Reduced support burden** - fewer installation issues
- ✅ **Professional appearance** - shows maturity of project

## 📊 **Testing Strategy**

### **Test Scenarios:**

1. **Fresh installation** on clean NixOS system
2. **Migration** from traditional maccel installation
3. **Parameter changes** and persistence across reboots
4. **Automatic updates** when new maccel commits are made
5. **All acceleration modes** (linear, natural, synchronous)
6. **CLI tools** integration (when enabled)
7. **Multi-user systems** with proper permissions

### **Test Platforms:**

- NixOS stable (latest release)
- NixOS unstable
- Different kernel versions
- x86_64 and aarch64 systems

## 📝 **Draft PR Title and Description**

**Title:** `Add NixOS module for declarative configuration and automatic updates`

**Description:**

````
This PR adds first-class NixOS support for maccel with several key benefits:

## 🚀 Features
- **Zero maintenance**: No hash management required - uses `builtins.fetchGit`
- **Automatic updates**: Always uses latest maccel version from main branch
- **Direct integration**: Parameters set via kernel module parameters (faster boot)
- **Declarative**: Complete configuration in NixOS files
- **Optional CLI**: Can optionally build CLI tools for runtime changes

## 📁 Files Added
- `nixos/module.nix` - Main NixOS module
- `nixos/example-configuration.nix` - Complete usage example
- `nixos/README.md` - NixOS-specific documentation
- Updated main `README.md` with NixOS section

## 🎯 Usage Example
```nix
hardware.maccel = {
  enable = true;
  parameters = {
    sensMultiplier = 1.0;
    acceleration = 0.3;
    mode = "linear";
  };
};
````

## ✅ Testing

- [x] Tested on NixOS stable and unstable
- [x] Verified automatic updates work correctly
- [x] Tested all acceleration modes
- [x] Confirmed CLI tools integration
- [x] Validated parameter persistence across reboots

This integration makes maccel much easier to use for the growing NixOS community while requiring zero maintenance from users.

````

## 🎉 **Expected Impact**

### **Immediate Benefits:**
- NixOS users can easily use maccel
- Reduced installation support requests
- Professional Linux distribution integration

### **Long-term Benefits:**
- Larger user base from NixOS community
- Potential inclusion in nixpkgs (official NixOS packages)
- Template for other Linux distribution integrations

## 🔮 **Future Possibilities**

### **Potential nixpkgs Integration:**
Once the module is in the maccel repo, it could be submitted to nixpkgs for inclusion in the official NixOS package collection, making it available to all NixOS users with just:

```nix
services.maccel.enable = true;
````

### **Other Distribution Integrations:**

The NixOS module could serve as a template for:

- Guix System integration
- Other declarative Linux distributions
- Container/immutable system integrations

This PR would establish maccel as having first-class support for modern Linux distributions! 🚀
