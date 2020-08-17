import Vapor

extension AbortError where Self: Codable {
    public var status: HTTPResponseStatus { .internalServerError }
    
    public var reason: String {
        guard let data = try? JSONEncoder().encode(self),
              let serialized = String(data: data, encoding: .utf8) else { return "\(self)" }
        
        return serialized
    }
}
