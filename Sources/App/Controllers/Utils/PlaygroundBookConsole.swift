import Vapor
import nef
import Bow
import BowEffects
import NefEditorData

final class PlaygroundBookConsole: nef.ProgressReport, HasWebSocketOutput, HasCommandEncoder {
    let webSocket: WebSocketOutput
    let commandEncoder: RequestEncoder
    
    init(webSocket: WebSocketOutput, encoder: RequestEncoder) {
        self.webSocket = webSocket
        self.commandEncoder = encoder
    }
    
    func notify<E: Swift.Error, A: CustomProgressDescription>(_ event: ProgressEvent<A>) -> IO<E, Void> {
        guard let event = event as? ProgressEvent<PlaygroundBookEvent> else {
            fatalError("received invalid event")
        }
        
        return webSocket.send(command: PlaygroundBookCommand.Outgoing.status(event.playgroundBookStatus))
                        .ignoreError()
                        .provide(self)
    }
}

private extension EnvIO where A == Void {
    func ignoreError<E: Swift.Error, EE: Swift.Error>() -> EnvIO<D, EE, Void> where F == IOPartial<E> {
        handleError { _ in }^.mapError { e in e as! EE }
    }
}

private extension nef.ProgressEvent where A == PlaygroundBookEvent {
    var playgroundBookStatus: PlaygroundBookStatus {
        .init(step: .init(information: step.progressDescription,
                          status: status.stepStatus),
              progress: step.progressPercentage)
    }
}

private extension nef.PlaygroundBookEvent {
    var progressPercentage: Double {
        let cases: Double = 5
        
        switch self {
        case .cleanup:
            return (1/cases) * 100
        case .creatingStructure:
            return (2/cases) * 100
        case .downloadingDependencies:
            return (3/cases) * 100
        case .gettingModules:
            return (4/cases) * 100
        case .buildingPlayground:
            return (5/cases) * 100
        }
    }
}

private extension nef.ProgressEventStatus {
    var stepStatus: PlaygroundBookStatus.Status {
        switch self {
        case .inProgress: return .running
        case .successful: return .succesful
        case .failed: return .failed
        }
    }
}
