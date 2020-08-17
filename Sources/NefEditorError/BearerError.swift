import Foundation

public enum BearerError: Error {
    case encodingRS256Key
    case signing
    case invalidPayload(PayloadError)
    case invalidIssuer
    case invalidIssuedAt
    case expiredJWT
}

public enum PayloadError: String, Error, Codable {
    case jwt
    case appleToken
}


// MARK: - Codable
extension BearerError: Codable {
    private enum CodingKeys: String, CodingKey {
        case encodingRS256Key
        case signing
        case invalidPayload
        case invalidIssuer
        case invalidIssuedAt
        case expiredJWT
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .encodingRS256Key:
            try container.encode(BearerError.encodingRS256Key, forKey: .encodingRS256Key)
        case .signing:
            try container.encode(BearerError.signing, forKey: .signing)
        case .invalidPayload(let error):
            try container.encode(error, forKey: .invalidPayload)
        case .invalidIssuer:
            try container.encode(BearerError.invalidIssuer, forKey: .invalidIssuer)
        case .invalidIssuedAt:
            try container.encode(BearerError.invalidIssuedAt, forKey: .invalidIssuedAt)
        case .expiredJWT:
            try container.encode(BearerError.expiredJWT, forKey: .expiredJWT)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let _ = try? container.decode(BearerError.self, forKey: .encodingRS256Key) {
            self = .encodingRS256Key
        } else if let _ = try? container.decode(BearerError.self, forKey: .invalidIssuer) {
            self = .invalidIssuer
        } else if let _ = try? container.decode(BearerError.self, forKey: .invalidIssuedAt) {
            self = .invalidIssuedAt
        } else if let _ = try? container.decode(BearerError.self, forKey: .expiredJWT) {
            self = .expiredJWT
        } else if let _ = try? container.decode(BearerError.self, forKey: .signing) {
            self = .signing
        } else if let invalidPayload = try? container.decode(PayloadError.self, forKey: .invalidPayload) {
            self = .invalidPayload(invalidPayload)
        } else {
            throw GeneralError.keyNotFound
        }
    }
}
