import Vapor

struct PlaygroundRecipe: Codable {
    let dependencies: [PlaygroundDependency]
}
