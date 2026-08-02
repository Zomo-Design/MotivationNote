# Contributing

Thanks for helping improve MotivationNote.

## Development setup

You need macOS 14 or later and a Swift 6 toolchain.

```bash
git clone https://github.com/nuonuostyjo-design/MotivationNote.git
cd MotivationNote
./scripts/run-checks.sh
swift build
```

Use `./scripts/build-app.sh` when you need a runnable `.app` bundle.

## Pull requests

1. Open an issue for behavior changes that need design discussion.
2. Keep changes focused and preserve offline-only operation.
3. Add or update checks when behavior changes.
4. Run `./scripts/run-checks.sh` and `swift build` before opening a pull request.
5. Explain the user-visible effect and include screenshots for UI changes.

By contributing, you agree that your contribution is licensed under the MIT
License.
