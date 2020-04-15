import Vapor
import Bow
import BowEffects
import NefEditorData
import AppleSignIn

final class AppleSignInController {
    let client: SignInClient
    let encoder: RequestEncoder
    
    init(client: SignInClient, encoder: RequestEncoder = JSONEncoder()) {
        self.client = client
        self.encoder = encoder
    }
    
    func handle(request: Request) throws -> String {
        let queue: DispatchQueue = .init(label: String(describing: AppleSignInController.self), qos: .userInitiated)
        
        return try client.signIn()
            .flatMap(encode(response:))^
            .provide(API.Config(basePath: "https://appleid.apple.com"))
            .unsafeRunSync(on: queue)
    }
    
    private func encode(response: AppleSignInResponse) -> EnvIO<API.Config, AppleSignInError, String> {
        encoder.safeEncode(response)^
            .mapError { e in .response(e) }^
            .flatMap { data in
                EnvIO.invoke { request in
                    guard let json = String(data: data, encoding: .utf8), !json.isEmpty else {
                        throw AppleSignInError.encoding
                    }
                    
                    return json
                }
            }^
    }
}
