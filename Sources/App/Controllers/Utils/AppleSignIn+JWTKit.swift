import Foundation
import JWTKit
import AppleSignIn

struct AppleSigner {
    let kid: JWKIdentifier
    let signer: JWTSigner
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

extension Array where Element == AppleSigner {
    func decode(jwt: String) throws -> AppleJWT {
        try jwtSigners.verify(jwt, as: AppleJWT.self)
    }
    
    private var jwtSigners: JWTSigners {
        let signers = JWTSigners()
        forEach { appleSigner in
            signers.use(appleSigner.signer, kid: appleSigner.kid)
        }
        
        return signers
    }
}

extension AppleJWT: JWTPayload {
    func verify(using signer: JWTSigner) throws {}
}
