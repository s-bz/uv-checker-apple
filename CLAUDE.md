# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

UVchecker is a SwiftUI-based iOS/macOS application built with Xcode. It currently provides a basic template app with SwiftData integration for data persistence.

## Development Commands

### Building and Running
- **Build**: Use Xcode build (⌘+B) or `xcodebuild` in terminal
- **Run**: Use Xcode run (⌘+R) or select target device/simulator
- **Clean Build**: Product → Clean Build Folder (⇧⌘+K)

### Testing
- **Run All Tests**: Use Xcode test (⌘+U) or `xcodebuild test`
- **Run Specific Test**: Click the diamond icon next to test function in Xcode
- **Test Targets**: 
  - `UVcheckerTests` - Unit tests
  - `UVcheckerUITests` - UI tests

## Architecture

### Core Components

**SwiftUI App Structure**
- `UVcheckerApp.swift`: Main app entry point, configures SwiftData ModelContainer
- `ContentView.swift`: Primary view with navigation split view pattern, handles item list display and management
- `Item.swift`: SwiftData model for persistent storage

**Data Layer**
- Uses SwiftData with `@Model` macro for data persistence
- ModelContainer configured with in-memory storage for tests/previews
- Query-driven UI updates via `@Query` property wrapper

**Platform Considerations**
- Conditional compilation for iOS/macOS differences (e.g., `#if os(iOS)`)
- NavigationSplitView for adaptive layouts
- Platform-specific toolbar items

## Key Patterns

- **SwiftData Integration**: Models use `@Model`, views use `@Query` and `@Environment(\.modelContext)`
- **Navigation**: NavigationSplitView with list-detail pattern
- **State Management**: Environment-based model context injection
- **Testing**: Separate test targets for unit and UI tests with XCTest framework