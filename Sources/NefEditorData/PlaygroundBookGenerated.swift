import Foundation

public struct PlaygroundBookGenerated: Codable {
    public let name: String
    public let zip: Data
    
    public init(name: String, zip: Data) {
        self.name = name
        self.zip = zip
    }
}
