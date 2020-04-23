import Foundation
import JWTKit
import AppleSignIn

// MARK: - Apple signer
struct AppleSigner {
    let kid: JWKIdentifier
    let signer: JWTSigner
}

extension Array where Element == AppleSigner {
    var jwtSigners: JWTSigners { .init(appleSigners: self) }
}

private extension JWTSigners {
    convenience init(appleSigners: [AppleSigner]) {
        self.init()
        appleSigners.forEach { appleSigner in
            use(appleSigner.signer, kid: appleSigner.kid)
        }
    }
}

extension JWKKey {
    var appleSigner: AppleSigner? {
        guard let rsaKey = RSAKey(modulus: n, exponent: e, privateExponent: nil) else {
            return nil
        }
        
        let jwkId = JWKIdentifier(string: kid)
        
        switch alg {
        case "RS256":
            return AppleSigner(kid: jwkId, signer: .rs256(key: rsaKey))
        case "RS384":
            return AppleSigner(kid: jwkId, signer: .rs384(key: rsaKey))
        case "RS512":
            return AppleSigner(kid: jwkId, signer: .rs512(key: rsaKey))
        default:
            return nil
        }
    }
}

// MARK: - Decode payload
extension JWTSigners {
    func verifiedPayload<Payload: JWTPayload>(jwt: String, as payload: Payload.Type = Payload.self) -> Result<Payload, JWTError> {
        Result {
            try verify(jwt, as: Payload.self)
        }.mapError { e in .decrypt(e) }
    }
    
    func unverifiedPayload<Payload: JWTPayload>(token: String, as payload: Payload.Type = Payload.self) -> Result<Payload, JWTError> {
        Result {
            try unverified(token, as: Payload.self)
        }.mapError { e in .decrypt(e) }
    }
}

extension ApplePayload: JWTPayload {
    func verify(using signer: JWTSigner) throws {}
}

extension AppleTokenPayload: JWTPayload {
    static var jwtSigners: JWTSigners { JWTSigners() }
    func verify(using signer: JWTSigner) throws {}
}
