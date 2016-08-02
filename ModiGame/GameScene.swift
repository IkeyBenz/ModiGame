//
//  GameScene.swift
//  Modii
//
//  Created by Ikey Benzaken on 7/17/16.
//  Copyright (c) 2016 Ikey Benzaken. All rights reserved.
//

import SpriteKit


class GameScene: SKScene {
    
    var deck = Deck()
    var players: Int = GameStateSingleton.sharedInstance.orderedPlayers.count
    var cardsInPlay: [SKSpriteNode] = []
    let dealButton = SKLabelNode(fontNamed: "Chalkduster")
    var deckOfCards: [Card] = []
    var myCard: Card!
    
    
    override func didMoveToView(view: SKView) {
        
        GameStateSingleton.sharedInstance.bluetoothService.gameSceneDelegate = self
        GameStateSingleton.sharedInstance.currentGameState = .InSession
        
        let background = SKSpriteNode(imageNamed: "Felt")
        background.size = self.frame.size
        background.position = CGPoint(x: CGRectGetMidX(frame), y: CGRectGetMidY(frame))
        
        if GameStateSingleton.sharedInstance.myTurnToDeal {
            dealButton.fontSize = 24
            dealButton.text = "Deal Cards"
            dealButton.position = CGPoint(x: CGRectGetMaxX(self.frame) * 0.75, y: CGRectGetMaxY(self.frame) / 5)
            dealButton.zPosition = 1
            
            deck.shuffle()
            placeDeckOnScreen()
            GameStateSingleton.sharedInstance.bluetoothService.sendData("deckString" + deck.cardsString)
        }
        
        self.addChild(background)
        self.addChild(dealButton)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            if nodeAtPoint(touch.locationInNode(self)) == dealButton {
                if cardsInPlay.count < players {
                    dealCards()
                    GameStateSingleton.sharedInstance.bluetoothService.sendData("dealCards")
                } else {
                    self.dealButton.removeFromParent()
                    GameStateSingleton.sharedInstance.myTurnToDeal = false
                }
            }
        }
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
    
    func loopableIndex(index: Int, range: Int) -> Int {
        var x = index
        if range == 0 {
            x = 0
        } else {
            while x > range {
                x = x - range - 1
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
        let referenceCard = SKSpriteNode(imageNamed: "ace_of_spades")
        var radius = (frame.size.height / 2) - (deckOfCards[0].frame.height)
        let centerPoint = CGPoint(x: frame.maxX / 4, y: frame.maxY / 2)
        let playerIndexOrder: Int = {
            let index: Int = 0
            for x in 0 ..< GameStateSingleton.sharedInstance.orderedPlayers.count {
                if GameStateSingleton.sharedInstance.orderedPlayers[x].peerID == GameStateSingleton.sharedInstance.bluetoothService.session.myPeerID {
                    return x + 1
                }
            }
            return index
        }()
        
        let angle: CGFloat = (((360 / CGFloat(GameStateSingleton.sharedInstance.orderedPlayers.count)) * CGFloat(cardsInPlay.count + (2 - playerIndexOrder))).toRadians()) - 90.toRadians()
        
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
        print(loopableIndex(cardsInPlay.count + 1, range: GameStateSingleton.sharedInstance.orderedPlayers.count))
        playerLabel.text = GameStateSingleton.sharedInstance.orderedPlayers[loopableIndex(cardsInPlay.count + 1, range: GameStateSingleton.sharedInstance.orderedPlayers.count - 1)].name
        playerLabel.fontSize = 12
        playerLabel.position = CGPointMake(centerPoint.x + (cos(angle) * (radius + (referenceCard.frame.height / 1.8))), centerPoint.y + (sin(angle) * (radius + (referenceCard.frame.height / 1.8))))
        playerLabel.zRotation = angle + 90.toRadians()
        playerLabel.zPosition = 1.0
        self.addChild(playerLabel)
        print(playerLabel.position)
        print(frame)
        print(view?.frame)
        
        
        cardsInPlay.append(deckOfCards.last!)
        GameStateSingleton.sharedInstance.orderedPlayers[cardsInPlay.count - 1].card = deckOfCards.last!
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
}




