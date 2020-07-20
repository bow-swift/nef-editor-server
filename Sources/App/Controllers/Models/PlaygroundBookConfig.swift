import Foundation
import BowEffects
import BowOptics
import nef
import Vapor

protocol HasLogger {
    var logger: Logger { get }
}

// MARK: - PlaygroundBookConfig
typealias PlaygroundBookResource = IOResource<PlaygroundBookError, URL>


struct PlaygroundBookConfig: AutoLens {
    let outputDirectory: URL
    let requestDecoder: Decoder
    let responseEncoder: Encoder
    let fileManager: FileManager
    var progressReport: nef.ProgressReport
    
    init(outputDirectory: URL, requestDecoder: Decoder, responseEncoder: Encoder, progressReport: nef.ProgressReport = EmptyProgressReport(), fileManager: FileManager = .default) {
        self.outputDirectory = outputDirectory
        self.requestDecoder = requestDecoder
        self.responseEncoder = responseEncoder
        self.fileManager = fileManager
        self.progressReport = progressReport
    }
}

extension PlaygroundBookConfig {
    var resource: PlaygroundBookResource {
        PlaygroundBookResource.from(acquire: {
            let output = self.outputDirectory.appendingPathComponent(UUID().uuidString)
            return .pure(output)
        }, release: { url, _ in
            self.fileManager.removeItemIO(at: url).ignoreError()
        })
    }
}

struct PlaygroundBookLogger: HasLogger {
    let config: PlaygroundBookConfig
    let logger: Logger
    
    init(config: PlaygroundBookConfig, logger: Logger) {
        self.logger = logger
        self.config = PlaygroundBookConfig.lens(for: \.progressReport).set(config, VaporProgressReport(logger: logger))
    }
}


// MARK: - PlaygroundBookConfig for WebSockets
struct PlaygroundBookSocketConfig: HasWebSocketOutput, HasCommandCodable {
    let config: PlaygroundBookConfig
    let webSocket: WebSocketOutput
    let commandEncoder: Encoder
    let commandDecoder: Decoder
    
    init(config: PlaygroundBookConfig, encoder: Encoder, decoder: Decoder, webSocket: WebSocketOutput) {
        let console = PlaygroundBookConsole(webSocket: webSocket, encoder: encoder)
        
        self.config = PlaygroundBookConfig.lens(for: \.progressReport).set(config, console)
        self.webSocket = console.webSocket
        self.commandEncoder = console.commandEncoder
        self.commandDecoder = decoder
    }
}


// MARK: - Helpers
private struct EmptyProgressReport: ProgressReport {
    func notify<E: Swift.Error, A: CustomProgressDescription>(_ event: ProgressEvent<A>) -> IO<E, Void> {
        .pure(())^
    }
}

private struct VaporProgressReport: ProgressReport {
    let logger: Logger

    func notify<E: Swift.Error, A: CustomProgressDescription>(_ event: ProgressEvent<A>) -> IO<E, Void> {
        IO.invoke {
            self.logger.info("[\(event.step.currentStep)/\(event.step.totalSteps) - \(event.status)] \(event.step.progressDescription)")
        }^
    }
}
