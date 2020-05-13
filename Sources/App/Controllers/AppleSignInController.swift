import Vapor
import Bow
import BowEffects
import AppleSignIn

final class AppleSignInController {
    let client: SignInClient
    let config: SignInConfig
    
    init(client: SignInClient, apiConfig: API.Config, environment: SignInEnvironment, responseEncoder: JSONEncoder = JSONEncoder()) {
        self.client = client
        self.config = .init(apiConfig: apiConfig,
                            environment: environment,
                            responseEncoder: responseEncoder)
    }
    
    func handle(request: Request) throws -> String {
        let queue: DispatchQueue = .init(label: String(describing: AppleSignInController.self), qos: .userInitiated)
        
        return try run(request: request)
            .unsafeRunSync(with: config, on: queue)
    }
    
    private func run(request: Request) -> EnvIO<SignInConfig, SignInError, String> {
        let env = EnvIO<SignInConfig, SignInError, SignInConfig>.var()
        let body = EnvIO<SignInConfig, SignInError, AppleSignInRequest>.var()
        let response = EnvIO<SignInConfig, SignInError, AppleSignInResponse>.var()
        let encoded = EnvIO<SignInConfig, SignInError, String>.var()
        
        return binding(
                env <- .ask(),
               body <- self.decodeRequest(body: request.content),
           response <- self.client.signIn(body.get),
            encoded <- self.encodeResponse(response.get),
        yield: encoded.get)^
    }
    
    private func decodeRequest(body: ContentContainer) -> EnvIO<SignInConfig, SignInError, AppleSignInRequest> {
        EnvIO.invoke { _ in
            try body.decode(AppleSignInRequest.self)
        }.mapError { e in .invalidCodification(.decodingRequest(e)) }
    }
    
    private func encodeResponse(_ response: AppleSignInResponse) -> EnvIO<SignInConfig, SignInError, String> {
        EnvIO.accessM { env in
            env.responseEncoder.safeEncode(response)
                .mapError { e in .invalidCodification(.encodingResponse(e)) }
        }
    }
}


extension SignInError: AbortError {
    var status: HTTPResponseStatus { .internalServerError }
    var reason: String { "\(self)" }
}
