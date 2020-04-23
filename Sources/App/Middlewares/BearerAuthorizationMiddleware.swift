import Vapor
import Bow
import BowEffects

struct BearerAuthorizationMiddleware: BearerAuthenticator {
    let authorization: Authorization
    let environment: BearerEnvironment
    
    func authenticate(bearer: BearerAuthorization, for request: Request) -> EventLoopFuture<Void> {
        let queue: DispatchQueue = .init(label: String(describing: PlaygroundBookController.self), qos: .userInitiated)
        
        return authorization.verify(bearer.token)
            .provide(environment)
            .map { bearer in request.auth.login(bearer) }^
            .unsafeRunSyncEither(on: queue)
            .eventLoopFuture(for: request)
    }
}
