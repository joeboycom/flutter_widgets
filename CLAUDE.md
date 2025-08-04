# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

### Development
- `flutter run` - Run the app with hot reload
- `flutter run -d chrome` - Run in Chrome browser
- `flutter run -d <device_id>` - Run on specific device

### Testing and Quality
- `flutter test` - Run all tests
- `flutter test test/widget_test.dart` - Run specific test file
- `flutter analyze` - Run static analysis with Flutter lints

### Building
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app (requires macOS)
- `flutter build web` - Build for web
- `flutter build <platform>` - Build for specific platform

### Dependencies
- `flutter pub get` - Install dependencies
- `flutter pub upgrade` - Upgrade dependencies

## Architecture

This is a Flutter application using the standard Flutter architecture:

### State Management
Currently uses basic `setState()` for state management. The main stateful widget pattern:
- `StatefulWidget` class defines the widget
- `State` class manages mutable state
- `setState()` triggers UI rebuilds

### Project Structure
- `/lib/main.dart` - Entry point containing MyApp root widget and MyHomePage
- `/test/` - Widget and unit tests
- `/android/`, `/ios/`, `/web/`, `/linux/`, `/windows/`, `/macos/` - Platform-specific code
- `pubspec.yaml` - Package configuration and dependencies

### Key Patterns
- Material Design components (Scaffold, AppBar, FloatingActionButton)
- Widget composition for UI building
- Hot reload for rapid development iteration
- Flutter lints for code quality (v5.0.0)

### Testing Approach
Uses `flutter_test` package with:
- `testWidgets()` for widget testing
- `WidgetTester` for UI interaction simulation
- `find` and `expect` for assertions