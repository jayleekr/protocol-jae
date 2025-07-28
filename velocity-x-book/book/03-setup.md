---
title: Environment Setup and Configuration
chapter: 3
author: VELOCITY-X Team
date: 2025-07-27
reading_time: 25 minutes
---

# Environment Setup and Configuration

> *"A good workman is known by his tools."* - Proverb  
> *"But the best workman creates tools that work for everyone."* - VELOCITY-X Team

## Overview

Getting VELOCITY-X up and running in your development environment is straightforward, but proper setup ensures optimal performance and reliability. This chapter provides comprehensive guidance for installing, configuring, and optimizing VELOCITY-X across different platforms and development scenarios.

By the end of this chapter, you'll have:
- A fully functional VELOCITY-X installation
- Optimized configuration for your development environment
- Understanding of advanced configuration options
- Knowledge of troubleshooting common setup issues

## 1. System Requirements

### Minimum Requirements
- **Operating System**: macOS 10.15+, Ubuntu 18.04+, Windows 10+ (with WSL2)
- **Memory**: 4GB RAM (8GB recommended)
- **Storage**: 2GB free space
- **Network**: Internet connection for initial setup and updates

### Recommended Requirements
- **Operating System**: macOS 12+, Ubuntu 20.04+, Windows 11 with WSL2
- **Memory**: 16GB RAM
- **Storage**: 10GB free space (for caching and temporary files)
- **CPU**: Multi-core processor (4+ cores recommended)

### Software Dependencies
- **Git**: Version 2.25 or later
- **Python**: 3.8 or later (3.11+ recommended)
- **Node.js**: 16.0 or later (for PDF generation)
- **Bash**: 4.0 or later

## 2. Installation

### Quick Start Installation

The fastest way to get started with VELOCITY-X:

```bash
# Clone the VELOCITY-X repository
git clone https://github.com/jayleekr/velocity-x.git
cd velocity-x

# Run the installation script
./scripts/install.sh

# Verify installation
./temp_hooks/commands/scripts/run-workflow.sh --version
```

### Manual Installation

For more control over the installation process:

#### Step 1: Clone and Setup
```bash
# Clone the repository
git clone https://github.com/jayleekr/velocity-x.git
cd velocity-x

# Create virtual environment (recommended)
python3 -m venv velocity-x-env
source velocity-x-env/bin/activate  # On Windows: velocity-x-env\Scripts\activate

# Install Python dependencies
pip install -r requirements.txt
```

#### Step 2: Install System Tools
```bash
# On macOS (using Homebrew)
brew install ruff pylint black radon bandit

# On Ubuntu/Debian
sudo apt update
sudo apt install python3-pip
pip3 install ruff pylint black radon bandit

# On Windows (using pip)
pip install ruff pylint black radon bandit
```

#### Step 3: Configure Permissions
```bash
# Make agent scripts executable
find temp_hooks/commands -name "*.sh" -exec chmod +x {} \;

# Verify permissions
ls -la temp_hooks/commands/agents/*/run.sh
```

#### Step 4: Install Node.js Dependencies (Optional)
```bash
# For advanced book generation features
cd velocity-x-book
npm install

# Test PDF generation capability
npm test
```

### Docker Installation

For containerized environments:

```bash
# Build the VELOCITY-X Docker image
docker build -t velocity-x:latest .

# Run VELOCITY-X in container
docker run -it --rm \
  -v $(pwd):/workspace \
  -w /workspace \
  velocity-x:latest \
  ./temp_hooks/commands/agents/velocity-x-polish-specialist/run.sh --help
```

### Development Installation

For contributors and advanced users:

```bash
# Clone with development dependencies
git clone --recurse-submodules https://github.com/jayleekr/velocity-x.git
cd velocity-x

# Install development dependencies
pip install -r requirements-dev.txt

# Install pre-commit hooks
pre-commit install

# Run development setup
make dev-setup

# Run tests to verify installation
make test
```

## 3. Configuration

### Basic Configuration

VELOCITY-X uses YAML configuration files located in `temp_hooks/commands/config/`:

#### Agent Configuration (`config/agents.yaml`)
```yaml
# Core agent settings
agents:
  velocity-x-polish-specialist:
    enabled: true
    timeout: 450
    memory_limit: "2Gi"
    cpu_limit: 1.0
    required_tools:
      - ruff
      - pylint
      - black
      - radon
    
  velocity-x-code-reviewer:
    enabled: true
    timeout: 600
    parallel_execution: true
    review_depth: "thorough"  # minimal, standard, thorough
```

