import Foundation

public struct PlaygroundRecipe: Codable {
    public let name: String
    public let dependencies: [PlaygroundDependency]
    
    public init(name: String, dependencies: [PlaygroundDependency]) {
        self.name = name
        self.dependencies = dependencies
    }
}
