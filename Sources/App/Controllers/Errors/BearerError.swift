import Foundation

enum BearerError: Error {
    case encodingRS256Key
    case signing(Error)
    case invalidPayload(Error)
    case invalidIssuer
    case invalidIssuedAt
    case expiredJWT
}
