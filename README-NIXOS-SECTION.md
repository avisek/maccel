# Proposed addition to main README.md

This section should be added after the existing installation methods in the main README.md:

---

## NixOS

For NixOS users, maccel provides a declarative module with automatic updates and zero maintenance.

### Quick Setup

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

### Benefits

- ✅ **Zero maintenance** - no hash management required
- ✅ **Automatic updates** - always uses latest maccel version
- ✅ **Fast boot** - parameters set directly at kernel module load
- ✅ **Declarative** - entire configuration in NixOS files
- ✅ **Reproducible** - same config produces same result

### Documentation

For complete NixOS setup instructions, configuration options, and troubleshooting, see: [nixos/README.md](nixos/README.md)

---

(This section would be inserted in the main README.md after the existing "Arch (PKGBUILD)" section)
