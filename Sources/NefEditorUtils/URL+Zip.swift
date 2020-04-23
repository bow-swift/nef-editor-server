import Foundation
import ZIPFoundation
import Bow
import BowEffects


public extension URL {
    
    func zipIO(name: String) -> EnvIO<FileManager, Error, Data> {
        EnvIO.invoke { fileManager in
            do {
                let zipURL = self.deletingLastPathComponent().appendingPathComponent("\(name).zip")
                try fileManager.zipItem(at: self, to: zipURL)
                return try Data(contentsOf: zipURL)
            } catch {
                throw error
            }
        }^
    }
}
