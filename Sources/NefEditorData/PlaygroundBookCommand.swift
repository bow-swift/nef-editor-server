import Foundation

public enum PlaygroundBookCommand {
    public enum Outgoing: Encodable {
        case event(PlaygroundBookEvent)
        case playgroundBookGenerated(PlaygroundBookGenerated)
        case error(PlaygroundBookCommandError)
    }
    
    public enum Incoming: Decodable {
        case recipe(PlaygroundRecipe)
        case unsupported
    }
}


// MARK: - Incoming & Outgoing <Codable>

extension PlaygroundBookCommand.Outgoing {
    private enum CodingKeys: String, CodingKey {
        case event
        case playgroundBookGenerated
        case error
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .event(let event):
            try container.encode(event, forKey: .event)
        case .playgroundBookGenerated(let playground):
            try container.encode(playground, forKey: .playgroundBookGenerated)
        case .error(let error):
            try container.encode(error, forKey: .error)
        }
    }
}

extension PlaygroundBookCommand.Incoming {
    private enum CodingKeys: String, CodingKey {
        case recipe
    }
    
    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self),
           let recipe = try? container.decode(PlaygroundRecipe.self, forKey: .recipe) {
            self = .recipe(recipe)
        } else {
            self = .unsupported
        }
    }
}
