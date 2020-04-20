import SwiftJWT

extension AppleClientSecretPayload: Claims {}

extension AppleClientSecret {

    func sign(p8key: String) -> Result<String, AppleSignInError.AppleToken> {
        guard let pkey = p8key.data(using: .utf8) else {
            return .failure(.encodingP8Key)
        }
        
        return Result {
            let jwtSigner = JWTSigner.es256(privateKey: pkey)
            let header = Header(typ: nil, kid: kid)
            var jwt = JWT(header: header, claims: payload)
            return try jwt.sign(using: jwtSigner)
        }.mapError { e in .clientSecret(e) }
    }
}
