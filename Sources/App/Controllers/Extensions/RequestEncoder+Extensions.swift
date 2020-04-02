import Foundation
import BowEffects

/// Make JSONEncoder conform to RequestEncoder
extension JSONEncoder: RequestEncoder {
    func safeEncode<T>(_ value: T) -> IO<EncodingError, Data> where T : Encodable {
        IO.invoke {
            do {
                return try self.encode(value)
            } catch let error as Swift.EncodingError {
                throw EncodingError.encoding(error)
            } catch {
                throw EncodingError.other(error)
            }
        }
    }
}
