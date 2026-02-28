# Contributing to Proxmox Autoshutdown

Thank you for your interest in contributing!

## Development Setup

```bash
# Clone and enter repository
git clone https://github.com/Anwar-Projects/proxmox-autoshutdown.git
cd proxmox-autoshutdown

# Install development dependencies
make deps

# Run tests to ensure everything works
make test
```

## Code Style

This project uses:

- **Shellcheck** for static analysis
- **shfmt** for formatting (2 space indent)
- Set `set -Eeuo pipefail` in all scripts

### Running Linters

```bash
make lint        # Run shellcheck
make check       # Check formatting
make format      # Auto-format with shfmt
```

## Testing

```bash
make test          # Run all tests
make test-smoke    # Quick smoke tests
make test-unit     # BATS unit tests
```

### Writing Tests

Add unit tests to `tests/test-functions.bats`:

```bash
@test "my new function works" {
  source "$LIB_DIR/my-module.sh"
  run my_function
  [ "$status" -eq 0 ]
}
```

## Pull Request Process

1. Create a feature branch: `git checkout -b feature/my-feature`
2. Make your changes with clear commit messages
3. Run `make test` and ensure all tests pass
4. Update documentation if needed
5. Submit PR with a clear description

## Module Guidelines

When adding new modules to `lib/`:

1. Include header comment with description
2. Set `set -Eeuo pipefail`
3. Export state variables explicitly
4. Add tests for public functions
5. Update README.md if adding user-facing features

## Commit Messages

Use conventional commits style:

- `feat: add new feature`
- `fix: resolve bug`
- `docs: update README`
- `test: add tests`
- `refactor: restructure code`
- `chore: update dependencies`

## Questions?

Open an issue for:

- Bug reports
- Feature requests
- Documentation improvements
- General questions

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
