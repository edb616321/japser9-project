# Unity Development Environment Setup Guide

## System Specifications
- **OS**: Windows 11 Pro
- **Hardware**: Dual NVIDIA RTX 4090 GPUs
- **Host**: 10.0.0.205 (AI Server)

## Installation Steps
1. Install Windows 11 Pro with latest updates
2. Install Unity Hub and Unity Editor 2022.3 LTS
3. Configure GPU settings for optimal performance
4. Set up remote access protocols

## Remote Access Configuration

### RDP Access
- Configure RDP with Network Level Authentication
- Set up proper firewall rules to only allow trusted IPs
- Configure RDP to use all displays

### PowerShell Remoting
- Enable PowerShell Remoting for automation
- Create secure endpoint configuration
- Set up proper authentication

## Unity Configuration for Dual RTX 4090s

### GPU Optimization
1. In Unity Editor, go to Edit > Project Settings > Player
2. Under "Other Settings", ensure DirectX12 is selected
3. Enable GPU lightmapping in Lighting settings
4. Configure NVIDIA Control Panel for optimal performance:
   - Set Power Management Mode to "Prefer Maximum Performance"
   - Set Threaded Optimization to "On"
   - Set Virtual Reality pre-rendered frames to "1"

### Project Structure Best Practices
- Organize assets in logical folders
- Set up proper Git integration with LFS
- Configure appropriate .gitignore for Unity projects

## Automation Scripts

The `tools/vm-management` directory contains scripts for managing the VM environment. These will need to be adapted for Windows PowerShell commands when transitioning to Windows 11.

## Integration with Existing Systems

### Nginx Configuration
- All services should be routed through the central Nginx server (10.0.0.228)
- Configure appropriate SSL certificates
- Set up proper reverse proxy rules
