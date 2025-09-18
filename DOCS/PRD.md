# PRD: Infuse UV Checker (iOS, watchOS, iOS Widgets)

### TL;DR

A fast, privacy-first UV checker for iPhone, Apple Watch, and iOS widgets that shows current and hourly UV for your approximate location, estimates time-to-sunburn and sunscreen reapplication based on user skin profile, and provides proactive reminders when leaving home. Launch focus on high-UV regions (APAC, Australia) with global coverage.

---

## Goals

### Business Goals

* Acquire 100,000 installs within 90 days via App Store search optimization and cross-promotion from VPN Super user base

* Achieve 35% weekly active users (WAU) and 20% day-1 retention within first quarter

* Maintain server-side costs under $0.05 per monthly active user at 100k MAU scale

* Build foundation for future monetization via RevenueCat subscription framework without degrading core user experience

* Establish market presence in high-UV regions (APAC, Australia) as springboard for global expansion

### User Goals

* Get instant UV clarity at a glance without complex navigation or setup

* Receive personalized sun safety guidance based on individual skin characteristics

* Get timely leave-home reminders to apply sunscreen before UV exposure

* Access simple, glanceable UV data on Apple Watch complications and widgets

* Enjoy low-battery impact and low-noise notification experience that respects user attention

### Non-Goals

* User accounts, login systems, or cloud data synchronization

* Precise GPS tracking, location history, or detailed movement trails

* Full offline weather forecasting capabilities beyond basic caching

* Medical diagnosis, treatment recommendations, or health advice beyond general sun safety

* Crowd-sourced UV readings or user-generated content features

---

## User Stories

**Everyday Commuter**

* As an everyday commuter, I want to check today's UV level at a glance on my phone's home screen widget, so that I can decide whether to apply sunscreen before leaving for work.

* As an everyday commuter, I want to receive a gentle reminder notification when I'm about to leave home on high-UV days, so that I don't forget sun protection.

* As an everyday commuter, I want to see hourly UV predictions for my commute times, so that I can plan my sun exposure throughout the day.

**Outdoor Enthusiast**

* As an outdoor enthusiast, I want to input my skin type and get personalized burn-time estimates, so that I know how long I can safely stay outside.

* As an outdoor enthusiast, I want to see when I need to reapply sunscreen based on my skin profile, so that I maintain consistent protection.

* As an outdoor enthusiast, I want quick access to UV data on my Apple Watch, so that I can check conditions without pulling out my phone during activities.

* As an outdoor enthusiast, I want to simulate different times of day to plan my outdoor activities, so that I can optimize my schedule around UV levels.

**Parent/Caregiver**

* As a parent, I want to understand safe sun exposure times for my children, so that I can protect them from harmful UV rays.

* As a parent, I want clear visual indicators of dangerous UV levels, so that I can quickly assess whether it's safe for family outdoor time.

* As a parent, I want educational content about sun safety, so that I can make informed decisions about my family's UV exposure.

**Watch-First User**

* As a watch-first user, I want UV data displayed prominently on my watch face complication, so that I can check conditions instantly.

* As a watch-first user, I want simplified UV alerts delivered directly to my wrist, so that I don't need to rely on my phone for sun safety information.

---

## Functional Requirements

* **Data & Location** (Priority: Critical)

  * Current UV Index: Real-time UV index data for user's approximate location

  * Hourly UV Forecast: 24-hour UV predictions with interactive timeline scrubber

  * Location Services: Approximate location detection with privacy-first approach; display resolved location string and last-updated timestamp; allow manual refresh and manual location override

  * Current Weather: Temperature and condition icon for reassurance and context (sourced from the same provider as UV)

  * Data Source Integration: Weather API integration with fallback providers

