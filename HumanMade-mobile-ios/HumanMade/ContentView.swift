//
//  ContentView.swift
//  HumanMade
//
//  Created by unique on 01/05/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var photoStore = CapturedPhotoStore()

    var body: some View {
        TabView {
            Tab("Verify", systemImage: "shield.lefthalf.filled") {
                VerifyView()
            }

            Tab("Photos", systemImage: "photo.on.rectangle.angled") {
                PhotosView(photoStore: photoStore)
            }

            Tab("Camera", systemImage: "camera.viewfinder", role:.search) {
                CameraView(photoStore: photoStore)
            }
        }
        .tint(Color(.systemGreen))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
