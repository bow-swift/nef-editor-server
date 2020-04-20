import Vapor
import AppleSignIn

struct RouteRegister {
    let app: Application
    
    func playgroundBook(config: @escaping (WebSocketOutput) -> PlaygroundBookConfig) {
        let controller = PlaygroundBookController(playgroundBook: PlaygroundBookServer(),
                                                  config: config)
        
        app.webSocket("playgroundBook", onUpgrade: controller.handler)
    }
    
    func appleSignIn() {
        let controller = AppleSignInController(client: AppleSignInClient(),
                                               apiConfig: API.Config(basePath: "https://appleid.apple.com"))
        
        app.post("signin", use: controller.handle)
    }
}
