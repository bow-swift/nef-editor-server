import Vapor
import nef
import Bow
import BowEffects
import NefEditorData

final class PlaygroundBookConsole: nef.ProgressReport, HasWebSocketOutput, HasCommandEncoder {
    let webSocket: WebSocketOutput
    let commandEncoder: Encoder
    
    init(webSocket: WebSocketOutput, encoder: Encoder) {
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
        case .successful: return .successful
        case .failed: return .failed
        }
    }
}
