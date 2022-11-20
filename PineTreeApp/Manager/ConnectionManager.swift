import Foundation
import PeerKit
import MultipeerConnectivity

protocol MPCSerializable {
    var mpcSerialized: Data { get }
    init(mpcSerialized: Data)
}

enum Event: String {
    case checkName
    case nameChecked
    case restoreHistory
    case messageHistory
    case natureLoverSentMessage
    case pineTreeMessage
}

struct ConnectionManager {

    // MARK: Properties

    private static var peers: [MCPeerID] {
        return PeerKit.session?.connectedPeers as [MCPeerID]? ?? []
    }

    // MARK: Start

    static func start() {
        PeerKit.transceive(serviceType: "pineTree")
    }
    
    static func resetTransceiver() {
        PeerKit.transceiver = .init(displayName: PeerKit.myName)
        PeerKit.transceive(serviceType: "pineTree")
    }
    
    static func stop() {
        PeerKit.stopTransceiving()
    }
    
    // MARK: Event Handling

    static func onConnect(_ run: PeerBlock?) {
        PeerKit.onConnect = run
    }

    static func onDisconnect(_ run: PeerBlock?) {
        PeerKit.onDisconnect = run
    }

    static func onEvent(_ event: Event, run: ObjectBlock?) {
        if let run = run {
            PeerKit.eventBlocks[event.rawValue] = run
        } else {
            PeerKit.eventBlocks.removeValue(forKey: event.rawValue)
        }
    }

    // MARK: Sending

    static func sendEvent(_ event: Event, object: [String: MPCSerializable]? = nil,
                          toPeers peers: [MCPeerID]? = PeerKit.session?.connectedPeers) {
        var anyObject: [String: Data]?
        if let object = object {
            anyObject = [String: Data]()
            for (key, value) in object {
                anyObject![key] = value.mpcSerialized
            }
        }
        PeerKit.sendEvent(event.rawValue, object: anyObject as AnyObject, toPeers: peers)
    }
}
