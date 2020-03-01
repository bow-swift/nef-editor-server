import Vapor

struct PlaygroundDependency: Codable {
    let name: String
    let url: String
    let version: String
}