#### Tool Configuration (`config/tools.yaml`)
```yaml
tools:
  ruff:
    enabled: true
    config_file: ".ruff.toml"
    severity_threshold: "error"
    
  pylint:
    enabled: true
    config_file: "pylintrc"
    score_threshold: 8.0
    
  black:
    enabled: true
    line_length: 88
    target_version: ["py38", "py39", "py310", "py311"]
    
  radon:
    enabled: true
    complexity_threshold: 10
    maintainability_threshold: "B"
```

#### Workflow Configuration (`config/workflows.yaml`)
```yaml
workflows:
  quality-trio:
    name: "Quality Trio Workflow"
    agents: 
      - velocity-x-polish-specialist
      - velocity-x-code-reviewer
    parallel_capable: false
    timeout: 1200
    
  security-focused:
    name: "Security-Focused Review"
    agents:
      - velocity-x-polish-specialist
      - velocity-x-security-guardian
      - velocity-x-code-reviewer
    parallel_capable: true
    timeout: 1800
```

### Advanced Configuration

#### Environment Variables
Create a `.env` file in the project root:

```bash
# VELOCITY-X Configuration
VELOCITY-X_LOG_LEVEL=INFO
VELOCITY-X_CACHE_DIR=/tmp/velocity-x-cache
VELOCITY-X_MAX_WORKERS=4
VELOCITY-X_TIMEOUT_DEFAULT=600

# Tool Configurations
RUFF_CACHE_DIR=/tmp/ruff-cache
PYLINT_JOBS=0  # Use all available cores
BLACK_CACHE_DIR=/tmp/black-cache

# Optional: AI Service Integration
OPENAI_API_KEY=your_api_key_here
ANTHROPIC_API_KEY=your_api_key_here

# Performance Tuning
VELOCITY-X_ENABLE_CACHING=true
VELOCITY-X_CACHE_TTL=3600
VELOCITY-X_MEMORY_LIMIT=8Gi
```

#### Global Configuration (`~/.velocity-x/config.yaml`)
```yaml
# Global VELOCITY-X settings
global:
  default_workspace: "~/workspace"
  cache_directory: "~/.velocity-x/cache"
  log_directory: "~/.velocity-x/logs"
  max_log_files: 10
  
preferences:
  default_workflow: "quality-trio"
  auto_update: true
  telemetry_enabled: false
  
integrations:
  github:
    enabled: true
    token_file: "~/.velocity-x/github-token"
  
  slack:
    enabled: false
    webhook_url: ""
```

### IDE Integration

#### VS Code Integration
Create `.vscode/settings.json`:

```json
{
  "velocity-x.enabled": true,
  "velocity-x.autoRunOnSave": true,
  "velocity-x.defaultWorkflow": "quality-trio",
  "velocity-x.showNotifications": true,
  "python.linting.enabled": true,
  "python.linting.pylintEnabled": true,
  "python.formatting.provider": "black",
  "files.associations": {
    "*.velocity-x.yaml": "yaml"
  }
}
```

Install the VELOCITY-X VS Code extension:
```bash
code --install-extension velocity-x-team.velocity-x-vscode
```

#### Vim Integration
Add to your `.vimrc`:

```vim
" VELOCITY-X Integration
autocmd BufWritePost *.py :call VELOCITY-XAutoRun()

function! VELOCITY-XAutoRun()
  if exists("g:velocity_x_auto_run") && g:velocity_x_auto_run
    silent execute "!./temp_hooks/commands/agents/velocity-x-polish-specialist/run.sh % &"
  endif
endfunction

" Enable VELOCITY-X auto-run
let g:velocity_x_auto_run = 1
```

#### JetBrains IDEs
Configure external tools in PyCharm/IntelliJ:

1. Go to **Settings** → **Tools** → **External Tools**
2. Add new tool:
   - **Name**: VELOCITY-X Polish Specialist
   - **Program**: `$ProjectFileDir$/temp_hooks/commands/agents/velocity-x-polish-specialist/run.sh`
   - **Arguments**: `$FilePath$`
   - **Working Directory**: `$ProjectFileDir$`

## 4. First Run and Verification

### Basic Functionality Test

