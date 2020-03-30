import Foundation

struct PlaygroundBookStatus: Codable {
    enum State: String, Codable {
        case failure
        case succesful
        case running
    }
    
    struct Task: Codable {
        let information: [String]
        let durationInSeconds: UInt
        let state: PlaygroundBookStatus.State
    }
    
    let totalSteps: UInt
    let currentStep: UInt
    let historical: [Task]
    let currentTask: Task
}
