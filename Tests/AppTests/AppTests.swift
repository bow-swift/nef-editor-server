import XCTVapor
@testable import App

final class AppTests: XCTestCase {
    
    func testAppleClientSecretSigned() {
        let p8key = "-----BEGIN PRIVATE KEY-----MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgcPEpOuFcCaMhNRrj\nt5y90XUrsKo2IvcCFbw3fdwo81WgCgYIKoZIzj0DAQehRANCAAR166oZeu1PsEv+\nXdkkaiPiwJWeW3iAC0ekuqOKQlekgkcwC0F7aLNnF8Fxmm1agJ9Iu89G9Y4bwfzH\nm53r/GYZ-----END PRIVATE KEY-----"
        
        let jwt = AppleClientSecret(kid: "J9CD6BW6MF",
                                    payload: .init(iss: "PKCNK63FZQ",
                                                   iat: Date(),
                                                   exp: Date().addingTimeInterval(24*60*60),
                                                   aud: "https://appleid.apple.com",
                                                   sub: "com.47deg.test"))
        
        
        let signed = jwt.sign(p8key: p8key)
        XCTAssertNotNil(try? signed.get())
    }
}