* **Personalization** (Priority: High)

  * Skin Profile Setup: Fitzpatrick skin type selection with visual guide; optional attributes (eye color, natural hair color, freckles, tanning response) to refine mapping to Fitzpatrick type

  * Burn Time Calculator: Personalized safe exposure time estimates computed per selected hour on the wheel

  * Sunscreen & SPF: Main-screen "Sunscreen" button opens a sheet to set SPF (None, 15, 30, 50+), quantity (Low, Medium, Lots), and the time applied (Now or custom). Selected values appear as a chip on the home screen and immediately adjust burn-time and the Sunscreen Window.

  * Quantity-to-dose mapping: Low ≈ 0.5 mg/cm², Medium ≈ 1.0 mg/cm², Lots ≈ 2.0 mg/cm² (the lab test dose). When users pick Low/Medium, suggest a “Double application” nudge to reach full protection.

  * Remove Sunscreen: One-tap "Remove" action clears the current SPF state and reverts calculations.

  * Sunscreen Timer: Reapplication reminders based on skin type, SPF, quantity, and UV levels; default reminder every 2 hours and after swim/sweat/toweling (always on, user can add earlier reminders).

  * Settings Persistence: User preferences stored locally on device

* **Alerts & Reminders** (Priority: High)

  * Leave-Home Notifications: Smart notifications when transitioning from Wi-Fi to cellular

  * UV Threshold Alerts: Customizable high-UV warnings

  * Sunscreen Reminders: Time-based reapplication notifications

  * Quiet Hours: Respect Do Not Disturb and user-defined quiet periods

* **iOS Widgets** (Priority: High)

  * Home Screen Widgets: Small, medium, and large widget sizes showing current UV and forecast

  * UV Wheel Widget: Small, Medium, and Large variants. Small shows a compact mini-wheel with current UVI and abbreviated burn-time (e.g., “BT 25m”); Medium/Large render the full 24-hour radial UV wheel with peak window and “Sunscreen Window” arc. Tap behavior: Small → opens app at Now; Medium/Large → opens at selected hour.

  * Lock Screen Widgets: Quick glance UV data on iOS 16+ lock screens; circular lock-screen widget uses mini-wheel ring with current UVI in center

  * Widget Customization: Color themes and data display options; burn-time display enabled by default with an in-app toggle to hide

  * Auto-Refresh: Background data updates with location changes and at Apple’s WidgetKit refresh budget

* **watchOS Integration** (Priority: Medium)

  * Watch App: Standalone Apple Watch app with current UV and basic forecast

  * UV Wheel View: Crown-rotatable radial UV wheel with haptic ticks per hour; tap any segment to jump focus with a distinct haptic; center shows UVI and burn-time for focused hour; top of screen shows location + temp line for reassurance

  * Complications: Graphic Circular displays mini-wheel; Modular/Utilitarian show current UVI with color chip; Corner complications show peak window arc and optionally the start→end time as a compact range

  * Glance Interface: Quick UV check optimized for outdoor readability (high contrast, minimal taps)

  * Independent Operation: Basic functionality without iPhone dependency

* **Education & Content** (Priority: Medium)

  * UV Index Guide: Educational content explaining UV levels and risks

  * Sun Safety Tips: Contextual advice based on current conditions

  * Skin Type Information: Detailed guidance on Fitzpatrick classification

  * Seasonal Awareness: Location-specific UV pattern education

* **Guidance & Summaries** (Priority: High)

  * Sunscreen Window Calculation: Compute start→end time range when protection is recommended; default threshold UVI ≥3, configurable in Settings to UVI ≥6 or “Personalized” using skin type and SPF

  * Hourly Burn-Time Calculation: For each focused hour, compute time-to-erythema (burn-time) using the user’s mapped Fitzpatrick MED baseline scaled by forecast UVI at that hour and adjusted for effective SPF and cloud cover attenuation; cap between 5 and 240 minutes. Effective SPF derives from dose and decay (see Burn‑Time Engine).

  * Sunscreen Window Display: Banner on dashboard and arc overlay on the wheel; exposed in Medium/Large widgets and Corner complications as a compact time range

  * Scrub-to-Update: When user scrubs or taps an hour, center panel updates time, UVI, and burn-time in real time; banner adapts to show whether the focused hour is inside or outside the window

* **Privacy & Telemetry** (Priority: Medium)

  * Anonymous Analytics: Privacy-first usage tracking via PostHog

  * Crash Reporting: Error tracking without personal data collection

  * Location Privacy: Approximate location without precise coordinates storage

  * Data Minimization: Collect only essential data for functionality

* **Internationalization** (Priority: Low)

  * Multi-Language Support: Initial support for English, Spanish, French, Japanese

  * Localized Content: Region-specific sun safety guidance and UV patterns

  * Cultural Adaptation: Skin type guidance adapted for different populations

  * Regional Marketing: Localized App Store presence in target markets

