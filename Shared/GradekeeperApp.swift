//
//  GradekeeperApp.swift
//  Shared
//
//  Created by Jackson Rakena on 10/08/22.
//

import SwiftUI

@main
struct GradekeeperApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
