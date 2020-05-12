import Vapor
import AppleSignIn

struct RouteRegister {
    let app: Application
    
    func healthCheck() throws {
        app.get("health_check") { _ in "OK!" }
    }
    
    func playgroundBook() throws {
        let output = URL(fileURLWithPath: NSTemporaryDirectory())
        let config = PlaygroundBookConfig(outputDirectory: output, requestDecoder: JSONDecoder(), responseEncoder: JSONEncoder())
        let controller = PlaygroundBookController(playgroundBook: PlaygroundBookServer(), config: config, socketConfig: socketConfig)
        let bearerAuth = try BearerAuthorizationMiddleware(authorization: AuthorizationServer(), environment: bearerEnvironment())
        
        app.grouped(bearerAuth)
           .grouped(Bearer.guardMiddleware())
           .webSocket("playgroundBook", onUpgrade: controller.handle)
        
        app.grouped(bearerAuth)
           .grouped(Bearer.guardMiddleware())
           .post("playgroundBook", use: controller.handle)
    }
    
    func appleSignIn() throws {
        let environment = try signInEnvironment()
        let client = AppleSignInClient()
        let apiConfig = API.Config(basePath: "https://appleid.apple.com").appending(contentType: .wwwFormUrlencoded)
        let controller = AppleSignInController(client: client, apiConfig: apiConfig, environment: environment)
        
        app.post("signin", use: controller.handle)
    }
    
    // MARK: - Environments
    private func signInEnvironment() throws -> SignInEnvironment {
        try .init(signIn: appleEnvironment(), bearer: bearerEnvironment())
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
private func socketConfig(config: PlaygroundBookConfig, webSocket: WebSocketOutput) -> PlaygroundBookSocketConfig {
    .init(config: config, encoder: JSONEncoder(), decoder: JSONDecoder(), webSocket: webSocket)
}
