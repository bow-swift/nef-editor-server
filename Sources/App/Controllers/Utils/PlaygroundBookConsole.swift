import Vapor
import nef
import Bow
import BowEffects

final class PlaygroundBookConsole: nef.Console {
    private let config: WebSocketConfig
    
    private var historical: [PlaygroundBookStatus.Task] = []
    private var lastStep: Step = .empty
    
    init(config: WebSocketConfig) {
        self.config = config
    }
    
    func printStep<E: Swift.Error>(step: Step, information: String) -> IO<E, Void> {
        update(step: step, information: [information], state: .running)
    }
    
    func printSubstep<E: Swift.Error>(step: Step, information: [String]) -> IO<E, Void> {
        update(step: step, information: information, state: .running)
    }
    
    func printStatus<E: Swift.Error>(success: Bool) -> IO<E, Void> {
        update(step: Step.empty, information: [], state: success ? .succesful : .failure)
    }
    
    func printStatus<E: Swift.Error>(information: String, success: Bool) -> IO<E, Void> {
        update(step: Step.empty, information: [information], state: success ? .succesful : .failure)
    }
    
    // MARK: internal helpers
    private func update<E: Swift.Error>(step: Step, information: [String], state: PlaygroundBookStatus.State) -> IO<E, Void> {
        let currentStep = step == .empty ? self.lastStep : step
        let progress = (max(Double(currentStep.partial), 0) / max(Double(currentStep.total), 1)) * 100.0
        
        let currentTask = PlaygroundBookStatus.Task(information: information,
                                                    durationInSeconds: step.estimatedDuration.double ?? 0,
                                                    state: state)
        
        let status = PlaygroundBookStatus(progress: progress,
                                          historical: self.historical,
                                          currentTask: currentTask)
      
        // update state
        lastStep = currentStep
        historical = historical.append(currentTask)
        
        // run send
        return WebSocket.send(PlaygroundBookCommand.Outgoing.status(status))
            .provide(config)^
            .ignoreError()^
    }
}

extension Step: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.partial == rhs.partial &&
        lhs.total == rhs.total
    }
}

extension IO where A == Void {
    func ignoreError<EE: Swift.Error>() -> IO<EE, Void> {
        handleError { _ in }^.mapError { e in e as! EE}
    }
}
