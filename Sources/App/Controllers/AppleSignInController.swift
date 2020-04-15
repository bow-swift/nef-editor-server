import Vapor
import Bow
import BowEffects
import NefEditorData

final class AppleSignInController {
    let apple: AppleSignIn
    let encoder: RequestEncoder
    
    init(apple: AppleSignIn, encoder: RequestEncoder = JSONEncoder()) {
        self.apple = apple
        self.encoder = encoder
    }
    
    func handle(request: Request) throws -> String {
        let queue: DispatchQueue = .init(label: String(describing: AppleSignInController.self), qos: .userInitiated)
        
        return try apple.signIn()
            .flatMap(encode(response:))^
            .provide(request)
            .unsafeRunSync(on: queue)
    }
    
    private func encode(response: AppleSignInResponse) -> EnvIO<Request, AppleSignInError, String> {
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
