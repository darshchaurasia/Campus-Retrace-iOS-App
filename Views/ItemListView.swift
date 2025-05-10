//
//  ItemListView.swift
//  LostFoundApp
//
//  Created by Darsh Chaurasia on 4/20/25.
//

import SwiftUI
import SwiftData
import MapKit

struct ItemListView: View {
    // -------------------------------------------------------------------
    // MARK: – Environment / State
    // -------------------------------------------------------------------

    @Environment(\.modelContext) private var context
    @Query var items: [LostFoundItem]

    @State private var showAdd          = false
    @State private var searchText       = ""
    @State private var selectedFilter: LostFoundItem.Status? = nil
    @State private var viewMode: ViewMode = .list
    @State private var mapPosition      = MapCameraPosition.automatic
    @State private var isRefreshing     = false

    @StateObject private var vm = ItemListViewModel()

    enum ViewMode { case list, grid, map }

    // -------------------------------------------------------------------
    // MARK: – Filtered list
    // -------------------------------------------------------------------

    private var filteredItems: [LostFoundItem] {
        items.filter { item in
            let matchesSearch = searchText.isEmpty ||
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.detail.localizedCaseInsensitiveContains(searchText)

            let matchesFilter = selectedFilter == nil || item.status == selectedFilter
            return matchesSearch && matchesFilter
        }
    }

    // -------------------------------------------------------------------
    // MARK: – Body
    // -------------------------------------------------------------------

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchHeader
                filterPills
                viewModePicker

