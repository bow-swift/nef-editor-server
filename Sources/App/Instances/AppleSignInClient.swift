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
             applePayload <- self.getPayload(identityToken: request.identityToken),
          verifiedPayload <- self.verify(payload: applePayload.get),
               appleToken <- self.generateAppleToken(code: request.authorizationCode),
                   bearer <- self.generateBearer(tokenResponse: appleToken.get),
        yield: .init(token: bearer.get))^
    }
    
    // MARK: - JWT
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
        }^.mapError { e in .jwt(e) }^
    }
    
    private func getAppleKeys() -> EnvIO<AppleSignInClientConfig, SignInError, JWKSet> {
        AppleSignIn.API.default.getKeys()
            .contramap(\.apiConfig)
            .mapError { e in .jwt(.appleKeysNotFound) }
    }
    
    private func verify(payload: ApplePayload) -> EnvIO<AppleSignInClientConfig, SignInError, ApplePayload> {
        EnvIO.invoke { env in
            guard payload.issuer == env.environment.signIn.issuer else {
                throw JWTError.invalidIssuer
            }
            
            guard payload.audience == env.environment.signIn.clientId else {
                throw JWTError.invalidClientID
            }
            
            guard payload.expires > Date() else {
                throw JWTError.expiredJWT
            }
            
            return payload
        }.mapError { e in .jwt(e) }^
    }
    
    // MARK: - Generate and validate tokens with Apple
    private func generateAppleToken(code: String) -> EnvIO<AppleSignInClientConfig, SignInError, AppleSignInTokenResponse> {
        let secret = EnvIO<AppleSignInClientConfig, AppleTokenError, String>.var()
        let token = EnvIO<AppleSignInClientConfig, AppleTokenError, AppleSignInTokenResponse>.var()
        
        return binding(
           secret <- self.clientSecret(),
            token <- self.getToken(clientSecret: secret.get, code: code),
        yield: token.get)^.mapError { e in .appleToken(e) }
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
                .token(clientId: env.environment.signIn.clientId,
                       clientSecret: clientSecret,
                       grantType: .authorizationCode,
                       code: code,
                       redirectUri: env.environment.signIn.redirectURI)
                .contramap(\.apiConfig)
                .flatMapError(appleSignInTokenError)
        }
    }
    
    private func clientSecret(issuedAt: Date = Date()) -> EnvIO<AppleSignInClientConfig, AppleTokenError, String> {
        EnvIO.invokeResult { env in
            let expirationDate = issuedAt.addingTimeInterval(env.environment.bearer.expirationInterval)
            
            let payload = AppleClientSecretPayload(iss: env.environment.signIn.teamId,
                                                   iat: issuedAt,
                                                   exp: expirationDate,
                                                   aud: env.environment.signIn.issuer,
                                                   sub: env.environment.signIn.clientId)

            return AppleClientSecret(kid: env.environment.signIn.keyId, payload: payload)
                .sign(p8key: env.environment.signIn.p8Key)
        }
    }
    
    // MARK: - Bearer
    private func generateBearer(tokenResponse: AppleSignInTokenResponse) -> EnvIO<AppleSignInClientConfig, SignInError, String> {
        let payload = EnvIO<BearerEnvironment, BearerError, AppleTokenPayload>.var()
        let bearerPayload = EnvIO<BearerEnvironment, BearerError, BearerPayload>.var()
        let bearer = EnvIO<BearerEnvironment, BearerError, String>.var()
        
        return binding(
                 payload <- self.payload(tokenResponse: tokenResponse),
           bearerPayload <- self.generateBearerPayload(payload: payload.get),
                  bearer <- self.generateBearer(payload: bearerPayload.get),
        yield: bearer.get)^
            .contramap(\.environment.bearer)
            .mapError { e in .bearer(e) }
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
}
