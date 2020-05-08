import Foundation
import nef
import Bow
import BowEffects
import NefEditorData
import NefEditorUtils


final class PlaygroundBookServer: PlaygroundBook {
    
    func build(command text: String) -> EnvIO<PlaygroundBookConfig, PlaygroundBookError, PlaygroundBookGenerated> {
        let command = EnvIO<PlaygroundBookConfig, PlaygroundBookError, PlaygroundBookCommand.Incoming>.var()
        let output = EnvIO<PlaygroundBookConfig, PlaygroundBookError, PlaygroundBookGenerated>.var()
        
        return binding(
            command <- self.getCommand(text: text),
             output <- self.buildPlaygroundBook(command: command.get),
        yield: output.get)^.report()
    }
    
    private func getCommand(text: String) -> EnvIO<PlaygroundBookConfig, PlaygroundBookError, PlaygroundBookCommand.Incoming> {
        guard let data = text.data(using: .utf8) else {
            return .raiseError(PlaygroundBookError.commandCodification)^
        }
            
        let env = EnvIO<PlaygroundBookConfig, PlaygroundBookError, PlaygroundBookConfig>.var()
        let command = EnvIO<PlaygroundBookConfig, PlaygroundBookError, PlaygroundBookCommand.Incoming>.var()
        
        return binding(
            env <- .ask(),
            command <- env.get.commandDecoder
                              .safeDecode(PlaygroundBookCommand.Incoming.self, from: data)
                              .mapError { e in .invalidCommand(e) },
        yield: command.get)^
    }
    
    private func buildPlaygroundBook(command: PlaygroundBookCommand.Incoming) -> EnvIO<PlaygroundBookConfig, PlaygroundBookError, PlaygroundBookGenerated> {
        switch command {
        case .recipe(let recipe):
            return buildPlaygroundBook(recipe)
        case .unsupported:
            return .raiseError(PlaygroundBookError.unsupportedCommand)^
        }
    }
    
    private func buildPlaygroundBook(_ recipe: PlaygroundRecipe) -> EnvIO<PlaygroundBookConfig, PlaygroundBookError, PlaygroundBookGenerated> {
        buildPlaygroundBook(recipe)
            .map { data in PlaygroundBookGenerated(name: recipe.name, zip: data) }^
    }
    
    private func buildPlaygroundBook(_ recipe: PlaygroundRecipe, at url: URL) -> EnvIO<PlaygroundBookConfig, PlaygroundBookError, URL> {
        let package = recipe.swiftPackage
        let render = nef.SwiftPlayground.render(packageContent: package.content,
                                                name: package.name,
                                                output: url)
        
        return render
            .contramap { env in env.console }
            .mapError { e in .renderRecipe(e) }^
    }
    
    private func buildPlaygroundBook(_ recipe: PlaygroundRecipe) -> EnvIO<PlaygroundBookConfig, PlaygroundBookError, Data> {
        func zipItem(_ url: URL) -> EnvIO<PlaygroundBookConfig, PlaygroundBookError, Data> {
            url.zipIO(name: recipe.name)
                .mapError { e in .zipRecipe(e) }
                .contramap(\.fileManager)
        }
        
        return EnvIO { env in
            env.resource.use { url in
                self.buildPlaygroundBook(recipe, at: url)
                    .flatMap(zipItem)^
                    .provide(env)
            }
        }
    }
}