---

## User Experience

**Entry Point & First-Time User Experience**

* Users discover the app through App Store search for "UV index," "sun safety," or cross-promotion from VPN Super

* App Store listing emphasizes speed, privacy, and Apple Watch integration with clear screenshots

* First launch presents welcoming tone-setting screen explaining the app's sun safety mission

* Immediate onboarding flow guides users through essential setup without overwhelming

**Core Experience**

* **Step 1:** App launches to main UV dashboard showing current conditions

  * Prominent current-conditions header: weather icon, temperature, and resolved location string (e.g., “Discovery Bay, Hong Kong SAR, China”) with a subtle “Using your location • Updated 11:17” status for reassurance; tap to change location or refresh

  * Large, clear UV index number with WHO color background (green/yellow/orange/red/purple)

  * “Sunscreen Window” banner shows today’s recommended protection window (e.g., “Take care 9:20 am – 2:40 pm”) derived from forecast thresholds

  * No loading screens – cached data displays immediately with fresh data updating seamlessly

* **Step 2:** User completes initial skin profile setup (if not done previously)

  * Visual Fitzpatrick skin type selector with diverse representation

  * Simple question format: "Choose the option that best describes your skin"

  * Educational tooltips explaining each skin type without medical jargon

  * Optional step with "Set Up Later" option to reduce friction

* **Step 3:** Main dashboard provides actionable UV information

  * Personalized burn time estimate: "Safe outside for \~25 minutes without sunscreen"

  * Sunscreen controls: "Sunscreen" button to set SPF, quantity, and applied time; chip shows current state (e.g., "SPF 30 • Lots • 10:05 am") with a small "×" to remove. Reapply timer shows ETA when active.

  * Quick access to hourly forecast scrubber and the UV Wheel for scrubbing; center updates with hour, UVI, and burn-time

  * Prominent "Remind Me" button for leave-home notifications

* **Step 4:** User interacts with the UV Wheel (24-hour radial forecast)

  * Circular wheel shows the next 24 hours mapped around the clock; each hour is a segment colored by UV level (UVI 0–2 green, 3–5 yellow, 6–7 orange, 8–10 red, 11+ purple)

  * Drag the handle around the wheel to scrub; center panel updates in real-time with hour, UVI, and personalized burn-time (factoring current SPF if set)

  * Tap any segment to jump focus to that hour with a distinct haptic; long-press opens hour detail sheet with expanded guidance (“BT 18m with SPF 30 • Reapply by 12:40 pm”)

  * “Sunscreen Window” arc overlay clearly marks the start → end times requiring protection; entering the arc triggers a stronger haptic

  * Peak UV window highlighted as a thicker arc; current time indicated by a notch with subtle pulsing

  * Accessibility: color-blind safe patterns overlay at high UV levels; VoiceOver announces hour and UVI on focus; supports Dynamic Type

* **Step 5:** User sets up widgets and complications

  * In-app tutorial showing widget gallery access

  * Preview of different widget sizes with live data

  * One-tap shortcuts to add widgets to home screen

  * Apple Watch complication setup with visual guide

* **Step 6:** User receives contextual notifications

  * Smart leave-home detection triggers sunscreen reminders

  * Non-intrusive alerts that don't interrupt important tasks

  * Clear action buttons: "Applied Sunscreen," "Remind Later," "Turn Off"

  * Respectful of notification preferences and quiet hours

**Advanced Features & Edge Cases**

* Offline graceful degradation with cached forecast data when network unavailable

* Location permission denied fallback to manual location selection

* Apple Watch independent operation when iPhone not available

* Widget refresh failures handled silently with timestamp indicators

* High-UV emergency alerts for extreme conditions (UV 11+)

* Accessibility support with VoiceOver announcements and high contrast modes

**UI/UX Highlights**

* Radial UV Wheel as primary mental model: 24-segment ring (one per hour) with WHO-aligned color scale (0–2 green, 3–5 yellow, 6–7 orange, 8–10 red, 11+ purple); previous hours fade to \~30% opacity to de-emphasize the past

* Location reassurance: always-on location string and last-updated timestamp near header; mismatch states (GPS off / stale data) surface a subtle warning chip with “Update” action

* Sunscreen Window communication: banner text with time range and contextual verb (“Take care”, “Safe tonight”); matching arc overlay on the wheel

