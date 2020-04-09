import Foundation
import NefEditorCrypto
import SwiftCheck
import CryptoKit


extension Curve25519.Signing.PrivateKey: Arbitrary {
    public static var arbitrary: Gen<Curve25519.Signing.PrivateKey> {
        Gen<Curve25519.Signing.PrivateKey>.pure(.init())
    }
}

extension Curve25519.Signing.PublicKey: Arbitrary {
    public static var arbitrary: Gen<Curve25519.Signing.PublicKey> {
        Curve25519.Signing.PrivateKey.arbitrary.map { privateKey in privateKey.publicKey }
    }
}
