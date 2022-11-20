import Foundation

struct Message: Codable, MPCSerializable {
    let senderId: String
    let message: String
    let date: Date
    
    var mpcSerialized: Data {
        return try! JSONEncoder().encode(self)
    }
    
    init(
        senderId: String,
        message: String,
        date: Date = Date()
    ) {
        self.senderId = senderId
        self.message = message
        self.date = date
    }
    
    init(mpcSerialized: Data) {
        self = try! JSONDecoder().decode(Message.self, from: mpcSerialized)
    }
}
