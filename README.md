# YoMemo Client (Flutter)

[![Build Desktop](https://github.com/yomemoai/yomemoai-client/actions/workflows/build.yml/badge.svg)](https://github.com/yomemoai/yomemoai-client/actions/workflows/build.yml)

YoMemo is a security-first memory relay for AI applications. This Flutter client provides a local, zero-trust experience with hybrid encryption and a local lock screen.

## Features

- Hybrid encryption compatible with `python-yomemo-mcp`
- Local password lock with idle timeout
- Handle-based grouping and quick memory editing
- Help menu with Docs and GitHub
- YoMemo brand styling and logo assets

## Requirements

- Flutter SDK 3.10+
- macOS (for macOS build)

## Setup

1. Install dependencies:
   ```bash
   flutter pub get
   ```
2. Configure API key and private key path in the app Settings.

## Security Model

- Client-side hybrid encryption (RSA-OAEP + AES-GCM)
- No plaintext stored on the server
- Local lock protects access on device

## Shortcuts

- `⌘ + L` / `Ctrl + L`: Lock immediately

## Build & Run

```bash
flutter run -d macos
```

## Docs

- Product: https://yomemo.ai
- Docs: https://doc.yomemo.ai
