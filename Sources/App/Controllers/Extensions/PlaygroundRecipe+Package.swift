import Foundation

extension PlaygroundRecipe {
    
    var swiftPackage: SwiftPackage {
        let content =   """
                        // swift-tools-version:5.1
                        import PackageDescription

                        let package = Package(
                            name: "\(name)",
                            dependencies: [
                        \(dependencies.map(\.swiftPackage).joined(separator: ",\n"))
                            ]
                        )
                        """
        
        return SwiftPackage(content: content, name: name)
    }
}
