import BowEffects

protocol Authorization {
    func verify(_ bearer: String) -> EnvIO<BearerEnvironment, BearerError, BearerPayload>
}
