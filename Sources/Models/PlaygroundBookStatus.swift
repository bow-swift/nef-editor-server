import Foundation

public struct PlaygroundBookStatus: Codable {
    public enum State: String, Codable {
        case failure
        case succesful
        case running
    }
    
    public struct Task: Codable {
        let information: [String]
        let durationInSeconds: Double
        let state: PlaygroundBookStatus.State
        
        public init(information: [String], durationInSeconds: Double, state: PlaygroundBookStatus.State) {
            self.information = information
            self.durationInSeconds = durationInSeconds
            self.state = state
        }
    }
    
    public let progress: Double
    public let historical: [Task]
    public let currentTask: Task
    
    public init(progress: Double, historical: [Task], currentTask: Task) {
        self.progress = progress
        self.historical = historical
        self.currentTask = currentTask
    }
}
