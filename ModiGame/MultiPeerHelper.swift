import Foundation
import MultipeerConnectivity

protocol ConnectionSceneDelegate {
    func connectedDevicesChanged(manager : ModiBlueToothService, connectedDevices: [String])
    func recievedUniversalPeerOrderFromHost(peers: [String])
    func gotoGame()
}

protocol GameSceneDelegate {
    func heresTheNewDeck(deck: Deck)
    func dealPeersCards()
}


class ModiBlueToothService: NSObject {
    private let ModiServiceType = "modii-service"
    private var myPeerID: MCPeerID
    private let serviceAdvertiser: MCNearbyServiceAdvertiser
    private let serviceBrowser: MCNearbyServiceBrowser
    
    var connectionSceneDelegate: ConnectionSceneDelegate?
    var gameSceneDelegate: GameSceneDelegate?
    
    override init() {
        myPeerID = MCPeerID(displayName: GameStateSingleton.sharedInstance.deviceName)
        print(myPeerID)
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: ModiServiceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: ModiServiceType)
        super.init()
        
        self.serviceAdvertiser.delegate = self
        self.serviceAdvertiser.startAdvertisingPeer()
        
        self.serviceBrowser.delegate = self
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
    
    lazy var session: MCSession = {
        let session = MCSession(peer: self.myPeerID, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.Required)
        session.delegate = self
        return session
    }()
    
    func sendData(string: String) {
        if session.connectedPeers.count > 0 {
            var error : NSError?
            do {
                try self.session.sendData(string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, toPeers: session.connectedPeers, withMode: MCSessionSendDataMode.Reliable)
            } catch let error1 as NSError {
                error = error1
                print("%@", "\(error)")
            }
        }
    }
//    func sendPeerOrder(peers: [MCPeerID]) {
//        if session.connectedPeers.count > 0 {
//            let data = NSKeyedArchiver.archivedDataWithRootObject(peers)
//            var error : NSError?
//            do {
//                try self.session.sendData(data, toPeers: session.connectedPeers, withMode: MCSessionSendDataMode.Reliable)
//            } catch let error1 as NSError {
//                error = error1
//                print("%@", "\(error)")
//            }
//        }
//    }
    
//    func sendNewPeerOrderToSingleton() {
//        GameStateSingleton.sharedInstance.orderedPlayers = [Player(name: self.myPeerID.displayName, peerID: self.myPeerID)]
//        for peer in self.session.connectedPeers {
//            GameStateSingleton.sharedInstance.orderedPlayers.append(Player(name: peer.displayName, peerID: peer))
//        }
//    }
    func peerStringsArray(str: String) -> [String] {
        var peerStrings: [String] = []
        var currentPeer: String = ""
        
        for character in str.characters {
            if character != "." {
                currentPeer += String(character)
            } else {
                peerStrings.append(currentPeer)
                currentPeer = ""
            }
        }
        return peerStrings
    }
    
}

extension ModiBlueToothService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: NSError) {
        print("Did not start advertising peer: \(error)")
    }
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: NSData?, invitationHandler: (Bool, MCSession) -> Void) {
        print("Did recieve invitation from \(peerID.displayName)")
        invitationHandler(true, self.session)
    }
}

extension ModiBlueToothService: MCNearbyServiceBrowserDelegate {
    func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {
        print("Did not start browsing for peers: \(error)")
    }
    func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("Found peer: \(peerID.displayName)")
        print("Sending invite to: \(peerID.displayName)")
        browser.invitePeer(peerID, toSession: self.session, withContext: nil, timeout: 30)
    }
    func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Lost peer: \(peerID.displayName)")
    }
    
}

extension MCSessionState {
    func stringValue() -> String {
        switch(self) {
        case .NotConnected: return "Not Connected"
        case .Connecting: return "Connecting"
        case .Connected: return "Connected"
        }
    }
}

extension ModiBlueToothService: MCSessionDelegate {
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        let str = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
        
        if str == "gametime" {
            connectionSceneDelegate?.gotoGame()
        }
        if str == "dealCards" {
            gameSceneDelegate?.dealPeersCards()
        }
        
        if str.characters.count > 9 {
            if str.substringToIndex(str.startIndex.advancedBy(10)) == "deckString" {
                let deckString = str.stringByReplacingOccurrencesOfString("deckString", withString: "")
                gameSceneDelegate?.heresTheNewDeck(Deck(withString: deckString))
            }
            
            if str.substringToIndex(str.startIndex.advancedBy(9)) == "peerOrder" {
                let peerOrder = str.stringByReplacingOccurrencesOfString("peerOrder", withString: "")
                connectionSceneDelegate?.recievedUniversalPeerOrderFromHost(peerStringsArray(peerOrder))
            }
        }
        
        
    }
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        print("\(peerID.displayName) did change state: \(state.stringValue())")
        self.connectionSceneDelegate?.connectedDevicesChanged(self, connectedDevices: session.connectedPeers.map({$0.displayName}))
        if GameStateSingleton.sharedInstance.currentGameState == .WaitingForPlayers {
        }
    }
    
    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
        
    }
    
    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
        
    }
}