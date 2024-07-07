//
//  GradekeeperApp.swift
//  Shared
//
//  Created by Jackson Rakena on 10/08/22.
//

import SwiftUI
import GoogleSignIn

@main
struct GradekeeperApp: App {
    let persistenceController = PersistenceController.shared

    var network = Network()
    var body: some Scene {
        
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(network)
                .onOpenURL(perform: { url in
                    GIDSignIn.sharedInstance.handle(url)
                })
        }
    }
}
