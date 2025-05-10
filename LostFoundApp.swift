//
//  LostFoundApp.swift
//  LostFoundApp
//
//  Created by Darsh Chaurasia on 4/20/25.
//

// LostFoundApp.swift
import SwiftUI
import SwiftData

@main
struct LostFoundApp: App {
    var body: some Scene {
        WindowGroup {
            ItemListView()
                .modelContainer(for: LostFoundItem.self)
        }
    }
}
