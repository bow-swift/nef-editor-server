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
        let bearer = EnvIO<AppleSignInClientConfig, SignInError, String>.var()
        
        return binding(
             applePayload <- self.getPayload(identityToken: request.identityToken).mapError { e in .jwt(e) },
          verifiedPayload <- self.verify(payload: applePayload.get).mapError { e in .jwt(e) },
               appleToken <- self.generateAppleToken(code: request.authorizationCode).mapError { e in .appleToken(e) },
                   bearer <- self.generateBearer(tokenResponse: appleToken.get).mapError { e in .bearer(e) },
        yield: .init(token: bearer.get))^
    }
    
    func verify(_ bearer: String) -> EnvIO<BearerEnvironment, BearerError, BearerPayload> {
        let bearerPayload = EnvIO<BearerEnvironment, BearerError, BearerPayload>.var()
        let verifiedPayload = EnvIO<BearerEnvironment, BearerError, BearerPayload>.var()
        
        return binding(
             bearerPayload <- self.getPayload(bearer: bearer),
           verifiedPayload <- self.verify(payload: bearerPayload.get),
        yield: verifiedPayload.get)^
    }
    
    // MARK: - JWT
    private func getPayload(identityToken jwt: String) -> EnvIO<AppleSignInClientConfig, JWTError, ApplePayload> {
        let jwks = EnvIO<AppleSignInClientConfig, JWTError, JWKSet>.var()
        let payload = EnvIO<AppleSignInClientConfig, JWTError, ApplePayload>.var()
        
        return binding(
               jwks <- self.getAppleKeys(),
            payload <- self.getPayload(identityToken: jwt, jwks: jwks.get),
        yield: payload.get)^
    }
    
    private func getPayload(identityToken: String, jwks: JWKSet) -> EnvIO<AppleSignInClientConfig, JWTError, ApplePayload> {
        EnvIO.invokeResult { _ in
            let signers = jwks.keys.compactMap { key in key.appleSigner }
            return signers.jwtSigners.verifiedPayload(jwt: identityToken)
        }^
    }
    
    private func getAppleKeys() -> EnvIO<AppleSignInClientConfig, JWTError, JWKSet> {
        AppleSignIn.API.default.getKeys()
            .contramap(\AppleSignInClientConfig.apiConfig)
            .mapError { e in .appleKeysNotFound }
    }
    
    private func verify(payload: ApplePayload) -> EnvIO<AppleSignInClientConfig, JWTError, ApplePayload> {
        EnvIO.invoke { env in
            guard payload.issuer == env.environment.sigIn.issuer else {
                throw JWTError.invalidIssuer
            }
            
            guard payload.audience == env.environment.sigIn.clientId else {
                throw JWTError.invalidClientID
            }
            
            guard payload.expires > Date() else {
                throw JWTError.expiredJWT
            }
            
            return payload
        }
    }
    
    // MARK: - Generate and validate tokens with Apple
    private func generateAppleToken(code: String) -> EnvIO<AppleSignInClientConfig, AppleTokenError, AppleSignInTokenResponse> {
        let secret = EnvIO<AppleSignInClientConfig, AppleTokenError, String>.var()
        let token = EnvIO<AppleSignInClientConfig, AppleTokenError, AppleSignInTokenResponse>.var()
        
        return binding(
           secret <- self.clientSecret(),
            token <- self.getToken(clientSecret: secret.get, code: code),
        yield: token.get)^
    }
    
    func getToken(clientSecret: String, code: String) -> EnvIO<AppleSignInClientConfig, AppleTokenError, AppleSignInTokenResponse> {
        func appleSignInTokenError(httpError: API.HTTPError) -> EnvIO<AppleSignInClientConfig, AppleTokenError, AppleSignInTokenResponse> {
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
    
    private func clientSecret(issuedAt: Date = Date()) -> EnvIO<AppleSignInClientConfig, AppleTokenError, String> {
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
    private func generateBearer(tokenResponse: AppleSignInTokenResponse) -> EnvIO<AppleSignInClientConfig, BearerError, String> {
        let payload = EnvIO<BearerEnvironment, BearerError, AppleTokenPayload>.var()
        let bearerPayload = EnvIO<BearerEnvironment, BearerError, BearerPayload>.var()
        let bearer = EnvIO<BearerEnvironment, BearerError, String>.var()
        
        return binding(
                 payload <- self.payload(tokenResponse: tokenResponse),
           bearerPayload <- self.generateBearerPayload(payload: payload.get),
                  bearer <- self.generateBearer(payload: bearerPayload.get),
        yield: bearer.get)^
            .contramap(\.environment.bearer)
    }
    
    private func payload(tokenResponse: AppleSignInTokenResponse) -> EnvIO<BearerEnvironment, BearerError, AppleTokenPayload> {
        EnvIO.invokeResult { _ in
            AppleTokenPayload.jwtSigners.unverifiedPayload(token: tokenResponse.idToken)
                .mapError { e in .invalidPayload(e) }
        }
    }
    
    private func generateBearerPayload(payload: AppleTokenPayload, issuedAt: Date = Date()) -> EnvIO<BearerEnvironment, BearerError, BearerPayload> {
        EnvIO.invoke { env in
            BearerPayload(issuer: env.issuer,
                          subject: payload.subject,
                          issuedAt: issuedAt,
                          expires: issuedAt.addingTimeInterval(env.expirationInterval))
        }
    }
    
    private func generateBearer(payload: BearerPayload) -> EnvIO<BearerEnvironment, BearerError, String> {
        EnvIO.invokeResult { env in
            Bearer(payload: payload).sign(rs256: env.privateKey)
        }
    }
    
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
