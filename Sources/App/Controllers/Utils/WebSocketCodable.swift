import Foundation
import BowEffects

/// Encoder
enum EncodingError: Error {
    case encoding(Swift.EncodingError)
    case other(Error)
}

protocol WebSocketEncoder {
    func safeEncode<T: Encodable>(_ value: T) -> IO<EncodingError, Data>
}


/// Decoder
public enum DecodingError: Error {
    case decoding(Swift.DecodingError)
    case other(Error)
}

public protocol WebSocketDecoder {
    func safeDecode<T: Decodable>(_ type: T.Type, from: Data) -> IO<DecodingError, T>
}
