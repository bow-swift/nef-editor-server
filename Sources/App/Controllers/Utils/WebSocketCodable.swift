import Foundation
import BowEffects

/// Encoder
enum EncodingError: Error {
    case encoding(Swift.EncodingError)
    case other(Error)
}

protocol RequestEncoder {
    func safeEncode<T: Encodable>(_ value: T) -> IO<EncodingError, Data>
}


/// Decoder
public enum DecodingError: Error {
    case decoding(Swift.DecodingError)
    case other(Error)
}

public protocol ResponseDecoder {
    func safeDecode<T: Decodable>(_ type: T.Type, from: Data) -> IO<DecodingError, T>
}
