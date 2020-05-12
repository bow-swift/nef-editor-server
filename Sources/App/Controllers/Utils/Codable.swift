import Foundation
import Bow
import BowEffects

/// Encoder
enum EncodingError: Error {
    case encoding(Swift.EncodingError)
    case other(Error)
    case invalidCodification(Error)
    case invalidUTF8Encoding
}

protocol Encoder {
    func safeEncode<D, T: Encodable>(_ value: T) -> EnvIO<D, EncodingError, Data>
}

extension Encoder {
    func safeEncode<D, T: Encodable>(_ value: T) -> EnvIO<D, EncodingError, String> {
        safeEncode(value)
            .mapError { e in EncodingError.invalidCodification(e) }
            .flatMap { encoded in
                EnvIO.invoke { _ in
                    guard let string = String(data: encoded, encoding: .utf8) else {
                        throw EncodingError.invalidUTF8Encoding
                    }
                    
                    return string
                }
            }^
    }
}

/// Decoder
public enum DecodingError: Error {
    case decoding(Swift.DecodingError)
    case other(Error)
}

public protocol Decoder {
    func safeDecode<D, T: Decodable>(_ type: T.Type, from: Data) -> EnvIO<D, DecodingError, T>
}
