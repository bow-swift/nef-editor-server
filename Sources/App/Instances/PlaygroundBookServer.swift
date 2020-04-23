import Foundation
import nef
import Bow
import BowEffects
import NefEditorData
import NefEditorUtils


final class PlaygroundBookServer: PlaygroundBook {
    
    func build(command text: String) -> EnvIO<PlaygroundBookConfig, PlaygroundBookCommandError, PlaygroundBookGenerated> {
        let command = EnvIO<PlaygroundBookConfig, PlaygroundBookCommandError, PlaygroundBookCommand.Incoming>.var()
        let output = EnvIO<PlaygroundBookConfig, PlaygroundBookCommandError, PlaygroundBookGenerated>.var()
        
        return binding(
            command <- self.getCommand(text: text),
             output <- self.buildPlaygroundBook(command: command.get),
        yield: output.get)^.report()
    }
    
    private func getCommand(text: String) -> EnvIO<PlaygroundBookConfig, PlaygroundBookCommandError, PlaygroundBookCommand.Incoming> {
        guard let data = text.data(using: .utf8) else {
            return EnvIO.raiseError(PlaygroundBookCommandError(description: "Unsupported message: \(text)", code: "404"))^
        }
            
        let env = EnvIO<PlaygroundBookConfig, PlaygroundBookCommandError, PlaygroundBookConfig>.var()
        let command = EnvIO<PlaygroundBookConfig, PlaygroundBookCommandError, PlaygroundBookCommand.Incoming>.var()
        
        return binding(
            env <- .ask(),
            command <- env.get.commandDecoder
                              .safeDecode(PlaygroundBookCommand.Incoming.self, from: data)
                              .mapError { e in .init(description: "\(e)", code: "404") },
        yield: command.get)^
    }
    
    private func buildPlaygroundBook(command: PlaygroundBookCommand.Incoming) -> EnvIO<PlaygroundBookConfig, PlaygroundBookCommandError, PlaygroundBookGenerated> {
        switch command {
        case .recipe(let recipe):
            return buildPlaygroundBook(recipe)
        case .unsupported:
            return EnvIO.raiseError(.init(description: "Unsupported command: \(command)", code: "404"))^
        }
    }
    
    private func buildPlaygroundBook(_ recipe: PlaygroundRecipe) -> EnvIO<PlaygroundBookConfig, PlaygroundBookCommandError, PlaygroundBookGenerated> {
        buildPlaygroundBook(recipe)
            .map { data in PlaygroundBookGenerated(name: recipe.name, zip: data) }^
    }
    
    private func buildPlaygroundBook(_ recipe: PlaygroundRecipe) -> EnvIO<PlaygroundBookConfig, PlaygroundBookCommandError, URL> {
        EnvIO { env in
            let package = recipe.swiftPackage
            let render = nef.SwiftPlayground.render(packageContent: package.content,
                                                    name: package.name,
                                                    output: env.outputDirectory)
            
            return render.provide(env.console)
                .mapError { e in .init(description: "\(e)", code: "500") }^
        }
    }
    
    private func buildPlaygroundBook(_ recipe: PlaygroundRecipe) -> EnvIO<PlaygroundBookConfig, PlaygroundBookCommandError, Data> {
        buildPlaygroundBook(recipe)
            .flatMap { url in
                url.zipIO(name: recipe.name)
                    .mapError { e in .init(description: e.localizedDescription, code: "500") }
                    .contramap(\.fileManager)
            }^
    }
}
