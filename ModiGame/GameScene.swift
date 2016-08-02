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
            dealButton.fontSize = 44
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
    
    func placeDeckOnScreen() {
        var x: CGFloat = 1
        for card in deck.cards {
            addCard(card, zPos: x)
            x = x + 1
        }
        
        let players = SKLabelNode(fontNamed: "Chalkduster")
        players.text = ""
        players.fontSize = 12
        for player in GameStateSingleton.sharedInstance.orderedPlayers {
            players.text? += player.name + ", "
        }
        players.position = CGPoint(x: frame.maxX / 2, y: frame.maxY / 2)
        players.zPosition = 100
        self.addChild(players)
    }
    
    func addCard(card: Card, zPos: CGFloat) {
        let randomRotation = arc4random_uniform(10)
        card.xScale = 0.19; card.yScale = 0.19
        card.position = CGPoint(x: frame.maxX * 0.75, y: frame.maxY * 0.4)
        card.zRotation = (CGFloat(randomRotation) - 5) * CGFloat(M_PI) / 180
        card.zPosition = zPos
        card.userInteractionEnabled = true
        addChild(card)
        deckOfCards.append(card)
        deck.cards.removeAtIndex(0)
    }
    
    func dealCards() {
        //FIGURE OUT A UNIVERSAL DEALCARDS METHOD THAT DEALS EVERY PLAYERS RESPECTIVE CARD TO THE BOTTOM OF THEIR SCREENS - DONE
        //WHILE ALSO MAINTAINING A SET ORDER OF PLAYERS - DONE
        
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
        
        referenceCard.zRotation = 90 * CGFloat(M_PI) / 180
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
        
        deckOfCards.last?.showPlayerName("PlayerName")
        cardsInPlay.append(deckOfCards.last!)
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




