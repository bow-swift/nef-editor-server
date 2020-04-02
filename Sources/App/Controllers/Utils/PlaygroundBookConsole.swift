import Vapor
import nef
import Bow
import BowEffects

final class PlaygroundBookConsole: nef.Console {
    private let config: WebSocketConfig
    
    init(config: WebSocketConfig) {
        self.config = config
    }
    
    func printStep<E: Swift.Error>(step: Step, information: String) -> IO<E, Void> {
        update(step: step, information: [information], status: .running).provide(config)
    }
    
    func printSubstep<E: Swift.Error>(step: Step, information: [String]) -> IO<E, Void> {
        update(step: step, information: information, status: .running).provide(config)
    }
    
    func printStatus<E: Swift.Error>(success: Bool) -> IO<E, Void> {
        update(step: Step.empty, information: [], status: success ? .succesful : .failure).provide(config)
    }
    
    func printStatus<E: Swift.Error>(information: String, success: Bool) -> IO<E, Void> {
        update(step: Step.empty, information: [information], status: success ? .succesful : .failure).provide(config)
    }
    
    // MARK: internal helpers
    private func update<E: Swift.Error>(step: Step, information: [String], status: PlaygroundBookStatus.Status) -> EnvIO<WebSocketConfig, E, Void> {
        let stepInfo = PlaygroundBookStatus.Step(information: information.joined(separator: "\n"), status: status)
        let outgoing = PlaygroundBookCommand.Outgoing.status(.init(step: stepInfo, progress: 0))
        
        return EnvIO<WebSocketConfig, WebSocketError, Void>.lazy()^
            .send(command: outgoing)
            .ignoreError()
    }
}

extension Step: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.partial == rhs.partial &&
        lhs.total == rhs.total
    }
}

extension EnvIO where A == Void {
    func ignoreError<E: Swift.Error, EE: Swift.Error>() -> EnvIO<D, EE, Void> where F == IOPartial<E> {
        handleError { _ in }^.mapError { e in e as! EE}
    }
}
