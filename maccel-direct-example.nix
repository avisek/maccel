# Example configuration using the DIRECT parameter approach (NO CLI needed!)
# This bypasses the maccel CLI entirely - cleaner, faster, and more reliable

{ config, pkgs, lib, ... }:

{
  # Import the direct module
  imports = [
    ./maccel-nixos-direct.nix
    # ... your other imports
  ];

  # Enable maccel with direct parameter setting
  hardware.maccel = {
    enable = true;
    
    # Optional: Enable debug info service
    debug = false;
    
    # Optional: Build CLI tools (not needed for basic functionality)
    buildTools = false;  # Set to true if you want maccel CLI for manual tweaking
    
    # Set parameters directly - these are converted to fixed-point and applied at boot
    parameters = {
      # Common parameters (apply to all modes)
      sensMultiplier = 1.0;     # Base sensitivity multiplier (1.0 = no change)
      yxRatio = 1.0;           # Y/X sensitivity ratio (1.0 = equal, >1.0 = higher Y sensitivity)
      inputDpi = 1000.0;       # Mouse DPI for normalization (default: 1000.0)
      angleRotation = 0.0;     # Rotation angle in degrees (0.0 = no rotation)
      mode = "linear";         # Acceleration curve: "linear", "natural", "synchronous", "no_accel"
      
      # Linear mode parameters (only used when mode = "linear")
      acceleration = 0.3;      # Linear acceleration factor (0.0 = no acceleration)
      offset = 2.0;           # Start accelerating above this input speed
      outputCap = 2.0;        # Maximum sensitivity multiplier cap
      
      # Natural mode parameters (only used when mode = "natural")
      # decayRate = 0.1;        # Decay rate of the natural curve (default: 0.1)
      # limit = 1.5;            # Limit of the natural curve (default: 1.5)
      
      # Synchronous mode parameters (only used when mode = "synchronous")
      # gamma = 1.0;            # Controls transition speed around midpoint (default: 1.0)
      # smooth = 0.5;           # Controls suddenness of sensitivity increase (default: 0.5)
      # motivity = 1.5;         # Sets max sens, min = 1/motivity (default: 1.5)
      # syncSpeed = 5.0;        # Middle sensitivity between min and max (default: 5.0)
    };
  };
  
  # Optional: Add your user to maccel group (only needed if buildTools = true)
  users.users.yourusername.extraGroups = [ "maccel" ];
  
  # That's it! No systemd services, no CLI calls, no boot scripts.
  # Parameters are applied directly when the kernel module loads.
}

# == What this approach does differently ==
#
# OLD WAY (CLI-based):
# 1. Boot → Load kernel module with defaults
# 2. systemd service starts
# 3. Service calls `maccel set param sens-mult 1.0`
# 4. CLI converts 1.0 → 4294967296 (fixed-point)
# 5. CLI writes "4294967296" to /sys/module/maccel/parameters/SENS_MULT
# 6. Creates reset script for persistence
#
# NEW WAY (Direct):
# 1. NixOS converts 1.0 → 4294967296 at build time
# 2. Boot → Load kernel module with: `modprobe maccel SENS_MULT=4294967296`
# 3. Done! No services, no CLI calls, no reset scripts.
#
# == Benefits ==
# ✅ Faster boot (no systemd services to wait for)
# ✅ More reliable (no CLI dependency)
# ✅ Cleaner (no temporary script files)
# ✅ Atomic (parameters set during module load)
# ✅ Simpler (fewer moving parts)
# ✅ Traditional Linux approach (kernel module parameters)
