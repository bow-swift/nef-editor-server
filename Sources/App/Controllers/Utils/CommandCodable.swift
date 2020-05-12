import Foundation
import BowEffects

typealias HasCommandCodable = HasCommandEncoder & HasCommandDecoder

protocol HasCommandEncoder {
    var commandEncoder: Encoder { get }
}

protocol HasCommandDecoder {
    var commandDecoder: Decoder { get }
}
