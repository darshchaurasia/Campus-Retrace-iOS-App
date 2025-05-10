//
//  ItemListViewModel.swift
//  LostFoundApp
//
//  Created by Darsh Chaurasia on 4/20/25.
//

import Foundation
import SwiftData

@MainActor
final class ItemListViewModel: ObservableObject {

    /// Pulls from the API and upserts into the local store, deleting rows
    /// that no longer exist on the server.
    func syncRemote(context: ModelContext) async {
        do {
            let dtos = try await APIService.shared.fetchItems()

            var existing = try context
                .fetch(FetchDescriptor<LostFoundItem>())
                .reduce(into: [UUID: LostFoundItem]()) { $0[$1.id] = $1 }

            var seen = Set<UUID>()

            // UPSERT
            for dto in dtos {
                guard let idString = dto.id else { continue }
                let uuid = stableUUID(from: idString)
                seen.insert(uuid)

                if let item = existing[uuid] {
                    update(item, with: dto)
                } else {
                    context.insert(makeItem(from: dto, id: uuid))
                }
            }

            // PRUNE (optional – comment out if undesired)
            for (uuid, item) in existing where !seen.contains(uuid) {
                context.delete(item)
            }

            try context.save()
        } catch {
            print("🔴 Sync error:", error)
        }
    }

    // MARK: – Upsert helpers ---------------------------------------------

    private func update(_ item: LostFoundItem, with dto: ItemDTO) {
        item.title     = dto.title
        item.detail    = dto.detail
        item.imageURL  = dto.imageURL
        item.latitude  = dto.latitude
        item.longitude = dto.longitude
        item.status    = .init(rawValue: dto.status) ?? .lost
        item.date      = dto.date
    }

    private func makeItem(from dto: ItemDTO, id: UUID) -> LostFoundItem {
        LostFoundItem(id: id,
                      title:     dto.title,
                      detail:    dto.detail,
                      imageURL:  dto.imageURL,
                      latitude:  dto.latitude,
                      longitude: dto.longitude,
                      status:    .init(rawValue: dto.status) ?? .lost,
                      date:      dto.date)
    }

    // MARK: – Deterministic UUID converter -------------------------------

    private func stableUUID(from idString: String) -> UUID {
        if let real = UUID(uuidString: idString) { return real }

        let num   = UInt64(idString) ?? 0
        let hex12 = String(format: "%012llx", num)
        let text  = "00000000-0000-0000-0000-\(hex12)"
        return UUID(uuidString: text)!
    }
}
