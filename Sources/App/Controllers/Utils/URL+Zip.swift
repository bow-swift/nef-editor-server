import Foundation
import Bow
import BowEffects
import ZIPFoundation

extension URL {
    
    func zipIO(name: String) -> EnvIO<FileManager, Error, Data> {
        EnvIO.invoke { fileManager in
            do {
                let name = name.lowercased().replacingFirstOccurrence(of: " ", with: "-")
                let zipURL = self.deletingLastPathComponent().appendingPathComponent("\(name).zip")
                try fileManager.zipItem(at: self, to: zipURL)
                return try Data(contentsOf: zipURL)
            } catch {
                throw error
            }
        }^
    }
}
