import Foundation
import NefEditorData

struct SwiftPackage: Codable {
    let name: String
    let content: String
}

extension PlaygroundRecipe {
    var swiftPackage: SwiftPackage {
        let packageName = "\(name)-\(UUID())"
        let listOfDependencies = dependencies.map { "\t\t\($0.swiftPackage)" }.joined(separator: ",\n")
        let content =   """
                        // swift-tools-version:5.1
                        import PackageDescription

                        let package = Package(
                            name: "\(packageName)",
                            dependencies: [
                        \(listOfDependencies)
                            ]
                        )
                        """
        
        return SwiftPackage(name: name, content: content)
    }
}


extension PlaygroundDependency {
    var swiftPackage: String {
        ".package(url: \"\(url)\", \(requirement.swiftPackage))"
    }
}

extension PlaygroundDependency.Requirement {
    var swiftPackage: String {
        switch self {
        case .version(let version):
            return ".exact(\"\(version)\")"
        case .branch(let branch):
            return ".branch(\"\(branch)\")"
        case .revision(let revision):
            return ".revision(\"\(revision)\")"
        case .range(let from, let to):
            if to.isEmpty {
                return "from: \"\(from)\""
            } else {
                return "\"\(from)\"...\"\(to)\""
            }
        }
    }
}
