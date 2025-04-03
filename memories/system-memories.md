# Jasper9 System Memories

## NGINX Configuration
- Nginx Server: 10.0.0.228
- User: eddyb
- Password: eddyb
- All services should be routed through this central reverse proxy

### Standard Domain Setup Process
1. Create Nginx Configuration on the central server
2. Generate SSL Certificate using Let's Encrypt
3. Apply Configuration and reload Nginx

### Security Best Practices
- Always use SSL (Let's Encrypt)
- Always include security headers
- Always force HTTPS redirect
- Always set proper timeouts
- Never expose internal ports directly
- Always use upstream blocks for services

## AI Server Configuration
- Server: 10.0.0.205
- Dual NVIDIA RTX 4090 GPUs (24GB VRAM each)
- Running Ollama (version 0.4.7) with multiple LLM models
- Docker containers:
  - Open WebUI (port 3100)
  - Flask Application (port 5001)
  - Flask Tailwind Application (port 5003)
  - Portainer (ports 8000, 9443)
  - Calendar App (port 8001)
  - Apache Tika (port 9998)
- Will be converted to Windows 11 Pro for Unity development

## Unity Development Environment
- Windows 11 Pro with dual GPU support
- Remote access via RDP and PowerShell
- Integration with existing systems via APIs
- GPU-accelerated rendering and lightmapping
- Proper project structure with version control integration
