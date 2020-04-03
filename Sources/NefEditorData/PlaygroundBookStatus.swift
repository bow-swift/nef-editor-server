import Foundation

public struct PlaygroundBookStatus: Codable {
    public enum Status: String, Codable {
        case failure
        case succesful
        case running
    }
    
    public struct Step: Codable {
        public let information: String
        public let status: PlaygroundBookStatus.Status
        
        public init(information: String, status: PlaygroundBookStatus.Status) {
            self.information = information
            self.status = status
        }
    }
    
    public let step: Step
    public let progress: Double
    
    public init(step: Step, progress: Double) {
        self.step = step
        self.progress = progress
    }
}
