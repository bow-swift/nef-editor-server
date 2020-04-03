import Foundation

struct PlaygroundBookStatus: Codable {
    enum Status: String, Codable {
        case failure
        case succesful
        case running
    }
    
    struct Step: Codable {
        let information: String
        let status: PlaygroundBookStatus.Status
    }
    
    let step: Step
    let progress: Double
}
