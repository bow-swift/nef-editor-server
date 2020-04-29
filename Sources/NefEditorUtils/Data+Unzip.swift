import Foundation
import ZIPFoundation
import Bow
import BowEffects


public extension Data {
    
    func unzipIO(output: URL, name: String) -> EnvIO<FileManager, Error, URL> {
        EnvIO.invoke { fileManager in
            let sourceURL = output.appendingPathComponent("\(name).zip")
            let destinationURL = output.appendingPathComponent(name)
            
            try self.write(to: sourceURL)
            try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
            try fileManager.unzipItem(at: sourceURL, to: destinationURL)
            
            return destinationURL
        }
    }
}
