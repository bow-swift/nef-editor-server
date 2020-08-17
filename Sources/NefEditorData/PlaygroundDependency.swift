import Foundation

public struct PlaygroundDependency {
    public enum Requirement {
        case version(String)
        case range(from: String, to: String = "")
        case branch(String)
        case revision(String)
    }
    
    public let name: String
    public let url: String
    public let requirement: Requirement
    public let products: [String]
    
    public init(name: String, url: String, requirement: Requirement, products: [String] = []) {
        self.name = name
        self.url = url
        self.requirement = requirement
        self.products = products
    }
}


// MARK: - PlaygroundDependency <Codable>

extension PlaygroundDependency: Codable {
    private enum CodingKeys: String, CodingKey {
        case name
        case url
        case requirement
        case products
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
           
        self.name = try container.decode(String.self, forKey: .name)
        self.url = try container.decode(String.self, forKey: .url)
        self.requirement = try container.decode(PlaygroundDependency.Requirement.self, forKey: .requirement)
        self.products = (try? container.decode([String].self, forKey: .products)) ?? []
    }
}


// MARK: - PlaygroundDependency.Requirement <Codable>

extension PlaygroundDependency.Requirement: Codable {
    private enum CodingKeys: String, CodingKey {
        case version
        case versionRangeFrom
        case versionRangeTo
        case branch
        case revision
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .version(let version):
            try container.encode(version, forKey: .version)
        case .range(from: let from, to: let to):
            try container.encode(from, forKey: .versionRangeFrom)
            try container.encode(to, forKey: .versionRangeTo)
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
        } else if let from = try? container.decode(String.self, forKey: .versionRangeFrom),
                  let to = try? container.decode(String.self, forKey: .versionRangeTo) {
            self = .range(from: from, to: to)
        } else if let branch = try? container.decode(String.self, forKey: .branch) {
            self = .branch(branch)
        } else if let revision = try? container.decode(String.self, forKey: .revision) {
            self = .revision(revision)
        } else {
            throw PlaygroundBookCommandError(description: "invalid value found in decoder from PlaygroundDependency.Requirement",
                                             code: "404")
        }
    }
}
