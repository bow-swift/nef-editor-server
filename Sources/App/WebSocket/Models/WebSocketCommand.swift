import Foundation

enum WebSocketCommand {
    enum Outgoing: Encodable {
        case status(GenerationStatus)
        case playgroundGenerated(PlaygroundGenerated)
        case error(WebSocketError)
        
        private enum CodingKeys: String, CodingKey {
            case status
            case playgroundGenerated
            case error
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            switch self {
            case .status(let status):
                try container.encode(status, forKey: .status)
            case .playgroundGenerated(let playgroundGenerated):
                try container.encode(playgroundGenerated, forKey: .playgroundGenerated)
            case .error(let error):
                try container.encode(error, forKey: .error)
            }
        }
    }
    
    enum Incoming: Decodable {
        case recipe(PlaygroundRecipe)
        case unsupported
        
        private enum CodingKeys: String, CodingKey {
            case recipe
        }
        
        init(from decoder: Decoder) throws {
            if let container = try? decoder.container(keyedBy: CodingKeys.self),
                let playgroundRecipe = try? container.decode(PlaygroundRecipe.self, forKey: .recipe) {
                
                self = .recipe(playgroundRecipe)
            } else {
                self = .unsupported
            }
        }
    }
}
