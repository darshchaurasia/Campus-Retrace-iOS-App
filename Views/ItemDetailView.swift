//
//  ItemDetailView.swift
//  LostFoundApp
//
//  Created by Darsh Chaurasia on 4/20/25.
//

import SwiftUI
import MapKit

struct ItemDetailView: View {
    // ----------------------------------------------------------------
    // MARK: – Init & State
    // ----------------------------------------------------------------

    let item: LostFoundItem

    @State private var mapPosition: MapCameraPosition
    @State private var showFullScreenMap = false
    @State private var showEdit         = false
    @State private var showDeleteAlert  = false

    @Environment(\.dismiss) private var dismiss

    init(item: LostFoundItem) {
        self.item = item
        _mapPosition = State(initialValue: .region(.init(
            center: item.coordinate,
            span: .init(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )))
    }

    // ----------------------------------------------------------------
    // MARK: – Body
    // ----------------------------------------------------------------

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerImage
                itemDetails
            }
            .padding(.bottom, 16)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .alert("Delete Item?",
               isPresented: $showDeleteAlert,
               actions: {
                   Button("Delete", role: .destructive) {
                       Task { await deleteItemAndDismiss() }
                   }
                   Button("Cancel", role: .cancel) {}
               },
               message: { Text("This action cannot be undone.") })
        .fullScreenCover(isPresented: $showFullScreenMap) { fullScreenMap }
        .sheet(isPresented: $showEdit) { ItemFormView(item: item) }
    }

    // ----------------------------------------------------------------
    // MARK: – Toolbar
    // ----------------------------------------------------------------

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            HStack {
                Image(systemName: item.status == .lost
                                   ? "magnifyingglass.circle.fill"
                                   : "checkmark.circle.fill")
                    .foregroundStyle(item.status == .lost ? .red : .green)
                Text(item.status == .lost ? "Lost Item" : "Found Item")
                    .font(.headline)
            }
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
            Button { showEdit = true }   label: { Image(systemName: "pencil") }
            Button(role: .destructive) { showDeleteAlert = true }
                   label: { Image(systemName: "trash") }
            Button { /* share */ }       label: { Image(systemName: "square.and.arrow.up") }
        }
    }

    // ----------------------------------------------------------------
    // MARK: – Header image
    // ----------------------------------------------------------------

    private var headerImage: some View {
        ZStack(alignment: .topTrailing) {
            AsyncImage(url: URL(string: item.imageURL)) { phase in
                switch phase {
                case .empty:
                    Rectangle().fill(Color.gray.opacity(0.2))
                               .overlay(ProgressView())
                case .success(let img):
                    img.resizable().aspectRatio(contentMode: .fill)
                case .failure:
                    Rectangle().fill(Color.gray.opacity(0.2))
                               .overlay(Image(systemName: "photo.slash")
                                        .font(.largeTitle))
                @unknown default: EmptyView()
                }
            }
            .frame(height: 250)
            .clipped()
            .cornerRadius(12)

            StatusBadge(status: item.status)
                .padding([.top, .trailing], 12)
        }
        .shadow(radius: 3)
        .padding(.horizontal)
    }

    // ----------------------------------------------------------------
    // MARK: – Details section
    // ----------------------------------------------------------------

    private var itemDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title & description
            Group {
                Text(item.title).font(.largeTitle)
                                 .fontWeight(.bold)
                                 .lineLimit(2)

                Divider()

                Label("Added on \(formattedDate)",
                      systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(item.detail).font(.body).padding(.vertical, 8)
            }
            .padding(.horizontal)

            locationSection
            contactButtons
        }
    }

    // ----------------------------------------------------------------
    // MARK: – Location section
    // ----------------------------------------------------------------

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Location", systemImage: "mappin.circle.fill")
                .font(.headline)
                .padding(.horizontal)

            ZStack(alignment: .bottomTrailing) {
                Map(position: $mapPosition) {
                    Annotation(item.title, coordinate: item.coordinate) {
                        Image(systemName: item.status == .lost
                                           ? "magnifyingglass.circle.fill"
                                           : "checkmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(item.status == .lost ? .red : .green)
                            .background(Circle().fill(.white.opacity(0.7)))
                            .shadow(radius: 2)
                    }
                }
                .frame(height: 250)
                .cornerRadius(12)
                .shadow(radius: 3)
                .padding(.horizontal)

                Button { showFullScreenMap = true } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.title3)
                        .padding(8)
                        .background(Circle().fill(.ultraThinMaterial))
                }
                .padding(20)
            }
        }
    }

    // ----------------------------------------------------------------
    // MARK: – Contact buttons
    // ----------------------------------------------------------------

    private var contactButtons: some View {
        VStack(spacing: 12) {
            Button { /* contact action */ } label: {
                Label("Contact", systemImage: "message.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue))
                    .foregroundColor(.white)
            }

            if item.status == .found {
                Button { /* claim action */ } label: {
                    Label("Claim as Mine", systemImage: "hand.raised.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.green))
                        .foregroundColor(.white)
                }
            }
        }
        .padding()
    }

    // ----------------------------------------------------------------
    // MARK: – Full-screen map
    // ----------------------------------------------------------------

    private var fullScreenMap: some View {
        NavigationStack {
            Map(position: $mapPosition) {
                Annotation(item.title, coordinate: item.coordinate) {
                    Image(systemName: item.status == .lost
                                       ? "magnifyingglass.circle.fill"
                                       : "checkmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(item.status == .lost ? .red : .green)
                        .background(Circle().fill(.white.opacity(0.7)))
                        .shadow(radius: 2)
                }
            }
            .mapControls { MapCompass(); MapPitchToggle(); MapUserLocationButton(); MapScaleView() }
            .navigationTitle("Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showFullScreenMap = false }
                }
            }
        }
    }

    // ----------------------------------------------------------------
    // MARK: – Delete helper
    // ----------------------------------------------------------------

    @MainActor
    private func deleteItemAndDismiss() async {
        if let ctx = item.modelContext { ctx.delete(item) }
        try? item.modelContext?.save()

        if let serverID = numericID(from: item.id) {
            try? await APIService.shared.deleteItem(id: serverID)
        }
        dismiss()
    }

    private func numericID(from uuid: UUID) -> String? {
        let tail = uuid.uuidString.replacingOccurrences(of: "-", with: "")
                                  .suffix(12)
        guard let n = UInt64(tail, radix: 16) else { return nil }
        return String(n)
    }

    // ----------------------------------------------------------------
    // MARK: – Helpers
    // ----------------------------------------------------------------

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: item.date)
    }
}

// --------------------------------------------------------------------
// MARK: – Status badge
// --------------------------------------------------------------------

struct StatusBadge: View {
    let status: LostFoundItem.Status
    var body: some View {
        HStack {
            Image(systemName: status == .lost
                              ? "magnifyingglass.circle.fill"
                              : status == .found
                                ? "checkmark.circle.fill"
                                : "arrow.triangle.2.circlepath")
            Text(status.rawValue.capitalized).fontWeight(.bold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(status == .lost ? Color.red.opacity(0.9)
                             : status == .found ? Color.green.opacity(0.9)
                             : Color.blue.opacity(0.9))
        )
        .foregroundColor(.white)
    }
}

// --------------------------------------------------------------------
// MARK: – Preview
// --------------------------------------------------------------------

#Preview {
    NavigationStack {
        ItemDetailView(item: LostFoundItem(
            title: "Preview Item",
            detail: "Sample description",
            imageURL: "https://picsum.photos/400",
            latitude: 37.7749,
            longitude: -122.4194,
            status: .lost
        ))
    }
}
