import Foundation

public struct Authorization: Codable, Equatable {
    let userId: UUID
    let domain: String
    let createdAt: Date

    public init(userId: UUID, domain: String, createdAt: Date) {
        self.userId = userId
        self.domain = domain
        self.createdAt = createdAt
    }
}
