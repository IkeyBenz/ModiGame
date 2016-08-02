import Foundation
import SpriteKit

class ConnectionScene: SKScene {
    
    
    var connectionsLabel = SKLabelNode(fontNamed: "Chalkduster")
    let startGamebutton = SKLabelNode(fontNamed: "Chalkduster")
    var textField: UITextField!
    
    override func didMoveToView(view: SKView) {
        
        print("In the connections scene")
        
        let background = SKSpriteNode(imageNamed: "Felt")
        background.size = self.frame.size
        background.position = CGPoint(x: CGRectGetMidX(frame), y: CGRectGetMidY(frame))
        background.zPosition = 0
        
        textField = UITextField(frame: CGRect(x: view.frame.origin.x, y: view.frame.origin.y, width: 400, height: 40))
        textField.placeholder = "Type your name here"
        textField.font = UIFont(name: "Chalkduster", size: 24)
        textField.delegate = self
        
        connectionsLabel.fontSize = 36
        connectionsLabel.position = CGPoint(x: CGRectGetMidX(frame), y: CGRectGetMidY(frame))
        connectionsLabel.zPosition = 1
        connectionsLabel.text = "Connected Players:"
        
        startGamebutton.position = CGPoint(x: connectionsLabel.position.x, y: CGRectGetMaxY(frame) / 4)
        startGamebutton.text = "Start Game"
        startGamebutton.fontSize = 36
        
        self.addChild(connectionsLabel)
        self.addChild(startGamebutton)
        self.addChild(background)
        view.addSubview(textField)
        
        
    }
    
    func goToGameScene() {
        let skView = self.view! as SKView
        let scene = GameScene(fileNamed: "GameScene")
        skView.showsFPS = true
        skView.showsNodeCount = true
        scene?.scaleMode = .ResizeFill
        skView.presentScene(scene)
    }
    
    //SIMULATANEOUSLY SETS AND SENDS THE PEER ORDER FOR HOST AND CLIENTS
    func orderedPlayersString() -> String {
        GameStateSingleton.sharedInstance.orderedPlayers = []
        let me = GameStateSingleton.sharedInstance.bluetoothService.session.myPeerID
        var orderedPlayers: String = "peerOrder" + me.displayName + "."
        GameStateSingleton.sharedInstance.orderedPlayers.append(Player(name: me.displayName, peerID: me))
        for player in GameStateSingleton.sharedInstance.bluetoothService.session.connectedPeers {
            orderedPlayers += player.displayName + "."
            GameStateSingleton.sharedInstance.orderedPlayers.append(Player(name: player.displayName, peerID: player))
        }
        return orderedPlayers
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            if CGRectContainsPoint(startGamebutton.frame, touch.locationInNode(self)) {
                GameStateSingleton.sharedInstance.bluetoothService.sendData(orderedPlayersString())
                GameStateSingleton.sharedInstance.bluetoothService.sendData("gametime")
                GameStateSingleton.sharedInstance.myTurnToDeal = true
                self.goToGameScene()
            }
        }
    }
    func initializeBluetooth(textField: UITextField) {
        print("yes")
        GameStateSingleton.sharedInstance.deviceName = textField.text!
        textField.resignFirstResponder()
        let modiService = ModiBlueToothService()
        GameStateSingleton.sharedInstance.bluetoothService = modiService
        GameStateSingleton.sharedInstance.bluetoothService.connectionSceneDelegate = self
    }
}

extension ConnectionScene: ConnectionSceneDelegate {
    func connectedDevicesChanged(manager: ModiBlueToothService, connectedDevices: [String]) {
        self.connectionsLabel.text = String(connectedDevices)
        
        //UPDATE PLAYER DICTIONARY
        GameStateSingleton.sharedInstance.playersDictionary = [:]
        
        let me = GameStateSingleton.sharedInstance.bluetoothService.session.myPeerID
        GameStateSingleton.sharedInstance.playersDictionary[me.displayName] = me
        
        for peer in GameStateSingleton.sharedInstance.bluetoothService.session.connectedPeers {
            GameStateSingleton.sharedInstance.playersDictionary[peer.displayName] = peer
        }
        
        

    }
    func gotoGame() {
        self.goToGameScene()
    }
    func recievedUniversalPeerOrderFromHost(peers: [String]) {
        for peer in peers {
            let peerID = GameStateSingleton.sharedInstance.playersDictionary[peer]
            GameStateSingleton.sharedInstance.orderedPlayers.append(Player(name: peer, peerID: peerID!))
        }
    }
}

extension ConnectionScene: UITextFieldDelegate {
//    func textFieldDidEndEditing(textField: UITextField) {
//        initializeBluetooth(textField)
//    }
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        initializeBluetooth(textField)
        return true
    }
}