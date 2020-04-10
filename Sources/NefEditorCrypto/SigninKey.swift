import Foundation
import Vapor

public protocol SigningKey {
    var rawRepresentation: Data { get }
    init<D>(rawRepresentation data: D) throws where D : ContiguousBytes
}

public extension SigningKey {
    var raw: String {
        String(data: rawRepresentation, encoding: .isoLatin1)!
    }
    
    static func signingKey(raw: String) -> Self? {
        guard let rawRepresentation = raw.data(using: .isoLatin1),
              let signingKey = try? Self.init(rawRepresentation: rawRepresentation) else { return nil }
        return signingKey
    }
}

extension Curve25519.Signing.PrivateKey: SigningKey {}
extension Curve25519.Signing.PublicKey: SigningKey {}


extension Curve25519.Signing.PrivateKey {
    
    public func addSignature(to headers: HTTPHeaders) -> Result<HTTPHeaders, SignatureError> {
        signature(for: headers).map { signature in
            var httpHeaders = headers
            httpHeaders[i18n.HTTPHeaders.signature] = String(data: signature, encoding: .isoLatin1)
            return httpHeaders
        }
    }
    
    private func signature(for headers: HTTPHeaders) -> Result<Data, SignatureError> {
        headers.encode()
            .mapError(SignatureError.encoding)
            .flatMap(signature(data:))
    }
    
    private func signature<D: DataProtocol>(data: D) -> Result<Data, SignatureError> {
        do {
            let signature = try self.signature(for: data)
            return .success(signature)
        } catch {
            return .failure(.creating(error))
        }
    }
}

extension Curve25519.Signing.PublicKey {
    
    public func isValidSignature<D: DataProtocol>(_ signature: D, for headers: HTTPHeaders) -> Bool {
        guard case let .success(data) = headers.encode() else { return false }
        return isValidSignature(signature, for: data)
    }
}
