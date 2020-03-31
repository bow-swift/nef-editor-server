import Foundation

extension DispatchTimeInterval {
    var double: Double? {
        switch self {
        case .seconds(let value): return Double(value)
        case .milliseconds(let value): return Double(value) * 0.001
        case .microseconds(let value): return Double(value) * 0.000_001
        case .nanoseconds(let value): return Double(value) * 0.000_000_001
        case .never: return nil
        @unknown default: return nil
        }
    }
}
