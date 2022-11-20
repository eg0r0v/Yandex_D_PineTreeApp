import Foundation

struct CheckNameModel: Codable, MPCSerializable {
    let senderId: String
    let result: Bool
    
    var mpcSerialized: Data {
        return try! JSONEncoder().encode(self)
    }
    
    init(
        senderId: String,
        result: Bool = false
    ) {
        self.senderId = senderId
        self.result = result
    }
    
    init(mpcSerialized: Data) {
        self = try! JSONDecoder().decode(CheckNameModel.self, from: mpcSerialized)
    }
}
