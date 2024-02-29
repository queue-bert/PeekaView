//
//  PeekaViewApp.swift
//  PeekaView
//
//  Created by Devon Quispe on 2/29/24.
//

import SwiftUI

@main
struct PeekaViewApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
