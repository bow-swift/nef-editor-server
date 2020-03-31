import Foundation

extension PlaygroundDependency {
    var swiftPackage: String {
        "        .package(url: \"\(url)\", \(requirement.swiftPackage))"
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
        }
    }
}
