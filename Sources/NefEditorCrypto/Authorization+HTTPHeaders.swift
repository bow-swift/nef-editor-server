import Foundation

public extension Authorization {
    
    func encode() -> Result<HTTPHeaders, HTTPHeaderError> {
        do {
            let data = try JSONEncoder().encode(self)
            let rawHeaders = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                
            if let headers = rawHeaders as? HTTPHeaders {
                return .success(headers)
            } else {
                return .failure(.encoding())
            }
        } catch {
            return .failure(.encoding(error))
        }
    }
}

public extension HTTPHeaders {
    
    func decode() -> Result<Authorization, HTTPHeaderError> {
        encode().flatMap { data in
            do {
                let auth = try JSONDecoder().decode(Authorization.self, from: data)
                return .success(auth)
            } catch {
                return .failure(.encoding(error))
            }
        }
    }
}
