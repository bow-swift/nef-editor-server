import Foundation

public enum PlaygroundBookCommand {
    public enum Outgoing: Codable {
        case event(PlaygroundBookEvent)
        case playgroundBookGenerated(PlaygroundBookGenerated)
        case error(PlaygroundBookCommandError)
    }
    
    public enum Incoming: Codable {
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
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let event = try? container.decode(PlaygroundBookEvent.self, forKey: .event) {
            self = .event(event)
        } else if let generated = try? container.decode(PlaygroundBookGenerated.self, forKey: .playgroundBookGenerated) {
            self = .playgroundBookGenerated(generated)
        } else if let error = try? container.decode(PlaygroundBookCommandError.self, forKey: .error) {
            self = .error(error)
        } else {
            throw PlaygroundBookCommandError(description: "invalid value found in decoder from PlaygroundBookCommand.Outgoing",
                                             code: "404")
        }
    }
}

extension PlaygroundBookCommand.Incoming {
    private enum CodingKeys: String, CodingKey {
        case recipe
        case unsupported
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .recipe(let recipe):
            try container.encode(recipe, forKey: .recipe)
        case .unsupported:
            try container.encode("unsupported", forKey: .unsupported)
        }
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
