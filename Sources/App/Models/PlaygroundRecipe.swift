import Foundation

struct PlaygroundRecipe: Codable {
    let dependencies: [PlaygroundDependency]
}

extension PlaygroundRecipe {
    
    var swiftPackage: SwiftPackage {
        return SwiftPackage.init(content: "", name: "")
    }
}
