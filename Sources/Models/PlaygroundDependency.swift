import Foundation

public struct PlaygroundDependency: Codable {
    public enum Requirement: Codable {
        case version(String)
        case branch(String)
        case revision(String)
    }
    
    public let name: String
    public let url: String
    public let requirement: Requirement
    
    public init(name: String, url: String, requirement: Requirement) {
        self.name = name
        self.url = url
        self.requirement = requirement
    }
}


// MARK: - PlaygroundDependency.Requirement <Codable>

extension PlaygroundDependency.Requirement {
    private enum CodingKeys: String, CodingKey {
        case version
        case branch
        case revision
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .version(let version):
            try container.encode(version, forKey: .version)
        case .branch(let branch):
            try container.encode(branch, forKey: .branch)
        case .revision(let revision):
            try container.encode(revision, forKey: .revision)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
           
        if let version = try? container.decode(String.self, forKey: .version) {
            self = .version(version)
        } else if let branch = try? container.decode(String.self, forKey: .branch) {
            self = .branch(branch)
        } else if let revision = try? container.decode(String.self, forKey: .revision) {
            self = .revision(revision)
        } else {
            throw NSError(domain: "invalid value found in decoder from `PlaygroundDependency.Requirement`", code: -1)
        }
    }
}