```bash
# Test individual agent
./temp_hooks/commands/agents/velocity-x-polish-specialist/run.sh --help

# Create a test file
cat > test_example.py << EOF
def bad_function(x,y):
    if x>y:
        return x+y
    else:
        return x-y

class MyClass:
    def __init__(self,value):
        self.value=value
EOF

# Run Polish Specialist
./temp_hooks/commands/agents/velocity-x-polish-specialist/run.sh test_example.py

# Verify output
ls -la velocity-x-output/velocity-x-polish-specialist_*/
```

### Quality Trio Workflow Test

```bash
# Run the full Quality Trio workflow
./temp_hooks/commands/scripts/run-quality-trio.sh test_example.py

# Check comprehensive results
cat velocity-x-output/workflow_*/workflow_report.json
```

Expected output structure:
```json
{
  "workflow": "quality-trio",
  "status": "completed",
  "overall_score": 85.2,
  "agents_executed": ["velocity-x-polish-specialist", "velocity-x-code-reviewer"],
  "execution_time": "45.3s",
  "improvements": {
    "code_quality": "+23%",
    "maintainability": "+18%",
    "security_score": "A+"
  }
}
```

### Performance Benchmark

```bash
# Run performance benchmark
./scripts/benchmark.sh

# Expected results:
# Agent initialization: < 2s
# Polish Specialist execution: < 30s for 1000 lines
# Code Reviewer execution: < 45s for 1000 lines
# Memory usage: < 512MB per agent
```

## 5. Troubleshooting

### Common Issues and Solutions

#### Issue: Permission Denied
```bash
# Error: Permission denied when running agents
# Solution: Fix permissions
find temp_hooks/commands -name "*.sh" -exec chmod +x {} \;
```

#### Issue: Python Module Not Found
```bash
# Error: ModuleNotFoundError: No module named 'yaml'
# Solution: Install dependencies
pip install pyyaml
# Or use fallback mode
export VELOCITY-X_USE_FALLBACK_PARSER=true
```

#### Issue: Tool Not Found
```bash
# Error: ruff: command not found
# Solution: Install tools via pip
pip install ruff pylint black radon bandit

# Or via system package manager
# macOS: brew install ruff
# Ubuntu: apt install python3-ruff
```

#### Issue: Timeout Errors
```bash
# Error: Agent execution timeout
# Solution: Increase timeout in config
# Edit temp_hooks/commands/config/agents.yaml
timeout: 900  # Increase from default 450
```

#### Issue: Memory Issues
```bash
# Error: Out of memory during execution
# Solution: Limit concurrent agents
export VELOCITY-X_MAX_WORKERS=2

# Or increase system limits
ulimit -m 8388608  # 8GB memory limit
```

### Diagnostic Commands

```bash
# Check system requirements
./scripts/check-requirements.sh

# Validate configuration
./scripts/validate-config.sh

# Test all agents
./scripts/test-agents.sh

# Generate diagnostic report
./scripts/diagnostic-report.sh > velocity-x-diagnostic.txt
```

### Log Analysis

```bash
# View recent logs
tail -f ~/.velocity-x/logs/velocity-x.log

# Search for errors
grep -i error ~/.velocity-x/logs/velocity-x.log

# Agent-specific logs
ls -la velocity-x-output/*/logs/
```

## 6. Performance Optimization

### Caching Configuration

```bash
# Enable persistent caching
export VELOCITY-X_ENABLE_CACHING=true
export VELOCITY-X_CACHE_DIR=/opt/velocity-x-cache

# Set cache size limits
export VELOCITY-X_CACHE_MAX_SIZE=2GB
export VELOCITY-X_CACHE_TTL=86400  # 24 hours
```

### Parallel Execution

```yaml
# config/performance.yaml
performance:
  max_workers: 4
  enable_parallel: true
  memory_per_worker: "2Gi"
  
  agent_specific:
    velocity-x-polish-specialist:
      workers: 2
      memory: "1Gi"
    velocity-x-code-reviewer:
      workers: 2 
      memory: "3Gi"
```

### Resource Monitoring

```bash
# Monitor resource usage
./scripts/monitor-resources.sh

# Output shows:
# Agent: velocity-x-polish-specialist
# CPU: 45%
# Memory: 1.2GB/2GB
# Execution time: 23.4s
```

## 7. Security Configuration

### Access Control

