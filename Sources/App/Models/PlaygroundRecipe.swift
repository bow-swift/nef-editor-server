import Foundation

struct PlaygroundRecipe: Codable {
    let name: String
    let dependencies: [PlaygroundDependency]
}
