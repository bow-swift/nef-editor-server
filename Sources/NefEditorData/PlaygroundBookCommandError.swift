 import Foundation

public struct PlaygroundBookCommandError: Error, Codable {
    public let description: String
    public let code: String
    
    public init(description: String, code: String) {
        self.description = description
        self.code = code
    }
}
