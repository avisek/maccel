#!/usr/bin/env bash

# Migration script: CLI-based → Direct parameters approach
# This script helps migrate from the old CLI-based approach to the new direct approach

set -e

echo "🔄 maccel NixOS Migration: CLI-based → Direct Parameters"
echo ""

# Check if we're in the right directory
if [ ! -f "maccel-nixos-direct.nix" ]; then
    echo "❌ Error: maccel-nixos-direct.nix not found in current directory"
    echo "   Please run this script from the directory containing the maccel NixOS files"
    exit 1
fi

# Backup existing files
echo "📦 Creating backups..."
if [ -f "maccel-nixos-module.nix" ]; then
    cp maccel-nixos-module.nix maccel-nixos-module-CLI-BACKUP.nix
    echo "   ✅ Backed up CLI-based module to: maccel-nixos-module-CLI-BACKUP.nix"
fi

if [ -f "maccel-configuration-example.nix" ]; then
    cp maccel-configuration-example.nix maccel-configuration-example-CLI-BACKUP.nix
    echo "   ✅ Backed up CLI example to: maccel-configuration-example-CLI-BACKUP.nix"
fi

# Update main module file
echo ""
echo "🔄 Migrating to direct parameters approach..."
cp maccel-nixos-direct.nix maccel-nixos-module.nix
echo "   ✅ Updated maccel-nixos-module.nix with direct approach"

# Update example configuration
cat > maccel-configuration-example.nix << 'EOF'
# Example NixOS configuration using the DIRECT maccel module
# This approach bypasses the CLI and sets parameters directly - faster and more reliable!

{ config, pkgs, lib, ... }:

{
  # Import the direct module
  imports = [
    ./maccel-nixos-module.nix
    # ... your other imports
  ];

  # Enable maccel with direct parameter setting
  hardware.maccel = {
    enable = true;
    
    # Optional: Enable debug info (shows applied parameters)
    debug = false;
    
    # Optional: Build CLI tools (not needed for basic functionality)
    buildTools = false;  # Set to true if you want `maccel` CLI for manual tweaking
    
    # Set parameters directly - converted to fixed-point integers at build time
    parameters = {
      sensMultiplier = 1.0;     # Base sensitivity (1.0 = no change)
      acceleration = 0.3;       # Linear acceleration factor  
      offset = 2.0;            # Start accelerating above this speed
      outputCap = 2.0;         # Maximum sensitivity multiplier
      mode = "linear";         # Acceleration curve: "linear", "natural", "synchronous", "no_accel"
    };
  };
  
  # Optional: Add your user to maccel group (only needed if buildTools = true)
  users.users.yourusername.extraGroups = [ "maccel" ];
  
  # That's it! Much cleaner than the old CLI-based approach:
  # ✅ No systemd services needed
  # ✅ No CLI dependency 
  # ✅ Faster boot
  # ✅ More reliable
  # ✅ Parameters applied during module load
}
EOF

echo "   ✅ Updated example configuration"

echo ""
echo "🎉 Migration complete!"
echo ""
echo "What changed:"
echo "  📁 maccel-nixos-module.nix → Now uses direct parameter approach"
echo "  📁 maccel-configuration-example.nix → Updated example"
echo "  📁 *-CLI-BACKUP.nix → Your old files (safe to delete later)"
echo ""
echo "Benefits of the new approach:"
echo "  ✅ No CLI dependency - works even if CLI build fails"
echo "  ✅ Faster boot - no systemd services to wait for"
echo "  ✅ More reliable - fewer moving parts"
echo "  ✅ Cleaner - no temporary script files"
echo "  ✅ Traditional Linux - uses kernel module parameters"
echo ""
echo "Your configuration syntax stays exactly the same!"
echo "Just rebuild your system:"
echo ""
echo "  sudo nixos-rebuild switch"
echo ""
echo "Optional: Enable CLI tools later by adding:"
echo ""
echo "  hardware.maccel.buildTools = true;"
echo ""
echo "📚 Read DIRECT-APPROACH-GUIDE.md for complete details"
echo "📚 Read APPROACHES-COMPARISON.md for comparison with other methods"
