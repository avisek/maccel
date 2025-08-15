# maccel NixOS Implementation Checklist

This checklist ensures all components are properly implemented and configured for maccel on NixOS.

## 📋 Pre-Implementation Requirements

- [ ] NixOS system with appropriate kernel headers
- [ ] Nix flakes enabled (for flake-based installation)
- [ ] Git and basic build tools available
- [ ] Understanding of your desired maccel configuration

## 🏗️ Core Implementation Steps

### 1. Module Files Setup

- [ ] Download/create `maccel-nixos-module.nix`
- [ ] Download/create example configuration file
- [ ] Set up flake.nix (if using flakes)
- [ ] Ensure all files are in correct locations

### 2. Hash Updates

- [ ] Run `./update-hashes.sh` to get correct source hashes
- [ ] Manually verify and update any remaining placeholder hashes
- [ ] Test that source can be fetched: `nix-prefetch-git https://github.com/Gnarus-G/maccel.git --rev v0.5.6`

### 3. Build Testing

- [ ] Test kernel module build: `nix-build -A maccel-kernel-module`
- [ ] Test CLI tools build: `nix-build -A maccel-tools`
- [ ] Verify no build errors or missing dependencies

## ⚙️ System Integration

### 4. Configuration

- [ ] Add module import to your `configuration.nix`
- [ ] Enable maccel: `hardware.maccel.enable = true`
- [ ] Configure desired parameters in `hardware.maccel.parameters`
- [ ] Add users to maccel group for CLI access

### 5. Deployment

- [ ] Run `sudo nixos-rebuild switch`
- [ ] Check for any build or activation errors
- [ ] Verify system rebuilds successfully

## ✅ Verification Steps

### 6. Kernel Module Verification

- [ ] Module loaded: `lsmod | grep maccel`
- [ ] Module parameters accessible: `ls /sys/module/maccel/parameters/`
- [ ] No kernel errors: `dmesg | grep maccel` (should show successful loading)

### 7. Tools Verification

- [ ] CLI available: `which maccel`
- [ ] CLI functional: `maccel --version`
- [ ] CLI can read params: `maccel get param sens-mult`
- [ ] TUI launches: `maccel tui` (should open without errors)

### 8. Permissions Verification

- [ ] maccel group exists: `getent group maccel`
- [ ] User in maccel group: `groups` (should show maccel)
- [ ] CLI works without sudo: `maccel get param sens-mult` (as regular user)
- [ ] Device permissions correct: `ls -la /dev/maccel`

### 9. Persistence Verification

- [ ] Reset scripts directory exists: `ls -la /var/lib/maccel/resets/`
- [ ] Udev rules installed: `ls /etc/udev/rules.d/*maccel*`
- [ ] Parameters persist after reboot (test by rebooting and checking values)

## 🔧 Functional Testing

### 10. Parameter Management

- [ ] Can set parameters: `maccel set param sens-mult 1.5`
- [ ] Can read parameters: `maccel get param sens-mult`
- [ ] Default parameters applied correctly at boot
- [ ] Parameter changes take effect immediately

### 11. Mode Testing

- [ ] Can change modes: `maccel set mode linear`
- [ ] Mode persists across reboots
- [ ] Different modes work correctly (linear, natural, synchronous)

### 12. Advanced Features

- [ ] Debug mode works (if enabled): Check for debug output in `dmesg`
- [ ] TUI interface functions properly
- [ ] Parameter validation works (try invalid values)

## 🐛 Troubleshooting Checklist

### 13. Common Issues

- [ ] **Module won't load**: Check kernel compatibility, build logs
- [ ] **Permission denied**: Verify group membership, udev rules
- [ ] **Build failures**: Check hashes, dependencies, kernel headers
- [ ] **Parameters don't persist**: Check udev scripts, directory permissions
- [ ] **CLI not found**: Check system packages, PATH

### 14. Debug Steps

- [ ] Enable debug mode: `hardware.maccel.debug = true`
- [ ] Check systemd service status: `systemctl status maccel-set-defaults`
- [ ] Review logs: `journalctl -u maccel-set-defaults`
- [ ] Verify module info: `modinfo maccel`

## 📝 Documentation Verification

### 15. Documentation

- [ ] README instructions are clear and accurate
- [ ] Example configurations work as documented
- [ ] All configuration options are documented
- [ ] Troubleshooting guide is complete

## 🚀 Production Readiness

### 16. Final Validation

- [ ] System stable after implementation
- [ ] No impact on other system functionality
- [ ] Mouse acceleration works as expected
- [ ] Configuration survives system updates
- [ ] Backup/restore procedures documented

## 📊 Performance Testing

### 17. Optional Performance Checks

- [ ] Test mouse responsiveness at different settings
- [ ] Verify no input lag introduced
- [ ] Test with different acceleration modes
- [ ] Validate parameter ranges and limits

## 🔒 Security Review

### 18. Security Considerations

- [ ] Only necessary users have maccel group access
- [ ] No unnecessary permissions granted
- [ ] Kernel module properly signed/validated
- [ ] No exposure of sensitive system interfaces

---

## ✅ Sign-off

Once all items are checked, your maccel NixOS implementation should be:

- ✅ **Fully functional**
- ✅ **Properly integrated**
- ✅ **Persistent across reboots**
- ✅ **Securely configured**
- ✅ **Ready for production use**

### Final Test Sequence:

1. Reboot the system
2. Verify module loads automatically
3. Check that parameters are restored
4. Test CLI functionality as regular user
5. Confirm mouse acceleration is working
6. Document your final configuration

**Implementation Date**: ******\_\_\_\_******  
**Tested By**: ******\_\_\_\_******  
**System**: ******\_\_\_\_******  
**Kernel Version**: ******\_\_\_\_******
