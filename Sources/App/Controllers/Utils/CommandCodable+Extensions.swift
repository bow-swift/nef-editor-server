import Foundation
import BowEffects

/// Make JSONEncoder conform to RequestEncoder
extension JSONEncoder: RequestEncoder {
    func safeEncode<D, T>(_ value: T) -> EnvIO<D, EncodingError, Data> where T : Encodable {
        EnvIO.invoke { _ in
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
extension JSONDecoder: ResponseDecoder {
    public func safeDecode<D, T>(_ type: T.Type, from data: Data) -> EnvIO<D, DecodingError, T> where T : Decodable {
        EnvIO.invoke { _ in
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
