import Foundation

public typealias HTTPHeaders = [String: Any]

public extension HTTPHeaders {
    var signatureValue: Data? {
        guard let signature = self[i18n.HTTPHeaders.signature] as? String else { return nil }
        return signature.data(using: .isoLatin1)
    }
}


internal extension HTTPHeaders {
    func encode() -> Result<Data, HTTPHeaderError> {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
            return .success(jsonData)
        } catch {
            return .failure(.encoding())
        }
    }
}
