# Example NixOS configuration using the maccel module
# Save this as configuration.nix or import it into your existing configuration

{ config, pkgs, lib, ... }:

{
  # Import the maccel module
  # Choose one of these:
  imports = [
    ./maccel-nixos-module.nix           # Full module with hashes (production)
    # ./maccel-nixos-module-no-hashes.nix  # Development module without hashes
    # ... your other imports
  ];

  # Enable maccel with custom configuration
  hardware.maccel = {
    enable = true;
    
    # Optional: Enable debug build (useful for troubleshooting)
    debug = false;
    
    # Optional: Auto-load the kernel module at boot (default: true)
    autoload = true;
    
    # Optional: Set default parameters
    parameters = {
      sensMultiplier = 1.0;     # Default sensitivity multiplier
      acceleration = 0.3;       # Linear acceleration factor
      offset = 2.0;            # Input offset
      outputCap = 2.0;         # Maximum output multiplier
      mode = "linear";         # Acceleration mode: "linear", "natural", or "synchronous"
    };
  };
  
  # Optional: Add your user to the maccel group to use the CLI without sudo
  users.users.yourusername = {
    extraGroups = [ "maccel" ];
    # ... other user configuration
  };
  
  # Alternative: Add all users in the "wheel" group to the maccel group
  # users.users = lib.mapAttrs (name: user: 
  #   if lib.elem "wheel" user.extraGroups 
  #   then user // { extraGroups = user.extraGroups ++ [ "maccel" ]; }
  #   else user
  # ) config.users.users;
  
  # The module automatically handles:
  # - Building and installing the kernel module
  # - Installing the CLI and TUI tools
  # - Setting up udev rules for permissions
  # - Creating the maccel group
  # - Persisting parameters across reboots
  # - Loading the module at boot
}
