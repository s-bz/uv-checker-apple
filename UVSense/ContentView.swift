//
//  ContentView.swift
//  UV Sense
//
//  Created by Samuel Bultez on 18/9/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        DashboardView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            Item.self,
            UVData.self,
            HourlyUVData.self,
            SkinProfile.self,
            SunscreenApplication.self,
            LocationData.self
        ], inMemory: true)
}