```yaml
# config/security.yaml
security:
  file_access:
    allowed_extensions: [".py", ".js", ".ts", ".java"]
    max_file_size: "10MB"
    blocked_paths: ["/etc/", "/usr/bin/"]
    
  network:
    allow_internet: false
    allowed_hosts: ["api.github.com"]
    
  execution:
    sandbox_mode: true
    user_isolation: true
    resource_limits: true
```

### Secrets Management

```bash
# Store API keys securely
echo "your_api_key" | ./scripts/store-secret.sh openai_api_key

# Use secrets in configuration
# config/integrations.yaml
ai_services:
  openai:
    api_key_from_secret: "openai_api_key"
```

## 8. Advanced Setup Scenarios

### CI/CD Integration

#### GitHub Actions
```yaml
# .github/workflows/velocity-x-quality.yml
name: VELOCITY-X Quality Check
on: [push, pull_request]

jobs:
  quality-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup VELOCITY-X
        run: |
          ./scripts/install.sh
          
      - name: Run Quality Trio
        run: |
          ./temp_hooks/commands/scripts/run-quality-trio.sh src/
          
      - name: Upload Results
        uses: actions/upload-artifact@v3
        with:
          name: velocity-x-results
          path: velocity-x-output/
```

#### Jenkins Pipeline
```groovy
pipeline {
    agent any
    
    stages {
        stage('Setup VELOCITY-X') {
            steps {
                sh './scripts/install.sh'
            }
        }
        
        stage('Quality Analysis') {
            steps {
                sh './temp_hooks/commands/scripts/run-quality-trio.sh src/'
                
                publishHTML([
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: 'velocity-x-output',
                    reportFiles: 'workflow_*/workflow_report.html',
                    reportName: 'VELOCITY-X Quality Report'
                ])
            }
        }
    }
}
```

### Enterprise Deployment

#### Docker Compose
```yaml
# docker-compose.yml
version: '3.8'

services:
  velocity-x-coordinator:
    image: velocity-x:latest
    environment:
      - VELOCITY-X_MODE=coordinator
      - VELOCITY-X_WORKERS=4
    volumes:
      - ./workspace:/workspace
      - velocity-x-cache:/cache
    
  velocity-x-worker:
    image: velocity-x:latest
    environment:
      - VELOCITY-X_MODE=worker
      - VELOCITY-X_COORDINATOR_URL=http://velocity-x-coordinator:8080
    volumes:
      - ./workspace:/workspace
    scale: 4

volumes:
  velocity-x-cache:
```

#### Kubernetes Deployment
```yaml
# k8s/velocity-x-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: velocity-x-agents
spec:
  replicas: 3
  selector:
    matchLabels:
      app: velocity-x
  template:
    metadata:
      labels:
        app: velocity-x
    spec:
      containers:
      - name: velocity-x
        image: velocity-x:latest
        resources:
          requests:
            memory: "2Gi"
            cpu: "1"
          limits:
            memory: "4Gi"
            cpu: "2"
        env:
        - name: VELOCITY-X_CONFIG_PATH
          value: "/config/agents.yaml"
        volumeMounts:
        - name: config
          mountPath: /config
        - name: workspace
          mountPath: /workspace
      volumes:
      - name: config
        configMap:
          name: velocity-x-config
      - name: workspace
        persistentVolumeClaim:
          claimName: velocity-x-workspace
```

## Summary

Your VELOCITY-X environment is now configured and ready for productive development:

✅ **Installation**: Complete setup across multiple platforms

✅ **Configuration**: Optimized for your development workflow

✅ **Integration**: Connected with your preferred IDE and tools

✅ **Security**: Properly secured for safe operation

✅ **Performance**: Tuned for optimal resource utilization

✅ **Troubleshooting**: Armed with diagnostic tools and solutions

## Exercises

1. **Installation Practice**: Set up VELOCITY-X on a different platform than your primary development environment

2. **Configuration Tuning**: Experiment with different timeout and memory settings to optimize for your workload

3. **IDE Integration**: Set up VELOCITY-X integration with your preferred IDE and create custom shortcuts

4. **CI Integration**: Implement VELOCITY-X in a sample project's CI/CD pipeline

## Further Reading

- [Polish Specialist Deep Dive](04-polish-specialist.md)
- [Workflow Design Patterns](08-workflow-design.md)
- [Troubleshooting Guide](11-troubleshooting.md)

---

*Next Chapter: [Polish Specialist Deep Dive](04-polish-specialist.md) - Master the code quality improvement agent*