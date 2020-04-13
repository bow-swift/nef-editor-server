import Foundation

enum AppleSignInError: Error {
    case invalidHttpMethod
    case request(Error)
    case response(Error)
    case encoding
}
