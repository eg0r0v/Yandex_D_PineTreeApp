//
//  NatureLoverViewModel.swift
//  PineTreeApp
//
//  Created by Илья Егоров on 19.11.2022.
//

import Foundation

final class NatureLoverViewModel: ViewModelProtocol {

    var lastName: String? {
        get {
            UserDefaults.standard.string(forKey: lastNameKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: lastNameKey)
        }
    }
    
    private var senderId: String!
    private weak var output: ViewModelOutput?
    private var checkName: String?
    private var checkNameBlock: ((Bool) -> Void)?
    
    private var lastMessage: Message?
    private let lastNameKey = "lastNameKey"
    
    init(output: ViewModelOutput) {
        self.output = output
        setupMultipeerEventHandlers()
    }
    
    func check(name: String, completion: @escaping (Bool) -> Void) {
        guard checkNameBlock == nil else { return completion(false) }
        let checkNameModel = CheckNameModel(senderId: name)
        ConnectionManager.sendEvent(.checkName, object: ["model": checkNameModel])
        checkName = name
        checkNameBlock = completion
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            if self?.checkNameBlock != nil {
                self?.checkNameBlock = nil
                ConnectionManager.resetTransceiver()
                completion(false)
            }
        }
    }
    
    func send(text: String) {
        let message = Message(senderId: senderId, message: text, date: Date())
        ConnectionManager.sendEvent(.natureLoverSentMessage, object: ["message": message])
    }
    
    private func setupMultipeerEventHandlers() {
        ConnectionManager.onEvent(.nameChecked) { [weak self] _, object in
            guard let dict = object as? [String: Data], let modelData = dict["model"] else { return }
            let checkNameModel = CheckNameModel(mpcSerialized: modelData)
            
            guard checkNameModel.senderId == self?.checkName else { return }
            self?.checkNameBlock?(checkNameModel.result)
            if checkNameModel.result {
                self?.senderId = self?.checkName
                self?.checkName = nil
                self?.requestHistory()
            }
        }
        
        ConnectionManager.onEvent(.messageHistory) { [weak self] _, object in
            guard let dict = object as? [String: Data], let modelData = dict["messageHistory"] else { return }
    
            let messageHistory = MessageHistory(mpcSerialized: modelData)
            
            guard messageHistory.peerId == self?.senderId else { return }
            
            for message in messageHistory.messages {
                self?.output?.display(message: message)
            }
            self?.lastMessage = messageHistory.messages.last
            self?.checkNameBlock = nil
        }
        
        ConnectionManager.onEvent(.pineTreeMessage) { [weak self] _, object in
            guard let dict = object as? [String: Data], let messageData = dict["message"] else { return }
            let message = Message(mpcSerialized: messageData)
            self?.output?.display(message: message)
            self?.lastMessage = message
        }
        
        ConnectionManager.onConnect { [weak self] _, _ in
            if self?.senderId != nil {
                self?.requestHistory()
            }
        }
        
        ConnectionManager.onDisconnect { peerID, myPeerID in
            if peerID == myPeerID {
                ConnectionManager.resetTransceiver()
            }
        }
    }
    
    private func requestHistory() {
        let messageHistoryRequest = MessageHistory(
            peerId: senderId,
            messages: [lastMessage].compactMap({ $0 })
        )
        ConnectionManager.sendEvent(.restoreHistory, object: ["model": messageHistoryRequest])
    }
}
