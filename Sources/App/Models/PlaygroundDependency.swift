import Foundation

struct PlaygroundDependency: Codable {
    enum Requirement: Codable {
        case version(String)
        case branch(String)
        case revision(String)
    }
    
    let name: String
    let url: String
    let requirement: Requirement
}


// MARK: - PlaygroundDependency.Requirement <Codable>

extension PlaygroundDependency.Requirement {
    private enum CodingKeys: String, CodingKey {
        case version
        case branch
        case revision
    }
    
    func encode(to encoder: Encoder) throws {
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
    
   init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
           
        if let version = try? container.decode(String.self, forKey: .version) {
            self = .version(version)
        } else if let branch = try? container.decode(String.self, forKey: .branch) {
            self = .branch(branch)
        } else if let revision = try? container.decode(String.self, forKey: .revision) {
            self = .revision(revision)
        } else {
            throw PlaygroundBookCommandError(description: "invalid value found in decoder from `PlaygroundDependency.Requirement`",
                                             code: "404")
        }
    }
}
