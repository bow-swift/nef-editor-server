import Foundation

public enum HTTPHeaderError: Error {
    case encoding(Error? = nil)
}
