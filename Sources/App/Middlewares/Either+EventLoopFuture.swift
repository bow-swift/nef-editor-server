import Vapor
import Bow

extension Either where A: Error {
    
    func eventLoopFuture(for request: Request) -> EventLoopFuture<Void> {
        self.fold(
            { a in
                request.eventLoop.future(error: a)
            },
            { b in
                request.eventLoop.future()
            }
        )
    }
}
