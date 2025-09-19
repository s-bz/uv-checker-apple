# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

UVchecker is a SwiftUI-based iOS application that provides real-time UV index monitoring, personalized sunburn risk calculations, and smart reminders for sun protection. The app uses WeatherKit for UV data, SwiftData for persistence, and includes a widget extension for home screen monitoring.

### Key Features
- Real-time UV index monitoring with 24-hour forecast
- Personalized burn time calculations based on skin type
- Sunscreen application tracking and reapplication reminders
- Leave-home reminders when UV levels are high
- Home screen widget with current UV data
- Location-based weather and UV updates

## Development Guidelines

### IMPORTANT: Working Principles

1. **Never ask for permission to commit** - Only commit when explicitly requested with "commit" in the user's message
2. **Don't change UI without permission** - Always ask before making visual changes or modifying user-facing text
3. **Build before committing** - Always ensure the code builds successfully before committing
4. **Test your changes** - Run the app in simulator to verify changes work as expected
5. **Preserve existing functionality** - Don't remove or modify features without explicit instruction
6. **Follow existing patterns** - Match the codebase's existing style and architecture

### Development Commands

#### Building and Running
- **Build**: `xcodebuild -scheme UVchecker -destination 'platform=iOS Simulator,name=iPhone 17'`
- **Clean Build**: `xcodebuild clean build -scheme UVchecker`
- **Run in Simulator**: Build first, then the app will launch automatically
- **Widget Testing**: Build and run, then add widget from home screen

#### Testing
- **Run All Tests**: `xcodebuild test -scheme UVchecker -destination 'platform=iOS Simulator,name=iPhone 17'`
- **Lint/Format**: The project uses Swift's built-in formatting

## Architecture

### Core Components

#### Data Models (`/Models`)
- `UVData.swift` - UV index data and weather conditions
- `SkinProfile.swift` - User skin type and burn risk calculations
- `SunscreenApplication.swift` - Sunscreen tracking
- `LocationData.swift` - Location information storage

#### Services (`/Services`)
- `WeatherKitService.swift` - WeatherKit API integration for UV data
- `LocationService.swift` - CoreLocation wrapper with permission handling
- `NotificationService.swift` - Local notifications for reminders
- `WidgetDataManager.swift` - App Groups data sharing with widget
- `BurnTimeCalculator.swift` - Sunburn risk calculations

#### Views (`/Views`)
- `DashboardView.swift` - Main app interface
- `UVTimelineView.swift` - 24-hour UV forecast timeline
- `OnboardingViews/` - Initial setup flow
- `SkinProfile/` - Skin type configuration

#### Widget Extension (`/Widget`)
- `Widget.swift` - Home screen widget implementation
- `WidgetViews.swift` - Widget UI components
- Uses App Groups (`group.com.infuseproduct.UVchecker`) for data sharing

### Platform Requirements
- **iOS Target**: 26.0 and newer
- **Swift Version**: 6.2
- **Xcode Version**: 17.0+
- **Dependencies**: WeatherKit, SwiftData, WidgetKit

## Key Patterns & Conventions

### State Management
- SwiftData with `@Model` for persistent data
- `@Query` for reactive data fetching
- `@Environment(\.modelContext)` for data operations
- `@AppStorage` for user preferences
- `@StateObject` for service instances

### Location Permissions
- **Three-tier permission system**:
  1. "Allow Once" - Basic functionality
  2. "While Using App" - Real-time updates
  3. "Always Allow" - Leave-home reminders
- Progressive permission requests (don't ask for Always immediately)
- Deep link to Settings when upgrade not possible in-app

### Widget Updates
- Shared data via App Groups
- Timeline updates every 30 minutes
- Manual refresh via WidgetCenter

### UI Guidelines
- **Spacing**: 16pt standard padding
- **Cards**: `Color(UIColor.secondarySystemBackground)` with 12pt corner radius
- **Navigation**: Large titles with profile button
- **Colors**: System colors only (no custom colors)
- **Feedback**: Haptic feedback for selections

## Common Tasks

### Adding a New Feature
1. Check existing patterns in similar features
2. Ask user about UI/UX changes before implementing
3. Update both app and widget if applicable
4. Test thoroughly in simulator
5. Only commit when explicitly requested

### Fixing Bugs
1. Reproduce the issue first
2. Fix without changing unrelated code
3. Test the fix thoroughly
4. Verify no regressions
5. Document the fix in commit message when requested

### Updating Permissions
1. Always update Info.plist with usage descriptions
2. Handle all permission states gracefully
3. Provide clear user guidance
4. Test permission flows from clean install

## Important Files

### Configuration
- `Info.plist` - App permissions and configuration
- `PrivacyInfo.xcprivacy` - Privacy manifest
- `UVchecker.entitlements` - App capabilities
- `WidgetExtension.entitlements` - Widget capabilities

### User Data
- SwiftData models persist to app container
- Widget data shared via App Groups
- Location cached for offline use

## Testing Checklist

Before considering any task complete:
- [ ] Code builds without errors
- [ ] App launches successfully
- [ ] Feature works as expected
- [ ] No UI regressions
- [ ] Widget updates properly (if applicable)
- [ ] Permissions handled gracefully
- [ ] Error states handled

## Do's and Don'ts

### DO:
- ✅ Ask before changing UI
- ✅ Test in simulator before saying "done"
- ✅ Follow existing code patterns
- ✅ Handle errors gracefully
- ✅ Update widget when app data changes
- ✅ Use system colors and fonts

### DON'T:
- ❌ Commit without explicit request
- ❌ Change UI without permission
- ❌ Remove existing features
- ❌ Add external dependencies
- ❌ Use custom colors without approval
- ❌ Request all permissions at once
- ❌ Assume code works without testing

## Git Workflow

1. Only commit when user explicitly requests
2. Write clear, descriptive commit messages
3. Include emoji only if requested
4. Don't push unless explicitly asked
5. Never force push or rewrite history

## Notes

- The app is designed for iOS 26+ with latest Swift features
- WeatherKit requires active Apple Developer account
- Widget must be manually added from home screen
- Background location requires "Always Allow" permission
- App Store distribution requires proper provisioning profiles