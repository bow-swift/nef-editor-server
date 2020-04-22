import Foundation
import nef
import Bow
import BowEffects
import AppleSignIn

final class AppleSignInClient: SignInClient {
    
    func signIn(_ request: AppleSignInRequest) -> EnvIO<AppleSignInClientConfig, SignInError, AppleSignInResponse> {
        let applePayload = EnvIO<AppleSignInClientConfig, SignInError, ApplePayload>.var()
        let verifiedPayload = EnvIO<AppleSignInClientConfig, SignInError, ApplePayload>.var()
        let appleToken = EnvIO<AppleSignInClientConfig, SignInError, AppleSignInTokenResponse>.var()
        let response = EnvIO<AppleSignInClientConfig, SignInError, AppleSignInResponse>.var()
        
        return binding(
             applePayload <- self.getPayload(identityToken: request.identityToken),
          verifiedPayload <- self.verify(payload: applePayload.get),
               appleToken <- self.generateAppleToken(code: request.authorizationCode),
                 response <- self.generateBearer(tokenResponse: appleToken.get),
        yield: response.get)^
    }
    
    func verify(_ bearer: String) -> EnvIO<BearerEnvironment, SignInError.BearerError, BearerPayload> {
        let bearerPayload = EnvIO<BearerEnvironment, SignInError.BearerError, BearerPayload>.var()
        let verifiedPayload = EnvIO<BearerEnvironment, SignInError.BearerError, BearerPayload>.var()
        
        return binding(
             bearerPayload <- self.getPayload(bearer: bearer),
           verifiedPayload <- self.verify(payload: bearerPayload.get),
        yield: verifiedPayload.get)^
    }
    
    // MARK: - JWT
    private func getAppleKeys() -> EnvIO<AppleSignInClientConfig, SignInError, JWKSet> {
        AppleSignIn.API.default.getKeys()
            .contramap(\AppleSignInClientConfig.apiConfig)
            .mapError { e in .jwt(.appleKeysNotFound) }
    }
    
    private func getPayload(identityToken jwt: String) -> EnvIO<AppleSignInClientConfig, SignInError, ApplePayload> {
        let jwks = EnvIO<AppleSignInClientConfig, SignInError, JWKSet>.var()
        let payload = EnvIO<AppleSignInClientConfig, SignInError, ApplePayload>.var()
        
        return binding(
               jwks <- self.getAppleKeys(),
            payload <- self.getPayload(identityToken: jwt, jwks: jwks.get),
        yield: payload.get)^
    }
    
    private func getPayload(identityToken: String, jwks: JWKSet) -> EnvIO<AppleSignInClientConfig, SignInError, ApplePayload> {
        EnvIO.invokeResult { _ in
            let signers = jwks.keys.compactMap { key in key.appleSigner }
            return signers.jwtSigners.verifiedPayload(jwt: identityToken)
        }^
    }
    
    private func verify(payload: ApplePayload) -> EnvIO<AppleSignInClientConfig, SignInError, ApplePayload> {
        EnvIO.invoke { env in
            guard payload.issuer == env.environment.sigIn.issuer else {
                throw SignInError.jwt(.invalidIssuer)
            }
            
            guard payload.audience == env.environment.sigIn.clientId else {
                throw SignInError.jwt(.invalidClientID)
            }
            
            guard payload.expires > Date() else {
                throw SignInError.jwt(.expiredJWT)
            }
            
            return payload
        }
    }
    
    // MARK: - Generate and validate tokens with Apple
    private func generateAppleToken(code: String) -> EnvIO<AppleSignInClientConfig, SignInError, AppleSignInTokenResponse> {
        let secret = EnvIO<AppleSignInClientConfig, SignInError.AppleTokenError, String>.var()
        let token = EnvIO<AppleSignInClientConfig, SignInError.AppleTokenError, AppleSignInTokenResponse>.var()
        
        return binding(
           secret <- self.clientSecret(),
            token <- self.getToken(clientSecret: secret.get, code: code),
        yield: token.get)^.mapError { e in .invalidAppleToken(e) }^
    }
    
