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
        let jwtRequest = AppleSignInRequest(user: "000870.c1930c96c3444d839de0491e5a52833c.1240",
                                         identityToken: "eyJraWQiOiJlWGF1bm1MIiwiYWxnIjoiUlMyNTYifQ.eyJpc3MiOiJodHRwczovL2FwcGxlaWQuYXBwbGUuY29tIiwiYXVkIjoiY29tLjQ3ZGVnLlNpZ25JbkFwcGxlVGVzdCIsImV4cCI6MTU4Njk0MzUwNiwiaWF0IjoxNTg2OTQyOTA2LCJzdWIiOiIwMDA4NzAuYzE5MzBjOTZjMzQ0NGQ4MzlkZTA0OTFlNWE1MjgzM2MuMTI0MCIsImNfaGFzaCI6IjZ0VTNFMlNZRUQzWUFVXzk4R19nQWciLCJhdXRoX3RpbWUiOjE1ODY5NDI5MDYsIm5vbmNlX3N1cHBvcnRlZCI6dHJ1ZX0.NdjYS3SHEmHXZUncyBTJf3uh06pXF0-wtBr8N35p7-qYlwOj-Fv-UcTyTD4TJdCA-2l26pLn2OiCdZYMg5Ws-gLleMp0ZX0p6mmwlFx6Wbq1VXgq5ekb7rct5remx446lj9ekp5kJevM7vjTlbgTeN9NMKK8yj-sQcAwMN5J8byT7K5EtoRlWwEpiR0C-FRj1lx872YwNIJwMFwsuI0c6FiQKG9CsJ9hxS8u5GuzCOuTRfjUk9g5RJyFZKQA45VequJXn_TinklTCjNNY83Q3rG4YvdRztroXbDtPVD2S-W_c0JyBsBR-6Baj_oLT4hwW2iImP8qtKOxrL_9P9hD4A",
                                         authorizationCode: "c4fbcb06cf6cc4d01a543850b01888972.0.nyxq.9RbVBv8evY0n7zh7o_h0Fg")
//        request.jwt.apple.verify(jwtRequest.identityToken)
        
        return try client.signIn(jwtRequest)
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
