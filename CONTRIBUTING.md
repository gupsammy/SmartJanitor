# Contributing to Mac Storage Cleaner

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## 🚀 Quick Start

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/yourusername/SmartJanitor.git
   cd SmartJanitor
   ```
3. Install for development:
   ```bash
   ./scripts/install-dev.sh
   ```

## 🏗️ Project Structure

```
SmartJanitor/
├── scripts/
│   ├── weekly-cleanup.sh         # Main bash cleanup logic
│   ├── monthly-claude-cleanup.sh # Claude Code integration
│   ├── send-notification.sh      # macOS notification system
│   └── manage-cleanup.sh         # CLI management interface
├── install.sh                    # One-line installer
├── docs/                        # Documentation and images
└── tests/                       # Test scripts
```

## 🧪 Development Setup

### Prerequisites

- macOS 14+ (for testing)
- Bash 4+
- Basic familiarity with launchd and macOS automation

### Development Installation

The development installer creates symlinks instead of copying files:

```bash
./scripts/install-dev.sh
```

This allows you to edit files and see changes immediately without reinstalling.

## 🔧 Making Changes

### Bash Scripts

- **Follow ShellCheck recommendations**: Run `shellcheck script.sh`
- **Test thoroughly**: Storage cleanup is sensitive - test on multiple macOS versions
- **Use safe patterns**: Always use `-f` flags for non-interactive operations
- **Handle errors gracefully**: Use `set -e` and proper error checking

### Claude Code Integration

- **Conservative approach**: Only allow safe cleanup operations
- **Test with restricted permissions**: Use `--dangerously-skip-permissions` carefully
- **Validate tool allowlists**: Ensure only safe tools are permitted

### Notifications

- **Use AppleScript**: For consistent macOS notification behavior
- **Handle user interaction**: Support both dismiss and view-logs actions
- **Test across macOS versions**: Notification APIs can vary

## 🧪 Testing

### Manual Testing

```bash
# Test weekly cleanup (safe to run)
smartjanitor test-weekly

# Test monthly cleanup (requires Claude Code)
smartjanitor test-monthly

# Check service status
smartjanitor status

# View logs
smartjanitor logs
```

### Automated Testing

```bash
# Run test suite (when available)
./tests/run-tests.sh

# Lint all scripts
./tests/lint-scripts.sh
```

## 📝 Code Style

### Bash Style Guide

- Use 4 spaces for indentation
- Quote variables: `"$VARIABLE"`
- Use `local` for function variables
- Prefer `[[ ]]` over `[ ]`
- Use meaningful function names
- Add comments for complex logic

### Example:

```bash
cleanup_docker_cache() {
    local cache_size_before
    local cache_size_after

    if command -v docker &> /dev/null; then
        cache_size_before=$(docker system df --format "{{.Size}}" | head -1)
        docker system prune -a -f --volumes
        cache_size_after=$(docker system df --format "{{.Size}}" | head -1)

        echo "Docker cache: $cache_size_before → $cache_size_after"
    else
        echo "Docker not available, skipping"
    fi
}
```

## 🔒 Security Guidelines

### File Operations

- **Never use `rm -rf` on user directories**
- **Always validate paths** before deletion
- **Use age-based filtering** for build artifacts
- **Whitelist safe directories** only

### Permission Handling

- **Minimal permissions**: Only request what's needed
- **Document security model**: Explain what tools can do
- **User consent**: Always show what will be cleaned

### Claude Code Integration

- **Restrict tool access**: Use allowedTools/disallowedTools
- **Safe prompts**: Never allow file editing or sensitive operations
- **Validate responses**: Check Claude's planned actions

## 📋 Pull Request Guidelines

### Before Submitting

1. **Test thoroughly** on your local machine
2. **Run linting**: `shellcheck scripts/*.sh`
3. **Update documentation** if adding features
4. **Add tests** for new functionality

### PR Description Template

```markdown
## 🎯 What does this PR do?

Brief description of changes

## 🧪 Testing

- [ ] Tested on macOS 14
- [ ] Tested weekly cleanup
- [ ] Tested monthly cleanup (if applicable)
- [ ] Tested installation process
- [ ] Verified notifications work

## 📝 Checklist

- [ ] Code follows style guide
- [ ] Documentation updated
- [ ] No security issues introduced
- [ ] Backward compatibility maintained
```

## 🐛 Reporting Issues

### Bug Reports

Please include:

- macOS version
- Shell version (`bash --version`)
- Full error logs
- Steps to reproduce
- Expected vs actual behavior

### Feature Requests

- Use case description
- Proposed implementation approach
- Potential security considerations
- Compatibility impact

## 🏷️ Versioning

We use Semantic Versioning (semver):

- **Major**: Breaking changes to installer or CLI
- **Minor**: New features, new cleanup targets
- **Patch**: Bug fixes, documentation updates

## 🎖️ Recognition

Contributors are recognized in:

- GitHub Contributors section
- Release notes for significant contributions
- README acknowledgments

## 📞 Getting Help

- **General questions**: [GitHub Discussions](https://github.com/gupsammy/SmartJanitor/discussions)
- **Bug reports**: [GitHub Issues](https://github.com/gupsammy/SmartJanitor/issues)
- **Security issues**: Email [samarthgupta1911@gmail.com](mailto:samarthgupta1911@gmail.com)

## 🤝 Code of Conduct

Be respectful, inclusive, and constructive. We're all here to make Mac storage management better!

---

Thank you for contributing to SmartJanitor! 🚀
