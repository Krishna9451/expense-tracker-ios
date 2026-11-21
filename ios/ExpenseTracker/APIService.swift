import Foundation

/// Wire format shared with the Spring Boot API.
struct ExpenseDTO: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var amount: Double
    var category: String
    var date: Date
}

protocol ExpenseAPI {
    func fetchExpenses() async throws -> [ExpenseDTO]
    func upsert(_ expense: ExpenseDTO) async throws
    func delete(id: UUID) async throws
}

enum APIError: LocalizedError {
    case invalidResponse
    case server(Int)
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "The server sent an invalid response."
        case .server(let code): return "Server error (HTTP \(code))."
        case .network(let error): return "Network problem: \(error.localizedDescription)"
        }
    }
}

struct APIService: ExpenseAPI {
    /// Simulator reaches the Mac's localhost directly. Change for a deployed server.
    var baseURL = URL(string: "http://localhost:8080")!
    var session: URLSession = .shared

    private static let fractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let plain = ISO8601DateFormatter()

    private var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let string = try decoder.singleValueContainer().decode(String.self)
            if let date = APIService.fractional.date(from: string) ?? APIService.plain.date(from: string) {
                return date
            }
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Unrecognised date: \(string)"))
        }
        return d
    }

    private var encoder: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(APIService.fractional.string(from: date))
        }
        return e
    }

    func fetchExpenses() async throws -> [ExpenseDTO] {
        let url = baseURL.appendingPathComponent("api/expenses")
        let data = try await send(URLRequest(url: url))
        return try decoder.decode([ExpenseDTO].self, from: data)
    }

    func upsert(_ expense: ExpenseDTO) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent("api/expenses/\(expense.id.uuidString)"))
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(expense)
        _ = try await send(request)
    }

    func delete(id: UUID) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent("api/expenses/\(id.uuidString)"))
        request.httpMethod = "DELETE"
        _ = try await send(request)
    }

    private func send(_ request: URLRequest) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
            guard (200..<300).contains(http.statusCode) else { throw APIError.server(http.statusCode) }
            return data
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.network(error)
        }
    }
}
