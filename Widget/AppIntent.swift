//
//  AppIntent.swift
//  Widget
//
//  Created by Samuel Bultez on 19/9/2025.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "UV Index Widget" }
    static var description: IntentDescription { "Shows current UV index and sun protection recommendations" }
    
    // Show burn time calculation
    @Parameter(title: "Show Burn Time", default: true)
    var showBurnTime: Bool
    
    // Show sunscreen status
    @Parameter(title: "Show Sunscreen Status", default: true)
    var showSunscreenStatus: Bool
}