# Add Official NixOS Support with Declarative Configuration

## Summary

This PR adds comprehensive NixOS support to maccel through a flake module, enabling NixOS users to declaratively configure mouse acceleration parameters directly in their system configuration with all parameters support.

## Motivation

NixOS users have been unable to easily use maccel due to the imperative installation process and lack of declarative configuration options. This addition brings maccel to the NixOS ecosystem with first-class support, making it accessible to thousands of NixOS users who prefer declarative system management.

## Features

### 🎯 **Declarative Configuration**

- All acceleration parameters configurable through `hardware.maccel.parameters`
- Parameters applied directly as kernel module parameters for maximum efficiency
- Type-safe configuration with proper validation
- No manual kernel module or udev rule installation required

### 🔧 **Optional CLI/TUI Integration**

- `enableCli` option to install CLI tools for parameter discovery
- Real-time parameter tuning with `maccel tui`
- Session-only changes that don't interfere with NixOS config
- Seamless workflow: experiment with CLI → apply permanently via config

### 📦 **Complete Integration**

- Automatic kernel module building and loading
- Proper udev rules and permissions setup
- User group management (`maccel` group)
- Debug build support via `debug` option
- Optional CLI/TUI for parameter discovery

### ⚡ **Enhanced Efficiency**

- Direct kernel module parameter approach (vs reset scripts used in standard installation)
- Parameters revert to declared values after reboot

## Implementation

### Files Added

- `flake.nix` - Simple flake exporting the NixOS module
- `module.nix` - Comprehensive NixOS module with 20+ configuration options
- `README-flake.md` - Detailed NixOS-specific documentation

### Key Components

- **Kernel Module Build**: Integrates with NixOS kernel package system
- **Fixed-Point Conversion**: Automatic conversion of float parameters to kernel-compatible fixed-point integers
- **Parameter Mapping**: Complete mapping of all driver parameters to NixOS options
- **CLI Integration**: Optional Rust package building for CLI tools

## Usage Example

```nix
# flake.nix
{
  inputs.maccel.url = "github:Gnarus-G/maccel";
}

# configuration.nix
{inputs, ...}: {
  imports = [inputs.maccel.nixosModules.default];

  hardware.maccel = {
    enable = true;
    enableCli = true;  # Optional

    parameters = {
      mode = "linear";
      sensMultiplier = 1.0;
      acceleration = 0.3;
      offset = 2.0;
      outputCap = 2.0;
    };
  };

  users.groups.maccel.members = ["username"];  # For CLI access without sudo
}
```

## Workflow Benefits

1. **Discovery**: Use `maccel tui` to find optimal parameters in real-time
2. **Configuration**: Apply discovered values permanently in NixOS config
3. **Persistence**: Parameters automatically load on every boot via kernel module parameters
4. **Reproducibility**: Identical configuration across multiple machines

## Documentation Updates

- **README.md**: Added NixOS installation section with concise example
- **README-flake.md**: Comprehensive NixOS-specific guide with:
  - Quick start instructions
  - Parameter management explanation
  - Recommended workflow
  - All available options

## Testing Considerations

The module has been tested with:

- ✅ Kernel module compilation and loading
- ✅ Parameter application and persistence
- ✅ CLI tool functionality when enabled
- ✅ Proper permissions and group setup
- ✅ All acceleration modes (linear, natural, synchronous, no_accel)

## Impact

This addition makes maccel accessible to the growing NixOS community while maintaining the same powerful functionality users expect. The declarative approach aligns perfectly with NixOS philosophy and provides a superior user experience compared to imperative installation methods.

## Related

- Closes potential NixOS user requests
- Enables inclusion in NixOS package collections
- Positions maccel as the most complete mouse acceleration solution for Linux

---

**Ready for the NixOS community! 🚀**
