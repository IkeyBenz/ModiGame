//
//  GameScene.swift
//  Modii
//
//  Created by Ikey Benzaken on 7/17/16.
//  Copyright (c) 2016 Ikey Benzaken. All rights reserved.
//

import SpriteKit


class GameScene: SKScene {
    
    let GS = GameStateSingleton.sharedInstance
    var deck = Deck()
    var players: Int = GameStateSingleton.sharedInstance.orderedPlayers.count
    var cardsInPlay: [SKSpriteNode] = []
    let dealButton = SKLabelNode(fontNamed: "Chalkduster")
    var deckOfCards: [Card] = []
    var tradeButton = SKLabelNode(fontNamed: "Chalkduster")
    var stickButton = SKLabelNode(fontNamed: "Chalkduster")
    var updateLabel = SKLabelNode(fontNamed: "Chalkduster")
    
    let playerIndexOrder: Int = {
        let index: Int = 0
        for x in 0 ..< GameStateSingleton.sharedInstance.orderedPlayers.count {
            if GameStateSingleton.sharedInstance.orderedPlayers[x].peerID == GameStateSingleton.sharedInstance.bluetoothService.session.myPeerID {
                return x + 1
            }
        }
        return index
    }()
    
    let myPlayer: Player = {
        for player in GameStateSingleton.sharedInstance.orderedPlayers {
            if player.peerID == GameStateSingleton.sharedInstance.bluetoothService.session.myPeerID {
                return player
            }
        }
        return Player(name: GameStateSingleton.sharedInstance.bluetoothService.session.myPeerID.displayName, peerID: GameStateSingleton.sharedInstance.bluetoothService.session.myPeerID)
    }()
    
    
    
    override func didMoveToView(view: SKView) {
        
        GS.bluetoothService.gameSceneDelegate = self
        GS.currentGameState = .InSession
        
        let background = SKSpriteNode(imageNamed: "Felt")
        background.size = self.frame.size
        background.position = CGPoint(x: CGRectGetMidX(frame), y: CGRectGetMidY(frame))
        
        if GS.myTurnToDeal {
            dealButton.fontSize = 24
            dealButton.text = "Deal Cards"
            dealButton.position = CGPoint(x: CGRectGetMaxX(self.frame) * 0.75, y: CGRectGetMaxY(self.frame) / 5)
            dealButton.zPosition = 1
            
            deck.shuffle()
            placeDeckOnScreen()
            GS.bluetoothService.sendData("deckString" + deck.cardsString)
        }
        
        tradeButton.text = "Swap"
        stickButton.text = "Stick"
        tradeButton.fontSize = 24
        stickButton.fontSize = 24
        tradeButton.position = CGPointMake(frame.maxX * 0.68, frame.maxY * 0.7)
        stickButton.position = CGPointMake(CGRectGetMaxX(tradeButton.frame) + (stickButton.frame.width / 1.25), tradeButton.position.y)
        tradeButton.zPosition = 1.0
        stickButton.zPosition = 1.0
        
        updateLabel.text = "\(GS.orderedPlayers[0].name) is dealing the cards"
        updateLabel.position = CGPointMake(frame.maxX * 0.75, frame.maxY - 25)
        updateLabel.zPosition = 1
        updateLabel.fontSize = 14
        
        
        self.addChild(background)
        self.addChild(dealButton)
        self.addChild(updateLabel)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            if nodeAtPoint(touch.locationInNode(self)) == dealButton {
                if cardsInPlay.count < players {
                    dealCards()
                    GS.bluetoothService.sendData("dealCards")
                    if cardsInPlay.count == players {
                        self.dealButton.removeFromParent()
                        GS.myTurnToDeal = false
                        self.nextPlayerGoes()
                    }
                }
            }
            if nodeAtPoint(touch.locationInNode(self)) == stickButton {
                self.removePlayerOptions()
                self.nextPlayerGoes()
            }
            if nodeAtPoint(touch.locationInNode(self)) == tradeButton {
                self.tradeCardWithPlayer(myPlayer, playerTwo: GS.orderedPlayers[loopableIndex(playerIndexOrder, range: GS.orderedPlayers.count)])
                GS.bluetoothService.sendData("playerTraded\(myPlayer.name).\(GS.orderedPlayers[loopableIndex(playerIndexOrder, range: GS.orderedPlayers.count)].name)")
                self.removePlayerOptions()
                self.nextPlayerGoes()
            }
        }
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
    
    func showPlayerOptions() {
        self.addChild(stickButton)
        self.addChild(tradeButton)
    }
    
    func removePlayerOptions() {
        stickButton.removeFromParent()
        tradeButton.removeFromParent()
    }
    
