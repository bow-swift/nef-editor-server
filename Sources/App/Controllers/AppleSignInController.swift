import Vapor
import Bow
import BowEffects
import AppleSignIn

final class AppleSignInController {
    let config: AppleSignInConfig
    
    init(client: SignInClient, apiConfig: API.Config, responseEncoder: JSONEncoder = JSONEncoder()) {
        self.config = AppleSignInConfig(client: client,
                                        apiConfig: apiConfig,
                                        responseEncoder: responseEncoder)
    }
    
    func handle(request: Request) throws -> String {
        let queue: DispatchQueue = .init(label: String(describing: AppleSignInController.self), qos: .userInitiated)

        return try run(request: request)
            .provide(config)
            .unsafeRunSync(on: queue)
    }
    
    private func run(request: Request) -> EnvIO<AppleSignInConfig, AppleSignInError, String> {
        let env = EnvIO<AppleSignInConfig, AppleSignInError, AppleSignInConfig>.var()
        let body = EnvIO<AppleSignInConfig, AppleSignInError, AppleSignInRequest>.var()
        let response = EnvIO<AppleSignInConfig, AppleSignInError, AppleSignInResponse>.var()
        let encoded = EnvIO<AppleSignInConfig, AppleSignInError, String>.var()
        
        return binding(
                env <- .ask(),
               body <- self.decode(body: request.content),
           response <- env.get.client.signIn(body.get).contramap(\AppleSignInConfig.apiConfig),
            encoded <- self.encodeResponse(response.get),
        yield: encoded.get)^
    }
    
    private func decode(body: ContentContainer) -> EnvIO<AppleSignInConfig, AppleSignInError, AppleSignInRequest> {
        EnvIO.invoke { _ in
            try body.decode(AppleSignInRequest.self)
        }.mapError { error in .decodingRequest(error) }^
    }
    
    private func encodeResponse(_ response: AppleSignInResponse) -> EnvIO<AppleSignInConfig, AppleSignInError, String> {
        func encode(response: AppleSignInResponse, encoder: Encoder) -> EnvIO<AppleSignInConfig, AppleSignInError, String> {
            encoder.safeEncode(response)^
                .mapError { e in .encodingResponse(e) }^
                .flatMap(self.encodeResponse)^
        }
        
        let env = EnvIO<AppleSignInConfig, AppleSignInError, AppleSignInConfig>.var()
        let encoded = EnvIO<AppleSignInConfig, AppleSignInError, String>.var()
        
        return binding(
               env <- .ask(),
           encoded <- encode(response: response, encoder: env.get.responseEncoder),
        yield: encoded.get)^
    }
    
    private func encodeResponse(_ response: Data) -> EnvIO<AppleSignInConfig, AppleSignInError, String> {
        func encode(data: Data, encoder: Encoder) -> EnvIO<AppleSignInConfig, AppleSignInError, String> {
            encoder.safeEncode(response)
            .mapError { e in .encodingResponse(e) }^
            .flatMap { encoded in
                EnvIO.invoke { _ in
                    guard let string = String(data: data, encoding: .utf8) else {
                        throw AppleSignInError.invalidUTF8Encoding
                    }
                    
                    return string
                }^
            }^
        }
        
        let env = EnvIO<AppleSignInConfig, AppleSignInError, AppleSignInConfig>.var()
        let encoded = EnvIO<AppleSignInConfig, AppleSignInError, String>.var()
        
        return binding(
               env <- .ask(),
           encoded <- encode(data: response, encoder: env.get.responseEncoder),
        yield: encoded.get)^
    }
}
