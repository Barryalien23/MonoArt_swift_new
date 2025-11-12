//
//  MonoArtApp.swift
//  MonoArt
//
//  Created by Александр Ращектаев on 07.11.2025.
//

import SwiftUI
import AsciiCameraKit
import AsciiUI

@main
struct MonoArtApp: App {
    init() {
        DesignSystem.bootstrap()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