    func getToken(clientSecret: String, code: String) -> EnvIO<AppleSignInClientConfig, SignInError.AppleTokenError, AppleSignInTokenResponse> {
        func appleSignInTokenError(httpError: API.HTTPError) -> EnvIO<AppleSignInClientConfig, SignInError.AppleTokenError, AppleSignInTokenResponse> {
            EnvIO.accessM { env in
                guard let data = httpError.dataError?.data else {
                    return EnvIO.raiseError(.invalidPayload)^
                }
                
                return env.apiConfig.decoder.safeDecode(AppleSignIn.AppleSignInError.self, from: data)
                    .mapError { error in .response(error) }^
                    .flatMap  { response in IO.raiseError(.response(response)) }^
                    .env()^
            }
        }
        
        return EnvIO.accessM { env in
            AppleSignIn.API.default
                .token(clientId: env.environment.sigIn.clientId,
                       clientSecret: clientSecret,
                       grantType: .authorizationCode,
                       code: code,
                       redirectUri: env.environment.sigIn.redirectURI)
                .contramap(\.apiConfig)
                .flatMapError(appleSignInTokenError)
        }
    }
    
    private func clientSecret(issuedAt: Date = Date()) -> EnvIO<AppleSignInClientConfig, SignInError.AppleTokenError, String> {
        EnvIO.invokeResult { env in
            let expirationDate = issuedAt.addingTimeInterval(env.environment.bearer.expirationInterval)
            
            let payload = AppleClientSecretPayload(iss: env.environment.sigIn.teamId,
                                                   iat: issuedAt,
                                                   exp: expirationDate,
                                                   aud: env.environment.sigIn.issuer,
                                                   sub: env.environment.sigIn.clientId)

            return AppleClientSecret(kid: env.environment.sigIn.keyId, payload: payload)
                .sign(p8key: env.environment.sigIn.p8Key)
        }
    }
    
    // MARK: - Bearer
    private func generateBearer(tokenResponse: AppleSignInTokenResponse) -> EnvIO<AppleSignInClientConfig, SignInError, AppleSignInResponse> {
        let payload = EnvIO<BearerEnvironment, SignInError.BearerError, AppleTokenPayload>.var()
        let bearerPayload = EnvIO<BearerEnvironment, SignInError.BearerError, BearerPayload>.var()
        let bearer = EnvIO<BearerEnvironment, SignInError.BearerError, String>.var()
        
        return binding(
                 payload <- self.payload(tokenResponse: tokenResponse),
           bearerPayload <- self.generateBearerPayload(payload: payload.get),
                  bearer <- self.generateBearer(payload: bearerPayload.get),
        yield: .init(token: bearer.get))^
            .contramap(\.environment.bearer)
            .mapError { e in .bearer(e) }
    }
    
    private func payload(tokenResponse: AppleSignInTokenResponse) -> EnvIO<BearerEnvironment, SignInError.BearerError, AppleTokenPayload> {
        EnvIO.invokeResult { _ in
            AppleTokenPayload.jwtSigners.unverifiedPayload(token: tokenResponse.idToken)
                .mapError { e in .invalidPayload(e) }
        }
    }
    
    private func generateBearerPayload(payload: AppleTokenPayload, issuedAt: Date = Date()) -> EnvIO<BearerEnvironment, SignInError.BearerError, BearerPayload> {
        EnvIO.invoke { env in
            BearerPayload(issuer: env.issuer,
                          subject: payload.subject,
                          issuedAt: issuedAt,
                          expires: issuedAt.addingTimeInterval(env.expirationInterval))
        }
    }
    
    private func generateBearer(payload: BearerPayload) -> EnvIO<BearerEnvironment, SignInError.BearerError, String> {
        EnvIO.invokeResult { env in
            Bearer(payload: payload).sign(rs256: env.privateKey)
        }
    }
    
    private func getPayload(bearer: String) -> EnvIO<BearerEnvironment, SignInError.BearerError, BearerPayload> {
        EnvIO.invokeResult { env in
            bearer.verifiedPayload(rs256: env.publicKey)
        }
    }
    
    private func verify(payload: BearerPayload) -> EnvIO<BearerEnvironment, SignInError.BearerError, BearerPayload> {
        EnvIO.invoke { env in
            guard payload.issuer == env.issuer else {
                throw SignInError.BearerError.invalidIssuer
            }
            
            guard payload.issuedAt < payload.expires else {
                throw SignInError.BearerError.invalidIssuedAt
            }
            
            guard payload.expires > Date() else {
                throw SignInError.BearerError.expiredJWT
            }
            
            return payload
        }
    }
}
