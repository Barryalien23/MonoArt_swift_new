//
//  ContentView.swift
//  MonoArt
//
//  Created by Александр Ращектаев on 07.11.2025.
//

import SwiftUI
import AsciiCameraKit
import AsciiUI

struct ContentView: View {
    @State private var isLaunchScreenVisible = true

    var body: some View {
        ZStack {
            if isLaunchScreenVisible {
                LaunchScreenView()
            } else {
                AsciiCameraExperience()
            }
        }
        .onAppear {
            // Hide launch screen after a short delay to allow app initialization
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isLaunchScreenVisible = false
            }
        }
    }
}

private struct UnsupportedVersionView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
            Text("MonoArt requires iOS 16 or newer")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.9))
        .foregroundStyle(.white)
    }
}

#Preview("ASCII Camera Experience") {
    if #available(iOS 16.0, *) {
        AsciiCameraExperience(
            viewModel: AppViewModel(previewStatus: .running, previewFrame: PreviewFrame(
                id: UUID(),
                glyphText: "▒░▒░▒░\n░▒░▒░▒\n▒░▒░▒░",
                columns: 6,
                rows: 3,
                renderedEffect: .ascii
            )),
            engineFactory: { StubAsciiEngine() },
            cameraFactory: { StubCameraService() },
            mediaCoordinatorFactory: { InMemoryMediaCoordinator() },
            frameRendererFactory: { AsciiFrameRenderer() }
        )
    } else {
        UnsupportedVersionView()
    }
}
