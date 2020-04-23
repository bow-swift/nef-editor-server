import Foundation

enum JWTError: Error {
    case appleKeysNotFound
    case decrypt(Error)
    case invalidClientID
    case invalidIssuer
    case invalidUserID
    case expiredJWT
}