                ZStack {
                    switch viewMode {
                    case .list: listView
                    case .grid: gridView
                    case .map : mapView
                    }

                    if filteredItems.isEmpty { emptyState }
                }
            }
            .navigationTitle("Lost & Found")
            .toolbar { navBarButtons }
            .toolbarBackground(.visible, for: .navigationBar)
            .task { await vm.syncRemote(context: context) }
            .sheet(isPresented: $showAdd) { ItemFormView() }
        }
    }

    // -------------------------------------------------------------------
    // MARK: – UI Sections
    // -------------------------------------------------------------------

    private var searchHeader: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.gray)
            TextField("Search", text: $searchText).autocapitalization(.none)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
        .padding(.horizontal)
    }

    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                FilterPill(title: "All",
                           isSelected: selectedFilter == nil,
                           color: .blue) { selectedFilter = nil }

                FilterPill(title: "Lost",
                           isSelected: selectedFilter == .lost,
                           color: .red) { selectedFilter = .lost }

                FilterPill(title: "Found",
                           isSelected: selectedFilter == .found,
                           color: .green) { selectedFilter = .found }

                FilterPill(title: "Returned",
                           isSelected: selectedFilter == .returned,
                           color: .orange) { selectedFilter = .returned }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }

    private var viewModePicker: some View {
        Picker("View Mode", selection: $viewMode) {
            Image(systemName: "list.bullet").tag(ViewMode.list)
            Image(systemName: "square.grid.2x2").tag(ViewMode.grid)
            Image(systemName: "map").tag(ViewMode.map)
        }
        .pickerStyle(.segmented)
        .padding([.horizontal, .bottom])
    }

    // -------------------- List view with swipe-to-delete ---------------
    private var listView: some View {
        List {
            ForEach(filteredItems) { item in
                NavigationLink(destination: ItemDetailView(item: item)) {
                    listRow(for: item)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        Task { await delete(item) }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    // Row cell
    private func listRow(for item: LostFoundItem) -> some View {
        HStack(spacing: 15) {
            AsyncImage(url: URL(string: item.imageURL)) { phase in
                switch phase {
                case .empty:
                    Rectangle().fill(Color.gray.opacity(0.3))
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                case .failure:
                    Rectangle().fill(Color.gray.opacity(0.3))
                               .overlay(Image(systemName: "photo.slash"))
                @unknown default: EmptyView()
                }
            }
            .frame(width: 70, height: 70)
            .cornerRadius(8)
            .shadow(radius: 1)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title).font(.headline).lineLimit(1)
                Text(item.detail)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack {
                    ItemStatusBadge(status: item.status)
                    Spacer()
                    Text(formatDate(item.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // -------------------- Grid view -------------------------------------
    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()),
                                GridItem(.flexible())],
                      spacing: 16) {
                ForEach(filteredItems) { item in
                    NavigationLink(destination: ItemDetailView(item: item)) {
                        gridCard(for: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    private func gridCard(for item: LostFoundItem) -> some View {
        VStack(alignment: .leading) {
            AsyncImage(url: URL(string: item.imageURL)) { phase in
                switch phase {
                case .empty:
                    Rectangle().fill(Color.gray.opacity(0.3))
                               .aspectRatio(1, contentMode: .fill)
                               .overlay(ProgressView())
                case .success(let image):
                    image.resizable()
                         .aspectRatio(contentMode: .fill)
                         .frame(height: 120)
                         .clipped()
                case .failure:
                    Rectangle().fill(Color.gray.opacity(0.3))
                               .aspectRatio(1, contentMode: .fill)
                               .overlay(Image(systemName: "photo.slash"))
                @unknown default: EmptyView()
                }
            }
            .cornerRadius(12, corners: [.topLeft, .topRight])

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title).font(.headline).lineLimit(1)
                Text(item.detail).font(.caption)
                                 .foregroundColor(.secondary)
                                 .lineLimit(1)
                HStack {
                    ItemStatusBadge(status: item.status)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(8)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1),
                radius: 5, x: 0, y: 2)
    }

    // -------------------- Map view --------------------------------------
    private var mapView: some View {
        Map(position: $mapPosition) {
            ForEach(filteredItems) { item in
                Annotation(item.title, coordinate: item.coordinate) {
                    NavigationLink(destination: ItemDetailView(item: item)) {
                        VStack {
                            Image(systemName: item.status == .lost
                                               ? "magnifyingglass.circle.fill"
                                               : "checkmark.circle.fill")
                                .font(.title)
                                .foregroundStyle(item.status == .lost ? .red : .green)
                                .background(Circle().fill(.white.opacity(0.7)))
                                .shadow(radius: 2)

                            Text(item.title).font(.caption).fontWeight(.bold)
                                .padding(4)
                                .background(Capsule().fill(.ultraThinMaterial))
                                .shadow(radius: 1)
                        }
                    }
                }
            }
        }
        .mapControls { MapCompass(); MapUserLocationButton() }
    }

    // -------------------- Empty state -----------------------------------
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No items found").font(.headline)

            Text(selectedFilter != nil
                 ? "Try changing your filter"
                 : "Add your first item")
                .font(.subheadline)
                .foregroundColor(.gray)

            Button(action: { showAdd = true }) {
                Text("Add New Item")
                    .padding()
                    .background(Capsule().fill(.blue))
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial))
        .padding()
    }

    // -------------------- Nav bar buttons -------------------------------
    @ToolbarContentBuilder
    private var navBarButtons: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button { showAdd.toggle() } label: {
                Image(systemName: "plus").fontWeight(.semibold)
            }
        }

        ToolbarItem(placement: .topBarLeading) {
            Button {
                isRefreshing = true
                Task {
                    await vm.syncRemote(context: context)
                    isRefreshing = false
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .rotationEffect(isRefreshing ? .degrees(360) : .degrees(0))
                    .animation(isRefreshing ? .linear(duration: 1)
                               .repeatForever(autoreverses: false) : .default,
                               value: isRefreshing)
            }
        }
    }

    // -------------------- Delete helper ---------------------------------
    @MainActor
    private func delete(_ item: LostFoundItem) async {
        context.delete(item)
        try? context.save()

        if let serverID = numericID(from: item.id) {
            try? await APIService.shared.deleteItem(id: serverID)
        }
    }

    private func numericID(from uuid: UUID) -> String? {
        let tail = uuid.uuidString.replacingOccurrences(of: "-", with: "")
                                  .suffix(12)
        guard let n = UInt64(tail, radix: 16) else { return nil }
        return String(n)
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .short
        return f.string(from: date)
    }
}

// -----------------------------------------------------------------------
// MARK: – Supporting views & extensions
// -----------------------------------------------------------------------

struct ItemStatusBadge: View {
    let status: LostFoundItem.Status
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(status == .lost ? Color.red.opacity(0.2)
                               : status == .found ? Color.green.opacity(0.2)
                               : Color.blue.opacity(0.2))
            )
            .foregroundColor(status == .lost ? .red
                           : status == .found ? .green
                           : .blue)
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(isSelected ? color.opacity(0.2)
                                     : Color(.systemGray6))
                )
                .foregroundColor(isSelected ? color : .primary)
                .overlay(
                    Capsule().strokeBorder(isSelected ? color : .clear, lineWidth: 1)
                )
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let p = UIBezierPath(roundedRect: rect,
                             byRoundingCorners: corners,
                             cornerRadii: CGSize(width: radius, height: radius))
        return Path(p.cgPath)
    }
}

// -----------------------------------------------------------------------
// MARK: – Preview
// -----------------------------------------------------------------------

#Preview { ItemListView() }
