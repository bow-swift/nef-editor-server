import Vapor
import nef
import Bow
import BowEffects
import NefEditorData

final class AppleSignInServer: AppleSignIn {
    
    func signIn() -> EnvIO<Request, AppleSignInError, AppleSignInResponse> {
        let keys = EnvIO<Request, AppleSignInError, AppleKeys>.var()
        let response = EnvIO<Request, AppleSignInError, AppleSignInResponse>.var()
        
        return binding(
                keys <- self.getAppleKeys(),
            response <- self.dummyResponse(),
        yield: response.get)^
    }
    
    private func dummyResponse() -> EnvIO<Request, AppleSignInError, AppleSignInResponse> {
        EnvIO { _ in
            IO.pure(AppleSignInResponse.init(token: "dummy response"))^
        }
    }
    
    private func getAppleKeys() -> EnvIO<Request, AppleSignInError, AppleKeys> {
        let appleKeys = URI(string: "https://appleid.apple.com/auth/keys")
        return get(uri: appleKeys).mapError { e in AppleSignInError.response(e) }
    }
    
    private func get<A: Decodable>(uri: URI) -> EnvIO<Request, Swift.Error, A> {
        fatalError()
    }
}
