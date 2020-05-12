import BowEffects
import NefEditorData

protocol PlaygroundBook {
    func build(command: String) -> EnvIO<PlaygroundBookSocketConfig, PlaygroundBookError, PlaygroundBookGenerated>
    func build(recipe: PlaygroundRecipe) -> EnvIO<PlaygroundBookConfig, PlaygroundBookError, PlaygroundBookGenerated>
}
