import Foundation

struct MessageHistory: Codable, MPCSerializable {
    
    let peerId: String
    let messages: [Message]
    
    var mpcSerialized: Data {
        return try! JSONEncoder().encode(self)
    }
    
    init(peerId: String, messages: [Message]) {
        self.peerId = peerId
        self.messages = messages
    }
    
    init(mpcSerialized: Data) {
        self = try! JSONDecoder().decode(MessageHistory.self, from: mpcSerialized)
    }
}