* Color-blind support: overlay patterns (diagonal stripes for ≥8, cross‑hatch for 11+) and explicit numeric labels on focus

* Readability outdoors: high-contrast palette, thick stroke weights, large center numerals; dark and light themes tuned for sunlight glare

* Haptics: gentle tick on hour change during scrub; distinct haptic on tap‑jump; stronger haptic for entering high UV arc (≥8); light haptic confirm when SPF is applied/removed; watchOS intensity capped to Soft to avoid notification fatigue outdoors

* Performance: wheel drawn with vector rendering; caches hourly UV to avoid layout thrash; 60fps target, 120Hz where available

* Touch targets sized appropriately for outdoor use; supports Dynamic Type; VoiceOver reads hour, UVI, and guidance

* Localized number formatting and time display based on user region preferences

**Visual Spec (MVP)**

* Wheel geometry: outer radius 168pt, inner radius 128pt (iPhone 15 baseline); 24 segments at 15° each; 2° gap between segments to create clear delineation; draw past-hour segments at 30% opacity.

* Arc thickness: peak UV highlight stroke 10pt; Sunscreen Window overlay 12pt with 60% opacity and subtle glow at edges for outdoor readability.

* Center panel: stacked labels — time (H:MM am/pm), UVI numeral (64pt, semi-bold), status/burn-time line (e.g., “Moderate • BT 25m”). Ellipsize gracefully on smaller screens.

* SPF controls: primary button 44pt high with label “Sunscreen”; opens a bottom sheet with segmented control for SPF (None/15/30/50+), quantity selector (Low/Medium/Lots), and time picker (Now/custom). Show an inline chip on the dashboard after apply with a clear affordance “× Remove”. Banner copy patterns: “Applied SPF 30 • Medium at 10:05 am — reapply by 12:05 pm”.

* Typography: San Francisco; header 17pt/semibold; UVI numeral 64pt/semi-bold; supporting text 15pt/regular; widgets scale proportionally (Small UVI 24pt, Medium 36pt, Large 48pt).

* Tap targets & input: minimum hit area 44×44pt; drag handle 28×28pt; Digital Crown step = 1 hour per notch, with inertial scroll disabled within the wheel.

* Colors: WHO palette with WCAG AA contrast on light and dark backgrounds; alpha ramp for UVI ≥8 adds 10% saturation.

* Loading & empty states: when data is stale (>90 minutes), show "Stale • Update" chip; if location off, show "Location Off" chip with action to enable or set manual location.

* Widgets: Small shows mini-wheel with dot indicator if the current hour is inside the Sunscreen Window; Medium/Large render full wheel with arc; all widgets show location city and last-updated time when budget allows.

* watchOS: use Graphic Circular for mini-wheel; peak window arc thickness 6pt; haptic types = soft tick (hour), impact light (entering window); max refresh every 60 minutes on low-power faces.

* Performance budget: 60fps target; drawing time <8ms/frame; memory for cached 24h data ≤200KB; battery impact <2%/day.

---

## Narrative

Sarah, a marketing manager in Sydney, checks her iPhone's home screen widget every morning during Australia's intense summer months. The widget shows UV 8 with a forecast peak of UV 11 at noon - she immediately knows it's going to be a serious sun day. As she prepares her coffee, Infuse sends a gentle notification: "High UV expected. Consider sunscreen before leaving home."

Rather than ignoring it like most app notifications, Sarah finds this helpful because it's perfectly timed and relevant. She opens the app and scrubs through the hourly forecast, discovering that UV levels will be moderate during her lunch meeting at 1 PM but dangerous during her 3 PM client visit. She decides to reschedule the outdoor portion of that meeting.

The app's skin profile feature, calibrated for her fair complexion, estimates she has about 15 minutes of safe exposure time without sunscreen - valuable information for her quick walk to the train station. Her Apple Watch complication keeps her informed throughout the day without needing to check her phone constantly.

By providing exactly the right information at the right time, Infuse becomes an invisible but essential part of Sarah's daily routine. For the business, Sarah represents the engaged user archetype - she checks the widget daily, relies on smart notifications, and values the personalized guidance enough to recommend the app to friends and family, driving organic growth in the crucial Australian market.

---

## Success Metrics

