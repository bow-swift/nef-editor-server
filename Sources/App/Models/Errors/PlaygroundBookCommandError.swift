 import Foundation

struct PlaygroundBookCommandError: Error, Encodable {
    let description: String
    let code: String
}
