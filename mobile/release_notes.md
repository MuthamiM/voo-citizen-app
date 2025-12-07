# v11.0.1: Google Login Hotfix

This patch release fixes a critical issue where Google Sign-In would time out or hang.

## 🐛 Bug Fixes

- **Google Authentication**: Fixed an issue where the app was attempting to verify Google tokens with a local development server instead of the live production server.
- **Timeouts**: Added a 40-second timeout to Google Auth requests to better handle server "cold starts".

## 📦 Previous Changes (v11.0.0)

- **Offline Support**: Submit issues while offline.
- **Encrypted Database**: Enhanced privacy for stored data.
- **Permissions Cleanup**: Removed unused permissions.

> **Note**: If you already installed v11.0.0, you can simple update. If coming from v8.x, **uninstall first** due to database encryption changes.
