import SwiftJWT

extension BearerPayload: Claims {}

extension Bearer {

    func sign(rs256: String) -> Result<String, SignInError.BearerError> {
        guard let pkey = rs256.data(using: .utf8) else {
            return .failure(.encodingRS256Key)
        }
        
        return Result {
            let jwtSigner = JWTSigner.rs256(privateKey: pkey)
            var jwt = JWT(header: Header(), claims: payload)
            return try jwt.sign(using: jwtSigner)
        }.mapError { e in .signing(e) }
    }
}

extension String {
    
    func verifiedPayload(rs256: String) -> Result<BearerPayload, SignInError.BearerError> {
        guard let pubkey = rs256.data(using: .utf8) else {
            return .failure(.encodingRS256Key)
        }
        
        return Result {
            let jwtVerifier = JWTVerifier.rs256(publicKey: pubkey)
            let jwt = try JWT<BearerPayload>(jwtString: self, verifier: jwtVerifier)
            return jwt.claims
        }.mapError { e in .invalidPayload(e) }
    }
}
