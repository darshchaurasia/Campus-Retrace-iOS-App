//  APIService.swift
//  LostFoundApp
//
//  Created by Darsh Chaurasia on 4/20/25.
//

import Foundation

// MARK: – DTO ----------------------------------------------------------------

struct ItemDTO: Codable {
    var id: String?                 // nil on POST ⇒ MockAPI assigns one
    let title: String
    let detail: String
    let imageURL: String
    let latitude: Double
    let longitude: Double
    let status: String
    let date: Date
}

// MARK: – Service ------------------------------------------------------------

struct APIService {
    static let shared = APIService()
    private let base: URL = {
        guard let urlString = Bundle.main.infoDictionary?["API_BASE_URL"] as? String, let url = URL(string: urlString) else {
            fatalError("Missing or invalid API_BASE_URL in Info.plist")
        }
        return url
    }()

    // GET /items ---------------------------------------------------------
    func fetchItems() async throws -> [ItemDTO] {
        let (data, _) = try await URLSession.shared.data(from: base)
        return try decoder().decode([ItemDTO].self, from: data)
    }

    // POST /items --------------------------------------------------------
    @discardableResult
    func postItem(_ dto: ItemDTO) async throws -> ItemDTO {
        var req = URLRequest(url: base)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try encoder().encode(dto)

        let (data, _) = try await URLSession.shared.data(for: req)
        return try decoder().decode(ItemDTO.self, from: data)
    }

    // PUT /items/:id -----------------------------------------------------
    func updateItem(id: String, with dto: ItemDTO) async throws {
        let url = base.appendingPathComponent(id)
        var req  = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try encoder().encode(dto)
        _ = try await URLSession.shared.data(for: req)
    }

    // DELETE /items/:id --------------------------------------------------
    func deleteItem(id: String) async throws {
        let url = base.appendingPathComponent(id)
        var req  = URLRequest(url: url)
        req.httpMethod = "DELETE"
        _ = try await URLSession.shared.data(for: req)
    }

    // MARK: – Private helpers -------------------------------------------

    private func encoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .deferredToDate      // numeric timestamp
        return e
    }

    private func decoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .deferredToDate
        return d
    }
}
