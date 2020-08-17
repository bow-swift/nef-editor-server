import Foundation
import NefEditorData

struct SwiftPackage: Codable {
    let name: String
    let content: String
}

extension PlaygroundRecipe {
    var swiftPackage: SwiftPackage {
        let packageName = "\(name)-\(UUID())"
        let listOfDependencies = dependencies.map { "\t\t\($0.package)" }.joined(separator: ",\n")
        let listOfTargets = dependencies.map { "\t\t\($0.target)" }.joined(separator: ",\n")
        let listOfTargetsNames = dependencies.map { "\"\($0.targetName)\"" }.joined(separator: ", ")
        
        let content =   """
                        // swift-tools-version:5.2
                        import PackageDescription

                        let package = Package(
                            name: "\(packageName)",
                            products: [
                                .library(name: "\(packageName)", targets: [\(listOfTargetsNames)])
                            ],
                            dependencies: [
                        \(listOfDependencies)
                            ],
                            targets: [
                        \(listOfTargets)
                            ]
                        )
                        """
        
        return SwiftPackage(name: name, content: content)
    }
}


extension PlaygroundDependency {
       
    var targetName: String {
        "\(swiftPackageName)-target"
    }
    
    var dependencyName: String {
        "\(swiftPackageName)-dependency"
    }
    
    var package: String {
        if self.products.count > 0 {
            return ".package(url: \"\(url)\", \(requirement.swiftPackage))"
        } else {
            return ".package(name: \"\(dependencyName)\", url: \"\(url)\", \(requirement.swiftPackage))"
        }
    }
    
    var target: String {
        if self.products.count > 0 {
            let listOfDependencies = products.map { "\"\($0)\"" }.joined(separator: ", ")
            return ".target(name: \"\(targetName)\", dependencies: [\(listOfDependencies)])"
        } else {
            return ".target(name: \"\(targetName)\", dependencies: [\"\(dependencyName)\"])"
        }
    }
    
    private var swiftPackageName: String {
        name.lowercased()
            .replacingFirstOccurrence(of: " ", with: "-")
            .trimmingEmptyCharacters
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
