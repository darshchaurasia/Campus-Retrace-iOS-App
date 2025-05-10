//
// Utilities/LocationManager.swift
//  LostFoundApp
//
//  Created by Darsh Chaurasia on 4/20/25.
//

import Foundation
import CoreLocation
import Combine

final class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    // Strong reference to location manager to prevent deallocation
    private let manager: CLLocationManager
    
    // Status property to track authorization status
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    // Published property for location with proper memory management
    @Published private(set) var location: CLLocationCoordinate2D?
    
    // Published property to track if there are any errors
    @Published var locationError: Error?
    
    // Property to track whether we're currently updating location
    private(set) var isUpdatingLocation = false
    
    override init() {
        self.manager = CLLocationManager()
        super.init()
        self.setupLocationManager()
    }
    
    private func setupLocationManager() {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
        
        // Request authorization if needed
        if authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if authorizationStatus == .authorizedWhenInUse || 
                  authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
            isUpdatingLocation = true
        }
    }
    
    // Method to manually request location updates
    func requestLocation() {
        if authorizationStatus == .authorizedWhenInUse || 
           authorizationStatus == .authorizedAlways {
            manager.requestLocation() // Request a one-time location update
        } else if authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }
    
    // Method to start continuous location updates
    func startUpdatingLocation() {
        if authorizationStatus == .authorizedWhenInUse || 
           authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
            isUpdatingLocation = true
        }
    }
    
    // Method to stop location updates
    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
        isUpdatingLocation = false
    }
    
    // MARK: - CLLocationManagerDelegate methods
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.last else { return }
        
        // Check if the location is valid (not 0,0 and recent)
        let howRecent = latestLocation.timestamp.timeIntervalSinceNow
        guard abs(howRecent) < 15 && 
              latestLocation.coordinate.latitude != 0 && 
              latestLocation.coordinate.longitude != 0 else { 
            return 
        }
        
        // Update the published location property on the main thread
        DispatchQueue.main.async { [weak self] in
            self?.location = latestLocation.coordinate
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Handle location errors
        DispatchQueue.main.async { [weak self] in
            self?.locationError = error
            print("Location error: \(error.localizedDescription)")
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.authorizationStatus = manager.authorizationStatus
            
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                // Start updating location if authorized
                manager.startUpdatingLocation()
                self.isUpdatingLocation = true
            case .denied, .restricted:
                // Stop updating location if denied
                manager.stopUpdatingLocation()
                self.isUpdatingLocation = false
                self.location = nil
            default:
                break
            }
        }
    }
}