    func nextPlayerGoes() {
        GS.bluetoothService.sendData("updateLabelIt's \(GS.orderedPlayers[loopableIndex(playerIndexOrder, range: GS.orderedPlayers.count)].name)'s turn to go.")
        GS.bluetoothService.sendData("playersTurn\(GS.orderedPlayers[loopableIndex(playerIndexOrder, range: GS.orderedPlayers.count)].name)")
        self.updateLabel.text = "It's \(GS.orderedPlayers[loopableIndex(playerIndexOrder, range: GS.orderedPlayers.count)].name)'s turn to go."
    }
    
    func tradeCardWithPlayer(playerOne: Player, playerTwo: Player) {
        moveCards(playerOne.card, card2: playerTwo.card)
        playerOne.card = playerTwo.card
    }
    
    func moveCards(card1: Card, card2: Card) {
        let moveToCard1 = SKAction.moveTo(card1.position, duration: 0.5)
        let moveToCard2 = SKAction.moveTo(card2.position, duration: 0.5)
        
        card1.runAction(moveToCard2)
        card2.runAction(moveToCard1)
    }
    
    func loopableIndex(index: Int, range: Int) -> Int {
        var x = index
        if range == 1 {
            x = 0
        } else {
            while x > (range - 1) {
                x = x - range
            }
        }
        return x
    }
    
    func placeDeckOnScreen() {
        var x: CGFloat = 1
        for card in deck.cards {
            addCard(card, zPos: x)
            x = x + 1
        }
    }
    func resizeCard(card: Card) -> CGSize {
        let aspectRatio = card.size.width / card.size.height
        let setHeight = self.frame.size.height / 4.5
        return CGSize(width: setHeight * aspectRatio, height: setHeight)
    }
    
    func addCard(card: Card, zPos: CGFloat) {
        let randomRotation = arc4random_uniform(10)
        card.size = resizeCard(card)
        card.position = CGPoint(x: frame.maxX * 0.75, y: frame.maxY * 0.4)
        card.zRotation = (CGFloat(randomRotation) - 5) * CGFloat(M_PI) / 180
        card.zPosition = zPos
        card.userInteractionEnabled = true
        addChild(card)
        deckOfCards.append(card)
        deck.cards.removeAtIndex(0)
    }
    
    func dealCards() {
        let referenceCard = Card(suit: "spades", readableRank: "Ace", rank: 1)
        referenceCard.size = resizeCard(referenceCard)
        var radius = (frame.size.height / 2) - (referenceCard.frame.height)
        let centerPoint = CGPoint(x: frame.maxX / 4, y: frame.maxY / 2)
        
        let angle: CGFloat = (((360 / CGFloat(GS.orderedPlayers.count)) * CGFloat(cardsInPlay.count + (2 - playerIndexOrder))).toRadians()) - 90.toRadians()
        
        referenceCard.zRotation = 90.toRadians()
        referenceCard.position.x = centerPoint.x - radius
        referenceCard.xScale = 0.2; referenceCard.yScale = 0.2
        
        while CGRectGetMinX(referenceCard.frame) < 0 {
            radius = radius - 8
            referenceCard.position.x = centerPoint.x - radius
        }
        
        
        let actionMove = SKAction.moveTo(CGPoint(x: centerPoint.x + (cos(angle) * radius),y: centerPoint.y + (sin(angle) * radius)), duration: 0.5)
        let actionRotate = SKAction.rotateToAngle((angle + 90.toRadians()), duration: 0.5)
        deckOfCards.last?.runAction(actionMove)
        deckOfCards.last?.runAction(actionRotate)
        
        let playerLabel = SKLabelNode(fontNamed: "Chalkduster")
        playerLabel.text = GS.orderedPlayers[loopableIndex(cardsInPlay.count + 1, range: GS.orderedPlayers.count - 1)].name
        playerLabel.fontSize = 12
        playerLabel.position = CGPointMake(centerPoint.x + (cos(angle) * (radius + (referenceCard.frame.height))), centerPoint.y + (sin(angle) * (radius + (referenceCard.frame.height))))
        playerLabel.zRotation = angle + 90.toRadians()
        playerLabel.zPosition = 1.0
        self.addChild(playerLabel)
        
        
        cardsInPlay.append(deckOfCards.last!)
        GS.orderedPlayers[cardsInPlay.count - 1].card = deckOfCards.last!
        deckOfCards.last!.owner = GS.orderedPlayers[cardsInPlay.count - 1]
        deckOfCards.removeLast()
    }
    
    
}

extension GameScene: GameSceneDelegate {
    func heresTheNewDeck(deck: Deck) {
        self.deck = deck
        placeDeckOnScreen()
    }
    func dealPeersCards() {
        self.dealCards()
    }
    func updateLabel(str: String) {
        self.updateLabel.text = str
    }
    func yourTurn() {
        self.showPlayerOptions()
    }
    func playersTradedCards(playerOne: Player, playerTwo: Player) {
        self.tradeCardWithPlayer(playerOne, playerTwo: playerTwo)
    }
}




