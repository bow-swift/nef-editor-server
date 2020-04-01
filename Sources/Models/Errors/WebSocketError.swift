 import Foundation

public struct WebSocketError: Encodable {
    public let description: String
    public let code: String
    
    public init(description: String, code: String) {
        self.description = description
        self.code = code
    }
}
