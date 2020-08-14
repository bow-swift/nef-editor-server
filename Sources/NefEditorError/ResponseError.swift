import Foundation

public struct ErrorResponse<T: Codable>: Error, Codable {
    public let error: Bool
    public let reason: T
}
