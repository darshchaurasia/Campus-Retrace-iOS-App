//
//  ItemFormView.swift
//  LostFoundApp
//
//  Created by Darsh Chaurasia on 4/20/25.
//

import SwiftUI
import PhotosUI
import MapKit
import CoreLocation
import SwiftData

struct ItemFormView: View {
    // --------------------------------------------------------------------
    // MARK: – New vs. Edit
    // --------------------------------------------------------------------

    private let itemToEdit: LostFoundItem?   // nil → create, non-nil → edit

    init(item: LostFoundItem? = nil) {
        self.itemToEdit = item

        _title  = State(initialValue: item?.title ?? "")
        _detail = State(initialValue: item?.detail ?? "")
        _status = State(initialValue: item?.status ?? .lost)

        _imageURL = State(initialValue: item?.imageURL ?? "")

        if let coord = item?.coordinate {
            _selectedCoordinate = State(initialValue: coord)
        }
    }

    // --------------------------------------------------------------------
    // MARK: – Environment / State
    // --------------------------------------------------------------------

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @StateObject private var locMan = LocationManager()

    @State private var title  = ""
    @State private var detail = ""
    @State private var status: LostFoundItem.Status = .lost

    @State private var pickerItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var imageURL = ""

    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var showLocationPicker = false

    @State private var isLoading    = false
    @State private var imageData    = Data()
    @State private var showImageErr = false
    @State private var errMessage   = ""

    // --------------------------------------------------------------------
    // MARK: – Body
    // --------------------------------------------------------------------

