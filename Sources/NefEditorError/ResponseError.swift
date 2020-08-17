import Foundation

public struct ErrorResponse<T: Codable>: Error, Codable {
    private enum CodingKeys: String, CodingKey {
        case isError = "error"
        case reason
    }
    
    public let isError: Bool
    public let reason: T
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.isError = try container.decode(Bool.self, forKey: .isError)
        let reason = try container.decode(String.self, forKey: .reason)
        
        if let data = reason.data(using: .utf8) {
            self.reason = try JSONDecoder().decode(T.self, from: data)
        } else {
            throw GeneralError.valueNotFound
        }
    }
}
