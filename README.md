# UVchecker - Smart UV Protection for iOS

Real-time UV monitoring and personalized sun protection guidance designed to help you stay safe in the sun.

## Overview

UVchecker is a comprehensive UV protection app that combines real-time UV index monitoring with personalized burn risk calculations and intelligent reminders. Using Apple's WeatherKit for accurate UV data and advanced algorithms for skin type analysis, UVchecker provides tailored sun protection recommendations that adapt to your unique needs.

## Core Features

### 🌞 Real-Time UV Monitoring
- **Current UV Index Display** - Live UV levels with color-coded severity indicators
- **24-Hour Forecast Timeline** - Visual hourly UV predictions to plan your day
- **Tomorrow's Forecast** - Next-day UV outlook for advance planning
- **Weather Integration** - Temperature and weather conditions alongside UV data
- **Auto-Refresh** - Pull-to-refresh and automatic data updates

### 🔬 Personalized Burn Time Calculations
- **Skin Type Profiling** - Fitzpatrick scale-based skin typing (Type I-VI)
- **Dynamic Risk Assessment** - Real-time burn time calculations based on:
  - Your skin type
  - Current UV index
  - Cloud cover conditions
  - Sunscreen application status
- **Warning Levels** - Color-coded alerts (Safe, Caution, Warning, Danger)
- **Intelligent Recommendations** - Contextual sun protection advice

### 🧴 Sunscreen Tracking & Management
- **Application Logging** - Track when and what SPF you've applied
- **Quantity Tracking** - Monitor application amount (Light, Normal, Heavy)
- **Reapplication Reminders** - Smart notifications based on:
  - Time elapsed since application
  - UV exposure levels
  - Activity level
- **SPF Effectiveness** - Visual indicators of current protection status
- **Quick Reapply** - One-tap sunscreen reapplication logging

### 📍 Advanced Location Services
- **GPS Location** - Precise location for accurate UV data
- **IP-Based Fallback** - Automatic fallback when GPS unavailable
- **VPN Detection** - Alerts when VPN may affect location accuracy
- **Location Type Indicators** - Clear labeling of data source (GPS, IP, Manual)
- **Privacy-First Design** - Minimal location data collection

### 🔔 Smart Notification System

#### Leave-Home Reminders
- **Geofencing Technology** - Detects when you leave home
- **UV-Triggered Alerts** - Only notifies when UV index ≥ 3
- **Contextual Messages** - Personalized recommendations based on conditions
- **Permission Management** - Progressive permission requests

#### Sunscreen Reapplication Alerts
- **Timely Reminders** - Based on SPF degradation curves
- **Activity-Adjusted** - Accounts for swimming, sweating, toweling
- **Actionable Notifications** - Quick actions directly from notifications

### 📱 Home Screen Widgets

#### Widget Sizes & Types
- **Small Widget** - Compact UV index display with location
- **Medium Widget** - UV data with recommendations and status
- **Large Widget** - Comprehensive dashboard with multiple metrics
- **Lock Screen Widgets** - Quick glance UV information
  - Circular: UV index icon and value
  - Rectangular: UV level with burn time
  - Inline: Text-based UV status

#### Widget Features
- **Real-Time Updates** - Automatic refresh every 30 minutes
- **Customizable Display** - Show/hide burn time, sunscreen status
- **Data Staleness Indicators** - Visual cues when data needs refresh
- **App Group Sync** - Seamless data sharing with main app

### ⚙️ Settings & Customization

#### Skin Profile Management
- **Profile Wizard** - Guided setup for accurate skin typing
- **Multiple Profiles** - Support for different users
- **Profile Updates** - Easy modification of skin characteristics

#### Permission Controls
- **Granular Settings** - Control each permission independently
- **Deep Linking** - Quick access to iOS Settings
- **Status Indicators** - Clear display of current permissions

#### Privacy & Security
- **Local Data Storage** - User data stays on device
- **No Account Required** - Full functionality without sign-up
- **Minimal Permissions** - Only requests what's necessary
- **Transparent Usage** - Clear explanations for each permission

## Technical Excellence

### Performance
- **Swift 6.2** - Latest language features for optimal performance
- **SwiftUI** - Native, responsive user interface
- **SwiftData** - Efficient local data persistence
- **Background Processing** - Minimal battery impact

### Data Sources
- **WeatherKit** - Apple's weather service for UV data
- **IPinfo.io** - IP geolocation fallback service
- **CoreLocation** - Native iOS location services

### Platform Support
- **iOS 26.0+** - Optimized for latest iOS features
- **iPhone** - Full support for all iPhone models
- **iPad** - Responsive layout for tablets
- **Apple Watch** - Companion app (coming soon)

## User Experience

### Onboarding Flow
1. **Welcome Screen** - App introduction and benefits
2. **Location Permission** - Progressive permission requests
3. **Skin Profile Setup** - Optional personalization
4. **Ready to Use** - Immediate UV monitoring

### Visual Design
- **Adaptive UI** - Supports light and dark modes
- **System Integration** - Follows iOS design guidelines
- **Accessibility** - VoiceOver and Dynamic Type support
- **Haptic Feedback** - Tactile responses for interactions

### Error Handling
- **Graceful Degradation** - Works with limited permissions
- **Offline Support** - Cached data when network unavailable
- **Clear Messaging** - User-friendly error explanations
- **Recovery Options** - Actionable solutions for issues

## Key Benefits

### For Health-Conscious Users
- Prevent sunburn with personalized timing alerts
- Track sun exposure patterns over time
- Make informed decisions about outdoor activities
- Maintain vitamin D balance safely

### For Parents
- Protect children with accurate burn time calculations
- Set reminders for family sunscreen application
- Plan outdoor activities during safer UV periods
- Educate kids about sun safety

### For Outdoor Enthusiasts
- Real-time UV data for hiking, biking, running
- Activity-based protection recommendations
- Weather integration for complete outdoor planning
- Lightweight, non-intrusive monitoring

### For Sensitive Skin
- Customized recommendations for your skin type
- Early warning system for high UV exposure
- Track what works for your protection routine
- Reduce skin damage and premature aging

## Privacy & Data

### What We Collect
- Location data (only for UV data retrieval)
- Skin profile information (stored locally)
- Sunscreen application history (on device only)

### What We Don't Collect
- Personal identification information
- Health records or medical data
- Usage analytics or tracking
- Contact information

### Data Storage
- All user data stored locally on device
- No cloud synchronization
- No third-party data sharing
- Complete user control over data

## Coming Soon

### Planned Features
- **Apple Watch App** - UV monitoring on your wrist
- **UV Camera Integration** - Visualize sunscreen coverage
- **Social Sharing** - Share UV safety tips with friends
- **Historical Trends** - Track your sun exposure over time
- **Multiple Locations** - Monitor UV at different places
- **Vitamin D Tracking** - Balance protection with vitamin D needs

## Support

- **In-App Help** - Contextual guidance throughout the app
- **Email Support** - Direct assistance when needed
- **Regular Updates** - Continuous improvements and new features
- **Community Feedback** - User-driven development priorities

## Requirements

- iOS 26.0 or later
- iPhone with GPS capability
- Internet connection for UV data updates
- Apple Developer account for WeatherKit access

---

UVchecker - Your intelligent companion for safe sun exposure. Stay protected, stay informed, stay healthy.