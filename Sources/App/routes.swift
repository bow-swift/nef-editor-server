import Vapor
import AppleSignIn

struct RouteRegister {
    let app: Application
    
    func playgroundBook() throws {
        let controller = PlaygroundBookController(playgroundBook: PlaygroundBookServer(), config: config)
        app.webSocket("playgroundBook", onUpgrade: controller.handler)
    }
    
    func appleSignIn() throws {
        let environment = try signInEnvironment()
        let client = AppleSignInClient()
        let apiConfig = API.Config(basePath: "https://appleid.apple.com").appending(contentType: .wwwFormUrlencoded)
        let controller = AppleSignInController(client: client, apiConfig: apiConfig, environment: environment)
        
        app.post("signin", use: controller.handle)
    }
    
    // MARK: - Environment
    private func signInEnvironment() throws -> SignInEnvironment {
        try .init(sigIn: appleEnvironment(), bearer: bearerEnvironment())
    }
    
    private func appleEnvironment() throws -> AppleSignInEnvironment {
        guard let p8Key = Environment.get("p8Key"),
              let teamId = Environment.get("teamId"),
              let keyId = Environment.get("keyId"),
              let clientId = Environment.get("clientId"),
              let redirectURI = Environment.get("redirectURI") else {
                throw Abort(.internalServerError, reason: "Apple sign-in credentials not found")
        }
        
        return .init(p8Key: p8Key,
                     teamId: teamId,
                     keyId: keyId,
                     clientId: clientId,
                     redirectURI: redirectURI)
    }
    
    private func bearerEnvironment() throws -> BearerEnvironment {
        guard let privateKey = Environment.get("privateRS256Key"),
              let publicKey = Environment.get("publicRS256Key") else {
                throw Abort(.internalServerError, reason: "Bearer credentials not found")
        }
        
        return .init(privateKey: privateKey,
                     publicKey: publicKey)
    }
}


// MARK: Builders
private func config(webSocket: WebSocketOutput) -> PlaygroundBookConfig {
    let output = URL(fileURLWithPath: NSTemporaryDirectory())
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    return PlaygroundBookConfig(outputDirectory: output,
                                encoder: encoder,
                                decoder: decoder,
                                webSocket: webSocket)
}
