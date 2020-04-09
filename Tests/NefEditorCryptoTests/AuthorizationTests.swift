import NefEditorCrypto
import CryptoKit
import SwiftCheck
import XCTest

final class AuthorizationTests: XCTestCase {
    
    func testAuthorization() {
        property("encoding/decoding to HTTP Headers should result the same") <- forAll(Authorization.arbitrary) { auth in
            let result = auth.encode().flatMap { headers in headers.decode() }
            
            if case let .success(decoded) = result {
                return auth == decoded
            } else {
                return false
            }
        }
        
        property("given HTTP Headers contains an Authorization should be able to decode it") <- forAll(String.arbitrary, String.arbitrary, Authorization.arbitrary) { (key, value, auth) in
            let resultHeaders: Result<HTTPHeaders, HTTPHeaderError> = auth.encode().map { headers in
                var httpHeaders = headers
                httpHeaders[key] = value
                return httpHeaders
            }
            
            let result = resultHeaders.flatMap { headers in headers.decode() }
            
            if case let .success(decoded) = result {
                return auth == decoded
            } else {
                return false
            }
        }
    }
}
