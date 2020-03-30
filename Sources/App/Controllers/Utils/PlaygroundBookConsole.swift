import Vapor
import nef
import Bow
import BowEffects

final class PlaygroundBookConsole: nef.Console {
    private let webSocket: WebSocket
    
    private let historical: [PlaygroundBookStatus.Task] = []
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
    
    func printStatus<E: Swift.Error>(step: Step, success: Bool) -> IO<E, Void> {
        IO.invoke { self.update(step: step, information: [], state: success ? .succesful : .failure) }^
    }
    
    func printStatus<E: Swift.Error>(step: Step, information: String, success: Bool) -> IO<E, Void> {
        IO.invoke { self.update(step: step, information: [information], state: success ? .succesful : .failure) }^
    }
    
    func printStatus<E: Swift.Error>(success: Bool) -> IO<E, Void> {
        IO.invoke { self.update(step: Step.empty, information: [], state: success ? .succesful : .failure) }^
    }
    
    func printStatus<E: Swift.Error>(information: String, success: Bool) -> IO<E, Void> {
        IO.invoke { self.update(step: Step.empty, information: [information], state: success ? .succesful : .failure) }^
    }
    
    // MARK: internal helpers
    private func update(step: Step, information: [String], state: PlaygroundBookStatus.State) {
        let currentStep = step == .empty ? lastStep : step
//        self.totalSteps  = step.total
//        self.currentStep = step.partial
//
//        self.task = step.total == step.partial ? "Completed!"
//                                               : status == .failure ? "Error!" : task
//        self.details = details.isEmpty ? self.details : details.joined(separator: " - ")
//        self.historical = self.lastTasks.map { "✓ \($0)"}.joined(separator: "\n")
//
//        self.status  = status
//        self.duration = step.estimatedDuration
//
//        if !task.isEmpty { self.lastTasks.insert(task, at: 0) }
    }
}

extension Step: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.partial == rhs.partial &&
        lhs.total == rhs.total &&
        lhs.estimatedDuration == rhs.estimatedDuration
    }
}
