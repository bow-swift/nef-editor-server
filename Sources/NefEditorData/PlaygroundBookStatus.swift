import Foundation

public struct PlaygroundBookEvent: Codable {
    public enum Status: String, Codable {
        case failed
        case succesful
        case running
    }
    
    public struct Progress: Codable {
        public let current: UInt
        public let total: UInt
        
        public init(current: UInt, total: UInt) {
            self.current = current
            self.total = total
        }
    }
    
    public let information: String
    public let progress: PlaygroundBookEvent.Progress
    public let status: Status
    
    public init(information: String, currentStep: UInt, totalSteps: UInt, status: PlaygroundBookEvent.Status) {
        self.information = information
        self.progress = .init(current: currentStep, total: totalSteps)
        self.status = status
    }
}
