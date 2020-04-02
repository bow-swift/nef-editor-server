import Foundation
import BowEffects

protocol RequestEncoder {
    func safeEncode<T: Encodable>(_ value: T) -> IO<EncodingError, Data>
}

enum EncodingError: Error {
    case encoding(Swift.EncodingError)
    case other(Error)
}