### User-Centric Metrics

* Daily Active Users (DAU): Target 25% of MAU engaging daily, measured via app opens and widget views

* Weekly Active Users (WAU): Target 35% of installs becoming weekly users within 30 days

* Day-1 Retention: Target 20% of new installs returning within 24 hours

* Widget Adoption: Target 60% of active users adding at least one home screen widget

* Notification Engagement: Target 40% positive response rate on leave-home sunscreen reminders

### Business Metrics

* Install Volume: 100,000 installs within 90 days via organic search and cross-promotion

* Cost Per Install: Maintain under $2.00 CPI for paid acquisition channels

* App Store Rating: Maintain 4.5+ star rating with focus on utility and privacy

* Cross-Promotion Conversion: Target 5% conversion rate from VPN Super user base

* Geographic Distribution: Target 40% of users from APAC region within first quarter

### Technical Metrics

* Server Cost Efficiency: Maintain under $0.05 per MAU in weather API and infrastructure costs

* App Performance: 95th percentile app launch time under 2 seconds with cached data

* Data Accuracy: 95% uptime for weather data sources with seamless fallback handling

* Battery Impact: Background refresh consumes less than 2% of device battery per day

* Widget Reliability: 99% successful widget refresh rate during normal network conditions

### Tracking Plan

* App Launch events with source attribution (organic, cross-promo, widget, complication)

* Onboarding completion rates by step (location permission, skin profile, notification opt-in)

* Feature engagement tracking (hourly scrubber usage, settings changes, educational content views)

* Sunscreen interactions: SPF applied (spf, quantity, applied_at), SPF removed, reapply reminder shown/acted

* Notification interaction events (delivered, opened, dismissed, action taken)

* Widget installation and removal events by size and placement

* Apple Watch app usage and complication interaction patterns

* User retention cohort analysis by acquisition source and engagement level

* Crash and error events with anonymized context for debugging

---

## Technical Considerations

### Technical Needs

* iOS native app built with Swift and SwiftUI for modern interface patterns

* WidgetKit implementation for home screen and lock screen widget experiences

* watchOS companion app with independent UV data access and complications

* Weather data API integration with multiple provider support for redundancy

* Local Core Data storage for user preferences, skin profiles, and cached forecasts

* Background App Refresh integration for proactive data updates and notifications

* Location Services integration with privacy-focused approximate positioning

* Push notification system for time-sensitive UV alerts and reminders

* Burn-Time Engine: deterministic function taking inputs {Fitzpatrick→MED baseline, hourly UVI, label SPF, dose (mg/cm²), applied timestamp, activity (indoors/normal/active), cloud cover}. Compute Effective SPF as: SPF_eff = (SPF_label)^(dose/2), where dose ∈ {Low 0.5, Medium 1.0, Lots 2.0}. Apply activity‑sensitive decay on SPF_eff since applied: indoors 0% for first 2h then −10% per additional 2h; normal −20% per 2h; active/water −35% per 2h and force reapply at 2h after water events. Output burn‑time minutes and reapply ETA. Unit-test with fixtures per skin type, SPF level, dose, and decay scenario.

Engineering Handoff (Appendix)

Formulas

* Effective SPF: SPF_eff = (SPF_label)^(dose/2) × (1 − decay), clamped to \[1, SPF_label\].

* Hourly burn-time (minutes): BT = clamp(5, 240, k × MED(Fitz) × SPF_eff ÷ UVI_hour), where k is a calibration constant set so that fair skin (Type I) at UVI 10 with no SPF yields ≈10 minutes.

Decay factors per 2 hours since applied

* Indoors: 0% for first 2h, then 10% each additional 2h

* Normal: 20% each 2h

* Active/Water: 35% each 2h; immediate “needs reapply” at 2h after water

Dose mapping from UI quantity

* Low = 0.5 mg/cm²; Medium = 1.0 mg/cm²; Lots = 2.0 mg/cm²

Worked examples (rounded)

* SPF 30, Low (0.5): SPF_eff ≈ 30^0.25 ≈ 2.3

* SPF 30, Medium (1.0): SPF_eff ≈ 30^0.5 ≈ 5.5

* SPF 50, Medium (1.0): SPF_eff ≈ 50^0.5 ≈ 7.1

* SPF 50, Lots (2.0): SPF_eff = 50

