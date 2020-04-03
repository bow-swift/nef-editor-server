import BowEffects

protocol PlaygroundBook {
    func build(command text: String) -> EnvIO<PlaygroundBookConfig, PlaygroundBookCommandError, PlaygroundBookGenerated>
}
