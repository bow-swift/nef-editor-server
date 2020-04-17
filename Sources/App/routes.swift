import Vapor
import AppleSignIn

struct RouteRegister {
    let app: Application
    
    func playgroundBook(config: @escaping (WebSocketOutput) -> PlaygroundBookConfig) {
        let controller = PlaygroundBookController(playgroundBook: PlaygroundBookServer(), config: config)
        app.webSocket("playgroundBook", onUpgrade: controller.handler)
    }
    
    func appleSignIn() {
        let client = AppleSignInClient(decoder: JSONDecoder())
        let apiConfig = API.Config(basePath: "https://appleid.apple.com")
            .appending(headers: ["Accept": "application/x-www-form-urlencoded",
                                 "Content-Type": "application/x-www-form-urlencoded"])
        
        let controller = AppleSignInController(client: client, apiConfig: apiConfig)
        app.post("signin", use: controller.handle)
    }
}
