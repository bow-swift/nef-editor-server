import Foundation
import BowEffects

typealias HasCommandCodable = HasCommandEncoder & HasCommandDecoder

protocol HasCommandEncoder {
    var commandEncoder: Encoder { get }
}

protocol HasCommandDecoder {
    var commandDecoder: Decoder { get }
}

/// Encoder
enum EncodingError: Error {
    case encoding(Swift.EncodingError)
    case other(Error)
}

protocol Encoder {
    func safeEncode<D, T: Encodable>(_ value: T) -> EnvIO<D, EncodingError, Data>
}


/// Decoder
public enum DecodingError: Error {
    case decoding(Swift.DecodingError)
    case other(Error)
}

public protocol Decoder {
    func safeDecode<D, T: Decodable>(_ type: T.Type, from: Data) -> EnvIO<D, DecodingError, T>
}
