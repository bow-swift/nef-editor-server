import Foundation

struct PlaygroundBookStatus: Codable {
    enum State: String, Codable {
        case failure
        case succesful
        case running
    }
    
    struct Task: Codable {
        let information: [String]
        let durationInSeconds: Double
        let state: PlaygroundBookStatus.State
    }
    
    let progress: Double
    let historical: [Task]
    let currentTask: Task
}