Copy strings

* Apply: “Applied SPF {spf} • {quantity} at {time} — reapply by {time_plus_2h}.”

* Remove: “Sunscreen cleared. Burn-time estimates updated.”

Assets to deliver

* Wheel vectors (SVG/PDF): base ring, segment mask, peak arc, Sunscreen Window arc

* Color tokens: WHO palette plus accessibility overlays, dark/light variants

* Haptic map: scrub tick, high‑UV enter, SPF apply/remove

* Widget renders: Small/Medium/Large, light/dark, inside/outside window states

* Icons: weather conditions, location status chip, SPF chip and remove

QA fixtures

* Unit tests: per skin type (I–VI), SPF {None, 15, 30, 50}, quantity {Low, Medium, Lots}, activity {indoors, normal, active}, water event toggle; verify BT monotonicity and clamps

### Integration Points

* WeatherKit, OpenWeatherMap, or Tomorrow.io APIs for UV index and forecast data

* Apple HealthKit integration potential for future sun exposure tracking features

* App Store Connect for app distribution, analytics, and cross-promotion capabilities

* RevenueCat SDK integration for future subscription and monetization features

* PostHog or similar analytics platform for privacy-compliant usage tracking

* Crash reporting service (Crashlytics) for stability monitoring and debugging

* TestFlight for beta testing and feature validation with target user groups

### Data Storage & Privacy

* All user data stored locally on device with no cloud synchronization required

* Location data used only for weather API requests, never stored or transmitted to own servers

* Skin profile and preferences encrypted and stored in device Keychain

* Anonymous usage analytics with no personally identifiable information collection

* Weather data cached locally for offline functionality and reduced API costs

* User notification preferences and quiet hours stored locally with system integration

* No user accounts, emails, or registration required - completely anonymous usage model

### Scalability & Performance

* Weather API costs scale linearly with active user base - budget $5,000/month at 100k MAU

* Client-side caching reduces API calls to 1-2 requests per user per day average

* Widget refresh optimization prevents excessive background data usage

* Efficient Core Data queries and background processing for smooth user experience

* CDN integration for educational content and app assets to reduce latency globally

* Horizontal scaling architecture ready for 1M+ users without major changes

### Potential Challenges

* Weather API rate limiting and cost management at scale requires intelligent caching strategy

* Apple Watch battery optimization while maintaining timely UV data updates

* iOS background refresh limitations may affect notification timing accuracy

* Communicating health-adjacent estimates responsibly: include disclaimers and avoid implying medical certainty; provide conservative bounds and caps

* International expansion requires localized weather data sources and cultural adaptation

* Competition with built-in Weather app features requires clear differentiation value

* Seasonal usage patterns in different hemispheres may impact retention metrics significantly

---

## Milestones & Sequencing

### Project Estimate

Medium: 4–6 weeks for MVP encompassing iOS app, basic widgets, and watchOS companion with core UV functionality

### Team Size & Composition

Small Team: 2 total people

* 1 iOS Developer/Engineer: Full-stack mobile development, API integration, widget implementation

* 1 Product Designer/Manager: UI/UX design, user research, product strategy, and project coordination

### Suggested Phases

**Phase 1: Core Foundation** (2 weeks)

* Key Deliverables: iOS Developer creates basic iOS app with weather API integration, location services, and main UV dashboard; Designer delivers app wireframes, visual design system, and user onboarding flow

* Dependencies: Weather API provider selection and account setup, App Store developer account configuration

**Phase 2: Personalization & Widgets** (2 weeks)

* Key Deliverables: iOS Developer implements skin profile system, burn time calculations, and home screen widgets; Designer creates widget designs, skin type selection interface, and notification templates

* Dependencies: Core app foundation completed, widget design specifications finalized

**Phase 3: watchOS & Polish** (1-2 weeks)

* Key Deliverables: iOS Developer builds Apple Watch companion app and complications; Designer refines user experience, creates App Store assets, and conducts final usability testing

* Dependencies: iOS app core functionality stable, Apple Watch development environment configured

**Phase 4: Launch Preparation** (1 week)

* Key Deliverables: Both team members collaborate on App Store submission, analytics implementation, beta testing coordination, and launch strategy execution

* Dependencies: App Store review guidelines compliance, TestFlight beta testing completed successfully