import Vapor

struct RouteRegister {
    let app: Application
    
    func playgroundBook(config: @escaping (WebSocketOutput) -> PlaygroundBookConfig) {
        let controller = PlaygroundBookController(playgroundBook: PlaygroundBookServer(), config: config)
        app.webSocket("playgroundBook", onUpgrade: controller.handler)
    }
    
    func appleSignIn() {
        app.get("signin", use: AppleSignInController(apple: AppleSignInServer()).handle)
    }
}
