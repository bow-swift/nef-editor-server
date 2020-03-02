import Foundation

enum WebSocketCommand {
    enum Outgoing: Encodable {
        case status(GenerationStatus)
        case playgroundGenerated(PlaygroundGenerated)
        case error(WebSocketError)
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            
            switch self {
            case .status(let status):
                try container.encode(status)
            case .playgroundGenerated(let playgroundGenerated):
                try container.encode(playgroundGenerated)
            case .error(let error):
                try container.encode(error)
            }
        }
    }
    
    enum Incoming: Decodable {
        case recipe(PlaygroundRecipe)
        case unsupported
        
        init(from decoder: Decoder) throws {
            if let container = try? decoder.singleValueContainer(),
                let playgroundRecipe = try? container.decode(PlaygroundRecipe.self) {
                
                self = .recipe(playgroundRecipe)
            } else {
                self = .unsupported
            }
        }
    }
}
