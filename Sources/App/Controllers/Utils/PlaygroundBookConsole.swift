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
        webSocket.send(command: PlaygroundBookCommand.Outgoing.event(event.playgroundBookEvent))
                 .ignoreError()
                 .provide(self)
    }
}

// MARK: Helpers for extracting information from a PlaygroundBookEvent
private extension nef.ProgressEvent {
    var playgroundBookEvent: NefEditorData.PlaygroundBookEvent {
        .init(information: step.progressDescription,
              currentStep: step.currentStep,
              totalSteps: step.totalSteps,
              status: status.eventStatus)
    }
}

private extension nef.ProgressEventStatus {
    var eventStatus: NefEditorData.PlaygroundBookEvent.Status {
        switch self {
        case .inProgress: return .running
        case .successful: return .succesful
        case .failed: return .failed
        }
    }
}

// MARK: helpers for ignoring the Error in EnvIO
private extension EnvIO where A == Void {
    func ignoreError<E: Swift.Error, EE: Swift.Error>() -> EnvIO<D, EE, Void> where F == IOPartial<E> {
        handleError { _ in }^.mapError { e in e as! EE }
    }
}
