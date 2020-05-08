 import Foundation

enum PlaygroundBookError: Error {
    case invalidCommand(Error)
    case commandCodification
    case unsupportedCommand
    case renderRecipe(Error)
    case zipRecipe(Error)
    case sending(Error)
}
