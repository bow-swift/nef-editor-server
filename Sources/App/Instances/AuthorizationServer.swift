import Foundation
import Bow
import BowEffects


final class AuthorizationServer: Authorization {
    
    func verify(_ bearer: String) -> EnvIO<BearerEnvironment, BearerError, BearerPayload> {
        let bearerPayload = EnvIO<BearerEnvironment, BearerError, BearerPayload>.var()
        let verifiedPayload = EnvIO<BearerEnvironment, BearerError, BearerPayload>.var()
        
        return binding(
             bearerPayload <- self.getPayload(bearer: bearer),
           verifiedPayload <- self.verify(payload: bearerPayload.get),
        yield: verifiedPayload.get)^
    }
    
    // MARK: - Bearer
    private func getPayload(bearer: String) -> EnvIO<BearerEnvironment, BearerError, BearerPayload> {
        EnvIO.invokeResult { env in
            bearer.verifiedPayload(rs256: env.publicKey)
        }
    }
    
    private func verify(payload: BearerPayload) -> EnvIO<BearerEnvironment, BearerError, BearerPayload> {
        EnvIO.invoke { env in
            guard payload.issuer == env.issuer else {
                throw BearerError.invalidIssuer
            }
            
            guard payload.issuedAt < payload.expires else {
                throw BearerError.invalidIssuedAt
            }
            
            guard payload.expires > Date() else {
                throw BearerError.expiredJWT
            }
            
            return payload
        }
    }
}
