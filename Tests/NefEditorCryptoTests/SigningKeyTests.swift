import NefEditorCrypto
import CryptoKit
import SwiftCheck
import XCTest

final class SigningKeyTests: XCTestCase {
    
    func testSigningKey() {
        property("verify signature for headers with the pair private/public") <- forAll(String.arbitrary, String.arbitrary, Curve25519.Signing.PrivateKey.arbitrary) { (key, value, signingKey) in
            var headers = HTTPHeaders()
            headers[key] = value
            
            let result = signingKey.addSignature(to: headers)
            
            if case let .success(httpHeaders) = result,
               let signature = httpHeaders.signatureValue {
                return signingKey.publicKey.isValidSignature(signature, for: headers)
            } else {
                return false
            }
        }
        
        property("raw a private-key and initialize using this raw should return the same signing key") <- forAll(Curve25519.Signing.PrivateKey.arbitrary) { (signingKey) in
            let privateKeyRaw = signingKey.raw
            
            if let privateKey = Curve25519.Signing.PrivateKey.signingKey(raw: privateKeyRaw) {
                return privateKey.rawRepresentation == signingKey.rawRepresentation
            } else {
                return false
            }
        }
        
        property("raw a public-key and initialize using this raw should return the same signing key") <- forAll(Curve25519.Signing.PublicKey.arbitrary) { (signingKey) in
            let publicKeyRaw = signingKey.raw
            
            if let publicKey = Curve25519.Signing.PublicKey.signingKey(raw: publicKeyRaw) {
                return publicKey.rawRepresentation == signingKey.rawRepresentation
            } else {
                return false
            }
        }
        
        property("must fails the validation if update headers after signing them") <- forAll(String.arbitrary, String.arbitrary, Curve25519.Signing.PrivateKey.arbitrary) { (key, value, signingKey) in
            var headers = HTTPHeaders()
            headers[key] = value
            let result = signingKey.addSignature(to: headers)
            headers[key] = "\(value)_updated"
            
            if case let .success(httpHeaders) = result,
               let signature = httpHeaders.signatureValue {
                return signingKey.publicKey.isValidSignature(signature, for: headers) == false
            } else {
                return false
            }
        }
    }
}



