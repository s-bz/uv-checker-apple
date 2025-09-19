//
//  WidgetBundle.swift
//  Widget
//
//  Created by Samuel Bultez on 19/9/2025.
//

import WidgetKit
import SwiftUI

@main
struct UVSenseWidgets: WidgetBundle {
    var body: some Widget {
        UVWidget()
        // Comment out control and live activity for now as they need separate implementation
        // WidgetControl()
        // WidgetLiveActivity()
    }
}