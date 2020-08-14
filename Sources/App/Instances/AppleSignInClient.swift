import Foundation
import nef
import Bow
import BowEffects
import AppleSignIn
import NefEditorError

final class AppleSignInClient: SignInClient {
    
    func signIn(_ request: AppleSignInRequest) -> EnvIO<SignInConfig, SignInError, AppleSignInResponse> {
        let applePayload = EnvIO<SignInConfig, SignInError, ApplePayload>.var()
        let verifiedPayload = EnvIO<SignInConfig, SignInError, ApplePayload>.var()
        let appleToken = EnvIO<SignInConfig, SignInError, AppleSignInTokenResponse>.var()
        let bearer = EnvIO<SignInConfig, SignInError, String>.var()
        
        return binding(
             applePayload <- self.getPayload(identityToken: request.identityToken),
          verifiedPayload <- self.verify(payload: applePayload.get),
               appleToken <- self.generateAppleToken(code: request.authorizationCode),
                   bearer <- self.generateBearer(tokenResponse: appleToken.get),
        yield: .init(token: bearer.get))^
    }
    
    // MARK: - JWT
    private func getPayload(identityToken jwt: String) -> EnvIO<SignInConfig, SignInError, ApplePayload> {
        let jwks = EnvIO<SignInConfig, SignInError, JWKSet>.var()
        let payload = EnvIO<SignInConfig, SignInError, ApplePayload>.var()
        
        return binding(
               jwks <- self.getAppleKeys(),
            payload <- self.getPayload(identityToken: jwt, jwks: jwks.get),
        yield: payload.get)^
    }
    
    private func getPayload(identityToken: String, jwks: JWKSet) -> EnvIO<SignInConfig, SignInError, ApplePayload> {
        EnvIO.invokeResult { _ in
            let signers = jwks.keys.compactMap { key in key.appleSigner }
            return signers.jwtSigners.verifiedPayload(jwt: identityToken)
        }.mapError(SignInError.jwt)
    }
    
    private func getAppleKeys() -> EnvIO<SignInConfig, SignInError, JWKSet> {
        AppleSignIn.API.default.getKeys()
            .contramap(\.apiConfig)
            .mapError { e in .jwt(.appleKeysNotFound) }
    }
    
    private func verify(payload: ApplePayload) -> EnvIO<SignInConfig, SignInError, ApplePayload> {
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
        }.mapError(SignInError.jwt)
    }
    
    // MARK: - Generate and validate tokens with Apple
    private func generateAppleToken(code: String) -> EnvIO<SignInConfig, SignInError, AppleSignInTokenResponse> {
        let secret = EnvIO<SignInConfig, AppleTokenError, String>.var()
        let token = EnvIO<SignInConfig, AppleTokenError, AppleSignInTokenResponse>.var()
        
        return binding(
           secret <- self.clientSecret(),
            token <- self.getToken(clientSecret: secret.get, code: code),
        yield: token.get)^.mapError(SignInError.appleToken)
    }
    
    func getToken(clientSecret: String, code: String) -> EnvIO<SignInConfig, AppleTokenError, AppleSignInTokenResponse> {
        func appleSignInTokenError(httpError: API.HTTPError) -> EnvIO<SignInConfig, AppleTokenError, AppleSignInTokenResponse> {
            EnvIO.accessM { env in
                guard let data = httpError.dataError?.data else {
                    return EnvIO.raiseError(.invalidPayload)^
                }
                
                return env.apiConfig.decoder.safeDecode(AppleSignIn.AppleSignInError.self, from: data)
                    .mapError(AppleTokenError.response)
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
    
    private func clientSecret(issuedAt: Date = Date()) -> EnvIO<SignInConfig, AppleTokenError, String> {
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
    private func generateBearer(tokenResponse: AppleSignInTokenResponse) -> EnvIO<SignInConfig, SignInError, String> {
        let payload = EnvIO<BearerEnvironment, BearerError, AppleTokenPayload>.var()
        let bearerPayload = EnvIO<BearerEnvironment, BearerError, BearerPayload>.var()
        let bearer = EnvIO<BearerEnvironment, BearerError, String>.var()
        
        return binding(
                 payload <- self.payload(tokenResponse: tokenResponse),
           bearerPayload <- self.generateBearerPayload(payload: payload.get),
                  bearer <- self.signBearerPayload(bearerPayload.get),
        yield: bearer.get)^
            .contramap(\.environment.bearer)
            .mapError(SignInError.bearer)
    }
    
    private func payload(tokenResponse: AppleSignInTokenResponse) -> EnvIO<BearerEnvironment, BearerError, AppleTokenPayload> {
        EnvIO.invokeResult { _ in
            AppleTokenPayload.jwtSigners.unverifiedPayload(token: tokenResponse.idToken)
                .mapError { _ in BearerError.invalidPayload(.appleToken) }
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
    
    private func signBearerPayload(_ payload: BearerPayload) -> EnvIO<BearerEnvironment, BearerError, String> {
        EnvIO.invokeResult { env in
            Bearer(payload: payload).sign(rs256: env.privateKey)
        }
    }
}
