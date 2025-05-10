//
// Models/LostFoundItem.swift
//  LostFoundApp
//
//  Created by Darsh Chaurasia on 4/20/25.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class LostFoundItem: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var detail: String
    var imageURL: String
    var latitude: Double
    var longitude: Double
    var status: Status
    var date: Date
    
    enum Status: String, Codable, CaseIterable {
        case lost, found, returned
    }
    
    init(id: UUID = .init(),
         title: String,
         detail: String,
         imageURL: String,
         latitude: Double,
         longitude: Double,
         status: Status,
         date: Date = .now) {
        self.id = id
        self.title = title
        self.detail = detail
        self.imageURL = imageURL
        self.latitude = latitude
        self.longitude = longitude
        self.status = status
        self.date = date
    }
    
    var coordinate: CLLocationCoordinate2D {
        .init(latitude: latitude, longitude: longitude)
    }
}
