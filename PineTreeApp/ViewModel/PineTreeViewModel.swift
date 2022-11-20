import MultipeerConnectivity

final class PineTreeViewModel: ViewModelProtocol {
    private final class MessageNode {
        let message: Message
        var next: MessageNode?
        
        init(message: Message) {
            self.message = message
        }
    }
    
    private var firstMessageNode: MessageNode?
    private var lastMessageNode: MessageNode?
    
    private var activeNames = [MCPeerID: String]()
    
    private weak var output: ViewModelOutput?
    
    init(output: ViewModelOutput) {
        self.output = output
        setupMultipeerEventHandlers()
    }
    
    private func setupMultipeerEventHandlers() {
        ConnectionManager.onEvent(.checkName) { [weak self] peerId, object in
            guard let dict = object as? [String: Data], let model = dict["model"] else { return }
            let checkNameModel = CheckNameModel(mpcSerialized: model)
            self?.checkName(peerId: peerId, model: checkNameModel)
        }
        
        ConnectionManager.onEvent(.restoreHistory) { [weak self] peerID, object in
            guard let dict = object as? [String: Data], let modelData = dict["model"] else { return }
            let messageHistoryRequest = MessageHistory(mpcSerialized: modelData)
            
            self?.sendMessageHistory(request: messageHistoryRequest)
        }
        
        ConnectionManager.onEvent(.natureLoverSentMessage) { [weak self] peerID, object in
            guard let dict = object as? [String: Data], let messageData = dict["message"] else { return }
            let message = Message(mpcSerialized: messageData)
            self?.add(message: message)
        }
        
        ConnectionManager.onDisconnect { [weak self] peerID, myPeerID in
            self?.activeNames[peerID] = nil
        }
    }
    
    private func checkName(peerId: MCPeerID, model: CheckNameModel) {
        let response = CheckNameModel(
            senderId: model.senderId,
            result:
                activeNames[peerId] == nil ||
                activeNames[peerId] == model.senderId
        )
        if activeNames[peerId] == nil {
            activeNames[peerId] = model.senderId
        }
        ConnectionManager.sendEvent(.nameChecked, object: ["model": response])
        output?.display(message: .init(
            senderId: "Check Name",
            message: "Pine Tree \(response.result ? "accepted" : "rejected") the name \(response.senderId)"
        ))
    }
    
    private func sendMessageHistory(request: MessageHistory) {
        let peerId = request.peerId
        let lastMessage = request.messages.first
        var messageNodeIterator = firstMessageNode
        
        var messages: [Message] = []
        while let message = messageNodeIterator?.message {
            let shouldAppendToHistory: Bool
            if let lastUpdateDate = lastMessage?.date {
                shouldAppendToHistory = message.date > lastUpdateDate
            } else {
                shouldAppendToHistory = true
            }
            
            if shouldAppendToHistory {
                messages.append(message)
            }
            
            messageNodeIterator = messageNodeIterator?.next
        }
        
        let messageHistory = MessageHistory(peerId: peerId, messages: messages)
        ConnectionManager.sendEvent(.messageHistory, object: ["messageHistory": messageHistory])
        output?.display(message: .init(
            senderId: "Restore History",
            message: "Pine Tree sent message history to peer \(peerId)"
        ))
    }
    
    private func add(message: Message) {
        let newNode = MessageNode(message: message)
        
        if lastMessageNode == nil {
            firstMessageNode = newNode
        } else {
            lastMessageNode?.next = newNode
        }
        lastMessageNode = newNode
        ConnectionManager.sendEvent(.pineTreeMessage, object: ["message": newNode.message])
        
        output?.display(message: .init(
            senderId: "Message",
            message: "Pine Tree distributed message from peer \(message.senderId)"
        ))
    }
}
