import Foundation

public enum SignatureError: Error {
    case encoding(Error)
    case creating(Error)
}