    var body: some View {
        NavigationStack {
            ZStack {
                formContents
                if isLoading { loadingOverlay }
            }
            .navigationTitle(itemToEdit == nil ? "New Item" : "Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarButtons }
            .onChange(of: pickerItem) { _ in loadImage() }
            .sheet(isPresented: $showLocationPicker) { locationPickerSheet }
            .alert("Image Error", isPresented: $showImageErr) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errMessage)
            }
        }
    }

    // --------------------------------------------------------------------
    // MARK: – Form contents
    // --------------------------------------------------------------------

    private var formContents: some View {
        Form {
            // ------------------ Item Details --------------------------
            Section(header: Text("Item Details").font(.headline)) {
                TextField("Title", text: $title)
                    .padding(.vertical, 8)

                TextField("Description", text: $detail, axis: .vertical)
                    .lineLimit(3...)
                    .padding(.vertical, 8)

                Picker("Status", selection: $status) {
                    ForEach(LostFoundItem.Status.allCases, id: \.self) {
                        Label($0.rawValue.capitalized,
                              systemImage: $0 == .lost ? "magnifyingglass.circle.fill"
                                        : $0 == .found ? "checkmark.circle.fill"
                                        : "arrow.triangle.2.circlepath")
                    }
                }
                .pickerStyle(.menu)
                .padding(.vertical, 8)
            }

            // ------------------ Image -------------------------------
            Section(header: Text("Image").font(.headline)) {
                VStack {
                    if let selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(8)
                    } else if !imageURL.isEmpty,
                              let url = URL(string: imageURL) {
                        // show existing image (edit mode)
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty: ProgressView()
                            case .success(let img):
                                img.resizable().scaledToFit()
                            default:
                                Image(systemName: "photo.slash")
                                    .resizable().scaledToFit()
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(maxHeight: 200)
                        .cornerRadius(8)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 150)
                            .cornerRadius(8)
                            .overlay(
                                VStack {
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                    Text("Select an image")
                                        .font(.headline)
                                }
                            )
                    }

                    PhotosPicker(selection: $pickerItem,
                                 matching: .images,
                                 photoLibrary: .shared()) {
                        Label("Select Image", systemImage: "photo.badge.plus")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.blue.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding(.vertical, 8)
            }

            // ------------------ Location ----------------------------
            Section(header: Text("Location").font(.headline)) {
                VStack {
                    if let coord = selectedCoordinate {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                            Text("Location selected")
                                .font(.headline)
                            Spacer()
                            Button("Change") { showLocationPicker = true }
                                .foregroundColor(.blue)
                        }

                        Map(position: .constant(
                                MapCameraPosition.region(
                                    MKCoordinateRegion(center: coord,
                                                       span: .init(latitudeDelta: 0.01,
                                                                   longitudeDelta: 0.01))
                                )
                            )) {
                            Marker("Selected", coordinate: coord)
                        }
                        .frame(height: 150)
                        .cornerRadius(8)
                        .disabled(true)
                        .padding(.top, 8)

                    } else {
                        Button {
                            showLocationPicker = true
                        } label: {
                            Label("Choose Location on Map", systemImage: "map")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.green.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }

                        Button {
                            if let loc = locMan.location {
                                selectedCoordinate = loc
                            }
                        } label: {
                            Label("Use Current Location", systemImage: "location.fill")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.indigo.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(locMan.location == nil)
                        .padding(.top, 8)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    // --------------------------------------------------------------------
    // MARK: – Toolbar
    // --------------------------------------------------------------------

    @ToolbarContentBuilder
    private var toolbarButtons: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button("Save") {
                isLoading = true
                save()
            }
            .disabled(title.isEmpty || imageURL.isEmpty ||
                      (selectedCoordinate == nil && itemToEdit == nil))
        }
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
        }
    }

    // --------------------------------------------------------------------
    // MARK: – Save (create & update)
    // --------------------------------------------------------------------

    private func save() {
        if let item = itemToEdit {
            updateExisting(item)
        } else {
            createNewItem()
        }
    }

    private func updateExisting(_ item: LostFoundItem) {
        // ---- local update ------------------------------------------------
        item.title    = title
        item.detail   = detail
        item.status   = status
        item.imageURL = imageURL
        if let coord = selectedCoordinate {
            item.latitude  = coord.latitude
            item.longitude = coord.longitude
        }
        try? context.save()

        // ---- remote update (PUT) ----------------------------------------
        if let serverID = numericID(from: item.id) {
            Task {
                let dto = ItemDTO(id:        serverID,
                                  title:     item.title,
                                  detail:    item.detail,
                                  imageURL:  item.imageURL,
                                  latitude:  item.latitude,
                                  longitude: item.longitude,
                                  status:    item.status.rawValue,
                                  date:      item.date)
                try? await APIService.shared.updateItem(id: serverID, with: dto)
                await MainActor.run { isLoading = false; dismiss() }
            }
        } else {
            // item never uploaded → treat as new
            createNewItem()
        }
    }

    private func createNewItem() {
        guard let coord = selectedCoordinate else { return }

        // ---- local insert ----------------------------------------------
        let item = LostFoundItem(title: title,
                                 detail: detail,
                                 imageURL: imageURL,
                                 latitude: coord.latitude,
                                 longitude: coord.longitude,
                                 status: status)
        context.insert(item)

        // ---- remote insert (POST) --------------------------------------
        Task {
            let dto = ItemDTO(id: nil,
                              title:     item.title,
                              detail:    item.detail,
                              imageURL:  item.imageURL,
                              latitude:  item.latitude,
                              longitude: item.longitude,
                              status:    item.status.rawValue,
                              date:      item.date)

            try? await APIService.shared.postItem(dto)

            await MainActor.run { isLoading = false; dismiss() }
        }
    }

    // --------------------------------------------------------------------
    // MARK: – Helpers
    // --------------------------------------------------------------------

    /// Converts the synthetic UUID (00000000-0000-0000-0000-XXXXXXXXXXXX) back
    /// to MockAPI’s numeric id string.
    private func numericID(from uuid: UUID) -> String? {
        let tail = uuid.uuidString.replacingOccurrences(of: "-", with: "")
                                  .suffix(12)          // last 12 hex chars
        guard let num = UInt64(tail, radix: 16) else { return nil }
        return String(num)                             // "1", "42", …
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            ProgressView("Saving…")
                .padding()
                .background(RoundedRectangle(cornerRadius: 10)
                               .fill(.ultraThinMaterial))
        }
    }

    // --------------- location picker sheet -------------------------------

    private var locationPickerSheet: some View {
        NavigationStack {
            MapScreen(selectedLocationParam: selectedCoordinate) { coord in
                selectedCoordinate = coord
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showLocationPicker = false }
                }
            }
        }
    }

    // --------------- image handling (unchanged from your version) ---------

    private func loadImage() {
        guard let picker = pickerItem else { return }

        Task { @MainActor in
            isLoading = true
            do {
                let data = try await picker.loadTransferable(type: Data.self)
                guard let data else { throw URLError(.badURL) }
                self.imageData = data
                guard let uiImage = UIImage(data: data) else {
                    throw URLError(.cannotDecodeContentData)
                }
                let resized = resizeImage(uiImage,
                                          targetSize: CGSize(width: 1000,
                                                             height: 1000))
                selectedImage = resized
                // In a real app, upload & assign URL here
                imageURL = "https://example.com/img/\(UUID().uuidString).jpg"
            } catch {
                errMessage = "Error loading image: \(error.localizedDescription)"
                showImageErr = true
            }
            isLoading = false
        }
    }

    private func resizeImage(_ img: UIImage, targetSize: CGSize) -> UIImage {
        let ratio = min(targetSize.width / img.size.width,
                        targetSize.height / img.size.height)
        let newSize = CGSize(width: img.size.width * ratio,
                             height: img.size.height * ratio)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1)
        img.draw(in: .init(origin: .zero, size: newSize))
        defer { UIGraphicsEndImageContext() }
        return UIGraphicsGetImageFromCurrentImageContext() ?? img
    }
}

// ------------------------------------------------------------------------
// MARK: – Preview
// ------------------------------------------------------------------------

#Preview {
    ItemFormView()
}
