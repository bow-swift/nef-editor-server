import BowEffects
import NefEditorError

protocol Authorization {
    func verify(_ bearer: String) -> EnvIO<BearerEnvironment, BearerError, Bearer>
}
