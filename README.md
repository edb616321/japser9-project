# Jasper9 Project Repository

This repository contains documentation, tools, and implementation details for the Jasper9 project, including Unity game development components and integrations with AI systems.

## Repository Structure

```
jasper9-project/
├── docs/                   # Documentation
│   ├── diagrams/          # Architecture and component diagrams
│   ├── setup-guides/      # Setup and installation guides
│   └── api-specs/         # API specifications
├── tools/                 # Development and management tools
│   ├── diagram-editor/    # Mermaid-based diagram editor
│   ├── vm-management/     # VM management scripts
│   └── automation/        # Automation scripts
├── implementation/        # Implementation code
│   ├── chat/              # Chat system implementation
│   ├── chat-ui/           # Chat UI components
│   └── ai-agent/          # AI agent workflows
├── workflows/             # Workflow definitions
│   ├── n8n/               # n8n workflow files
│   └── agent/             # Agent workflow definitions
└── memories/              # System configuration memories
```

## Key Components

### Jasper9 Architecture
The Jasper9 project consists of a React TypeScript frontend integrated with Unity WebGL, connecting to Supabase for data storage and the Convai AI Engine for AI interactions.

### Unity Development
The project includes Unity game development with WebGL export for web integration. Development is performed on a Windows 11 Pro environment with dual NVIDIA RTX 4090 GPUs.

### Infrastructure
The project utilizes:
- AI Server (10.0.0.205) - Running Ollama and various services
- NGINX Reverse Proxy (10.0.0.228) - Central routing for all services

## Documentation

Refer to the `docs/` directory for detailed documentation on:
- System architecture and component relationships
- Setup guides for development environments
- API specifications for integration points

## Getting Started

1. Review the architecture diagrams in `docs/diagrams/`
2. Follow the Unity setup guide in `docs/setup-guides/unity-setup.md`
3. Explore the implementation details in the respective directories
