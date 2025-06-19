//
//  ContentView.swift
//  DriveSafe
//
//  Created by Gurkirt Singh on 2025-06-15.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView{
            Tab("Scan", systemImage: "wrench"){
                ScanTroubleCodeView()
            }
        }
    }
}

#Preview {
    ContentView()
}
