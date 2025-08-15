#!/usr/bin/env bash

# Script to update the SHA256 hashes in the maccel NixOS module
# This script fetches the latest version and updates the placeholder hashes

set -e

MACCEL_VERSION="0.5.6"
MODULE_FILE="maccel-nixos-module.nix"
FLAKE_FILE="flake.nix"

echo "🔍 Fetching SHA256 hash for maccel source..."

# Get the source hash using nix-prefetch-git
if command -v nix-prefetch-git >/dev/null; then
    echo "Using nix-prefetch-git..."
    SOURCE_HASH=$(nix-prefetch-git https://github.com/Gnarus-G/maccel.git --rev "v${MACCEL_VERSION}" --quiet | jq -r '.sha256')
else
    # Fallback to nix-prefetch-url
    echo "Using nix-prefetch-url..."
    TARBALL_URL="https://github.com/Gnarus-G/maccel/archive/v${MACCEL_VERSION}.tar.gz"
    SOURCE_HASH=$(nix-prefetch-url --unpack "$TARBALL_URL")
fi

echo "📝 Source hash: sha256-$SOURCE_HASH"

# Update the module file
if [ -f "$MODULE_FILE" ]; then
    echo "🔧 Updating hashes in $MODULE_FILE..."
    
    # Replace the source hash
    sed -i "s/sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=/sha256-$SOURCE_HASH/g" "$MODULE_FILE"
    
    echo "✅ Updated $MODULE_FILE"
else
    echo "❌ Module file $MODULE_FILE not found"
fi

# Update the flake file
if [ -f "$FLAKE_FILE" ]; then
    echo "🔧 Updating hashes in $FLAKE_FILE..."
    
    # Replace the source hash
    sed -i "s/sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=/sha256-$SOURCE_HASH/g" "$FLAKE_FILE"
    
    echo "✅ Updated $FLAKE_FILE"
else
    echo "❌ Flake file $FLAKE_FILE not found"
fi

echo ""
echo "⚠️  NOTE: The Cargo hash (sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=) still needs to be updated."
echo "   To get the correct Cargo hash:"
echo "   1. Try building the package with: nix-build -A maccel-tools"
echo "   2. The build will fail and show the correct hash in the error message"
echo "   3. Replace 'sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=' with the correct hash"
echo ""
echo "✨ Hash update complete! You may need to manually update the Cargo hash after first build."

# Optionally try to get the cargo hash by attempting to build
echo ""
echo "🚀 Attempting to determine Cargo hash by building..."

# Create a temporary test file to build just the Rust package
cat > test-cargo-hash.nix << 'EOF'
{ pkgs ? import <nixpkgs> {} }:

pkgs.rustPlatform.buildRustPackage rec {
  pname = "maccel-tools";
  version = "0.5.6";
  
  src = pkgs.fetchFromGitHub {
    owner = "Gnarus-G";
    repo = "maccel";
    rev = "v${version}";
    sha256 = "REPLACE_WITH_SOURCE_HASH";
  };
  
  cargoHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  cargoBuildFlags = [ "--bin" "maccel" ];
}
EOF

# Replace the source hash in the test file
sed -i "s/REPLACE_WITH_SOURCE_HASH/sha256-$SOURCE_HASH/g" test-cargo-hash.nix

echo "🔨 Attempting to build to get Cargo hash..."
if nix-build test-cargo-hash.nix 2>&1 | tee build-output.log; then
    echo "✅ Build succeeded!"
else
    # Extract the expected hash from the error message
    if grep -q "got:" build-output.log; then
        CORRECT_CARGO_HASH=$(grep "got:" build-output.log | grep -o "sha256-[A-Za-z0-9+/=]*" | head -1)
        if [ ! -z "$CORRECT_CARGO_HASH" ]; then
            echo "🎯 Found correct Cargo hash: $CORRECT_CARGO_HASH"
            
            # Update both files with the correct cargo hash
            if [ -f "$MODULE_FILE" ]; then
                sed -i "s/sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=/$CORRECT_CARGO_HASH/g" "$MODULE_FILE"
                echo "✅ Updated Cargo hash in $MODULE_FILE"
            fi
            
            if [ -f "$FLAKE_FILE" ]; then
                sed -i "s/sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=/$CORRECT_CARGO_HASH/g" "$FLAKE_FILE"
                echo "✅ Updated Cargo hash in $FLAKE_FILE"
            fi
            
            echo ""
            echo "🎉 All hashes updated successfully!"
        else
            echo "❌ Could not extract Cargo hash from build output"
        fi
    else
        echo "❌ Build failed but could not find hash in output"
    fi
fi

# Clean up temporary files
rm -f test-cargo-hash.nix build-output.log result

echo ""
echo "🏁 Script complete. Your maccel NixOS module should now have correct hashes!"
