import Vapor
import AppleSignIn

struct RouteRegister {
    let app: Application
    
    func playgroundBook() throws {
        let controller = PlaygroundBookController(playgroundBook: PlaygroundBookServer(), config: config)
        app.webSocket("playgroundBook", onUpgrade: controller.handler)
    }
    
    func appleSignIn() throws {
        guard let p8Key = Environment.get("p8Key"),
              let teamId = Environment.get("teamId"),
              let keyId = Environment.get("keyId"),
              let clientId = Environment.get("clientId"),
              let redirectURI = Environment.get("redirectURI") else {
                throw Abort(.internalServerError, reason: "credentials not found")
        }

        let client = AppleSignInClient()
        let apiConfig = API.Config(basePath: "https://appleid.apple.com").appending(contentType: .wwwFormUrlencoded)
        let environment = AppleSignInEnvironment(p8Key: p8Key,
                                                 teamId: teamId,
                                                 keyId: keyId,
                                                 clientId: clientId,
                                                 redirectURI: redirectURI)
        
        let controller = AppleSignInController(client: client, apiConfig: apiConfig, environment: environment)
        app.post("signin", use: controller.handle)
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
