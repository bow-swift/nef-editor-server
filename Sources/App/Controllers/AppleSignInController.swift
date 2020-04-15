import Vapor
import Bow
import BowEffects
import NefEditorData
import AppleSignIn

final class AppleSignInController {
    let client: SignInClient
    let apiConfig: API.Config
    let responseEncoder: JSONEncoder
    
    init(client: SignInClient, apiConfig: API.Config, responseEncoder: JSONEncoder = JSONEncoder()) {
        self.client = client
        self.apiConfig = apiConfig
        self.responseEncoder = responseEncoder
    }
    
    func handle(request: Request) throws -> String {
        let queue: DispatchQueue = .init(label: String(describing: AppleSignInController.self), qos: .userInitiated)

        return try run(request: request)
            .provide(apiConfig)
            .unsafeRunSync(on: queue)
    }
    
    private func run(request: Request) -> EnvIO<API.Config, AppleSignInError, String> {
        let body = EnvIO<API.Config, AppleSignInError, AppleSignInRequest>.var()
        let response = EnvIO<API.Config, AppleSignInError, AppleSignInResponse>.var()
        let encoded = EnvIO<API.Config, AppleSignInError, String>.var()
        
        return binding(
               body <- self.decode(body: request.content),
           response <- self.client.signIn(body.get),
            encoded <- self.encode(response: response.get, with: self.responseEncoder),
        yield: encoded.get)^
    }
    
    private func decode(body: ContentContainer) -> EnvIO<API.Config, AppleSignInError, AppleSignInRequest> {
        do {
            let request = try body.decode(AppleSignInRequest.self)
            return EnvIO.pure(request)^
        } catch {
            return EnvIO.raiseError(AppleSignInError.decoding(error))^
        }
    }
    
    private func encode(response: AppleSignInResponse, with encoder: JSONEncoder) -> EnvIO<API.Config, AppleSignInError, String> {
        encoder.safeEncode(response)^
            .mapError { e in .encoding(e) }^
            .flatMap { data in
                EnvIO.invoke { request in
                    guard let json = String(data: data, encoding: .utf8), !json.isEmpty else {
                        throw AppleSignInError.encoding()
                    }

                    return json
                }
            }^
    }
}
