import Foundation
import BowEffects

/// Make JSONEncoder conform to RequestEncoder
extension JSONEncoder: WebSocketEncoder {
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

/// Make JSONDecoder conform to RequestDecoder
extension JSONDecoder: WebSocketDecoder {
    public func safeDecode<T>(_ type: T.Type, from data: Data) -> IO<DecodingError, T> where T : Decodable {
        IO.invoke {
            do {
                return try self.decode(T.self, from: data)
            } catch let error as Swift.DecodingError {
                throw DecodingError.decoding(error)
            } catch {
                throw DecodingError.other(error)
            }
        }
    }
}
