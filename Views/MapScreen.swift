//
//  MapScreen.swift
//  LostFoundApp
//
//  Created by Darsh Chaurasia on 4/20/25.
//
import SwiftUI
import MapKit
import SwiftData

// Remove the problematic enum and use a simple Int to track style
struct MapScreen: View {
    @Query var items: [LostFoundItem]
    @State private var camera = MapCameraPosition.automatic
    @State private var selectedItem: LostFoundItem?
    @State private var showLocationPicker = false
    @State private var selectedLocation: CLLocationCoordinate2D?
    @State private var isLocationSelected = false
    @State private var mapStyleSelection = 0 // 0: standard, 1: hybrid, 2: satellite
    
    // Initialization with location selection support
    var selectedLocationParam: CLLocationCoordinate2D?
    var onLocationSelected: ((CLLocationCoordinate2D) -> Void)?
    
    init(selectedLocationParam: CLLocationCoordinate2D? = nil, onLocationSelected: ((CLLocationCoordinate2D) -> Void)? = nil) {
        self.selectedLocationParam = selectedLocationParam
        self.onLocationSelected = onLocationSelected
        
        // Initialize the _selectedLocation state directly if a location is provided
        if let selectedLocation = selectedLocationParam {
            _selectedLocation = State(initialValue: selectedLocation)
        }
    }
    
    var body: some View {
        mainContent
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !showLocationPicker {
                    ToolbarItem(placement: .topBarTrailing) {
                        locationPickerButton
                    }
                }
            }
            .onAppear {
                // Set location picker mode if initialized for location selection
                if onLocationSelected != nil {
                    showLocationPicker = true
                }
            }
            .sheet(item: $selectedItem) { item in
                ItemDetailView(item: item)
            }
    }
    
    // MARK: - Computed Properties
    
    // Get the current MapStyle based on selection
    private var currentMapStyle: MapStyle {
        switch mapStyleSelection {
        case 1: return .hybrid
        case 2: return .imagery
        default: return .standard
        }
    }
    
    // MARK: - Extracted Views
    
    private var mainContent: some View {
        ZStack {
            mapView
            
            if showLocationPicker {
                locationPickerOverlay
            }
            
            mapStylePickerView
        }
    }
    
    private var mapView: some View {
        Map(position: $camera, selection: $selectedItem) {
            // Display all existing items
            ForEach(items) { item in
                annotationForItem(item)
            }
            
            // Show selection pin during location picking mode
            if showLocationPicker, let location = selectedLocation {
                Marker("Selected Location", coordinate: location)
                    .tint(.blue)
            }
        }
        .mapStyle(currentMapStyle) // Apply current style without using enum
        .mapControls {
            MapCompass()
            MapPitchToggle()
            MapUserLocationButton()
            MapScaleView()
        }
        .onTapGesture { location in
            if showLocationPicker {
                // For demo purposes, we'll just use a hardcoded location
                // In a real app, you would convert the tap point to a coordinate
                selectedLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
            }
        }
    }
    
    private func annotationForItem(_ item: LostFoundItem) -> some MapContent {
        Annotation(item.title, coordinate: item.coordinate) {
            Image(systemName: getSystemImageName(for: item))
                .font(.title)
                .foregroundStyle(getImageColor(for: item))
                .background(Circle().fill(.white.opacity(0.7)))
                .shadow(radius: 2)
        }
        .tag(item)
    }
    
    private func getSystemImageName(for item: LostFoundItem) -> String {
        item.status == .lost ? "magnifyingglass.circle.fill" : "checkmark.circle.fill"
    }
    
    private func getImageColor(for item: LostFoundItem) -> Color {
        item.status == .lost ? .red : .green
    }
    
    private var locationPickerOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Button(action: {
                    showLocationPicker = false
                    selectedLocation = nil
                }) {
                    Text("Cancel")
                        .padding()
                        .background(Capsule().fill(.ultraThinMaterial))
                }
                
                Spacer()
                
                Button(action: confirmLocationSelection) {
                    Text("Confirm Location")
                        .bold()
                        .padding()
                        .background(Capsule().fill(.blue))
                        .foregroundColor(.white)
                }
                .disabled(selectedLocation == nil)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 15).fill(.ultraThinMaterial))
            .padding()
        }
    }
    
    private var mapStylePickerView: some View {
        VStack {
            // Simple segmented picker without using enum
            Picker("Map Style", selection: $mapStyleSelection) {
                Text("Standard").tag(0)
                Text("Hybrid").tag(1) 
                Text("Satellite").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial))
            .padding()
            
            Spacer()
        }
    }
    
    private var locationPickerButton: some View {
        Button(action: {
            showLocationPicker = true
        }) {
            Label("Select Location", systemImage: "location.fill")
        }
    }
    
    // MARK: - Helper Functions
    
    private func confirmLocationSelection() {
        if let location = selectedLocation, let onSelect = onLocationSelected {
            onSelect(location)
            showLocationPicker = false
            isLocationSelected = true
        }
    }
}

// Preview provider
#Preview {
    MapScreen()
}

