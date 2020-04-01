import Vapor
import nef
import Bow
import BowEffects
import Models

final class PlaygroundBookConsole: nef.Console {
    private let webSocket: WebSocket
    
    private var historical: [PlaygroundBookStatus.Task] = []
    private var lastStep: Step = .empty
    
    init(webSocket: WebSocket) {
        self.webSocket = webSocket
    }
    
    func printStep<E: Swift.Error>(step: Step, information: String) -> IO<E, Void> {
        IO.invoke { self.update(step: step, information: [information], state: .running) }^
    }
    
    func printSubstep<E: Swift.Error>(step: Step, information: [String]) -> IO<E, Void> {
        IO.invoke { self.update(step: step, information: information, state: .running) }^
    }
    
    func printStatus<E: Swift.Error>(success: Bool) -> IO<E, Void> {
        IO.invoke { self.update(step: Step.empty, information: [], state: success ? .succesful : .failure) }^
    }
    
    func printStatus<E: Swift.Error>(information: String, success: Bool) -> IO<E, Void> {
        IO.invoke { self.update(step: Step.empty, information: [information], state: success ? .succesful : .failure) }^
    }
    
    // MARK: internal helpers
    private func update(step: Step, information: [String], state: PlaygroundBookStatus.State) {
        let currentStep = step == .empty ? self.lastStep : step
        let progress = (max(Double(currentStep.partial), 0) / max(Double(currentStep.total), 1)) * 100.0
        
        let currentTask = PlaygroundBookStatus.Task(information: information,
                                                    durationInSeconds: step.estimatedDuration.double ?? 0,
                                                    state: state)
        
        webSocket.send(.status(.init(progress: progress,
                                     historical: self.historical,
                                     currentTask: currentTask)))
        
        // update state
        lastStep = currentStep
        historical = historical.append(currentTask)
    }
}

extension Step: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.partial == rhs.partial &&
        lhs.total == rhs.total
    }
}
