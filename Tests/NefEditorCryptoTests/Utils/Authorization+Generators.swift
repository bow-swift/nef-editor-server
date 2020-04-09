import Foundation
import NefEditorCrypto
import SwiftCheck

extension Authorization: Arbitrary {
    public static var arbitrary: Gen<Authorization> {
        String.arbitrary.map { string in
            Authorization(userId: UUID(),
                          domain: string,
                          createdAt: Date())
        }
    }
}
