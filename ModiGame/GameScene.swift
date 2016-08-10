//
//  GameScene.swift
//  Modii
//
//  Created by Ikey Benzaken on 7/17/16.
//  Copyright (c) 2016 Ikey Benzaken. All rights reserved.
//

import SpriteKit

//  NEXT MOVE:
//  - DISABLE TRADING WITH KINGS
//  - IF PLAYER IS FIRST IN ORDER (IF PLAYER IS THE DEALER) HE SWITCHES WITH THE DECK AND THE ROUND ENDS
//  - LET THAT RUN IN AN ENDLESS LOOP UNTIL ONLY ONE LIFE REMAINS


// FIX THE ENDOFROUND FUNCTION
// YOU CALLED IT NINE DIFFERENT TIMES, FUCKHEAD.

class GameScene: SKScene {
    
    let GS = GameStateSingleton.sharedInstance
    var deck = Deck()
    var players: Int = GameStateSingleton.sharedInstance.orderedPlayers.count
    var cardsInPlay: [Card] = []
    var cardsInTrash: [Card] = []
    let dealButton = SKLabelNode(fontNamed: "Chalkduster")
    var deckOfCards: [Card] = []
    var tradeButton = SKLabelNode(fontNamed: "Chalkduster")
    var stickButton = SKLabelNode(fontNamed: "Chalkduster")
    var updateLabel = SKLabelNode(fontNamed: "Chalkduster")
    var roundLabel = SKLabelNode(fontNamed: "Chalkduster")
    var roundNubmer: Int = 0
    var myTurnToDeal: Bool = false
    
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
                GameStateSingleton.sharedInstance.myPlayer = player
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
        
        dealButton.fontSize = 24
        dealButton.text = "Deal Cards"
        dealButton.position = CGPoint(x: CGRectGetMaxX(self.frame) * 0.75, y: CGRectGetMaxY(self.frame) / 14)
        dealButton.zPosition = 1
        
        if GS.currentDealer.peerID == myPlayer.peerID {
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
        
        roundLabel.text = "Round 1"
        roundLabel.position = CGPoint(x: frame.maxX / 2, y: frame.maxY / 2)
        roundLabel.fontSize = 24
        roundLabel.zPosition = 1
        
        updateLabel.text = "Loading Game..."
        updateLabel.position = CGPointMake(frame.maxX * 0.75, frame.maxY - 25)
        updateLabel.zPosition = 1
        updateLabel.fontSize = 14
        
        
        self.addChild(background)
        self.addChild(updateLabel)
        runBeginingOfRoundFunctions()
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let wait = SKAction.waitForDuration(2)
        let block = SKAction.runBlock({self.nextPlayerGoes()})
        let endMyTurn = SKAction.sequence([wait, block])
        for touch in touches {
            if nodeAtPoint(touch.locationInNode(self)) == dealButton {
                dealCards()
                GS.bluetoothService.sendData("dealCards")
                dealButton.removeFromParent()
                self.runAction(endMyTurn)
            }
            if nodeAtPoint(touch.locationInNode(self)) == stickButton {
                if myPlayer.peerID == GS.currentDealer.peerID {
                    self.runEndOfRoundFunctions()
                    GS.bluetoothService.sendData("endRound")
                } else {
                    self.runAction(endMyTurn)
                }
                GS.bluetoothService.sendData("updateLabel\(myPlayer.name) stuck")
                self.updateLabel.text = "\(myPlayer.name) stuck"
                self.removePlayerOptions()
            }
            if nodeAtPoint(touch.locationInNode(self)) == tradeButton {
                if myPlayer.peerID != GS.currentDealer.peerID {
                    self.tradeCardWithPlayer(myPlayer, playerTwo: GS.orderedPlayers[loopableIndex(playerIndexOrder, range: GS.orderedPlayers.count)])
                    GS.bluetoothService.sendData("playerTraded\(myPlayer.name).\(GS.orderedPlayers[loopableIndex(playerIndexOrder, range: GS.orderedPlayers.count)].name)")
                    self.updateLabel.text = "\(myPlayer.name) traded cards with \(GS.orderedPlayers[loopableIndex(playerIndexOrder, range: GS.orderedPlayers.count)].name)"
                    self.runAction(endMyTurn)
                } else {
                    self.tradeCardWithDeck(myPlayer)
                    GS.bluetoothService.sendData("hittingDeck\(myPlayer.name)")
                    let wait  = SKAction.waitForDuration(3)
                    let block = SKAction.runBlock({self.runEndOfRoundFunctions(); self.GS.bluetoothService.sendData("endRound")})
                    self.runAction(SKAction.sequence([wait, block]))
                }
                self.removePlayerOptions()
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
        let temp = playerOne.card
        moveCards(playerOne.card, card2: playerTwo.card)
        playerOne.card = playerTwo.card
        playerTwo.card = temp
        playerOne.card.owner = playerOne
        playerTwo.card.owner = playerTwo
    }
    
    func tradeCardWithDeck(player: Player) {
        if deckOfCards.count > 0 {
            let card = deckOfCards.last!
            let xPos = player.card.position.x + (cos(player.card.zRotation) * 10)
            let yPos = player.card.position.y + (sin(player.card.zRotation) * 10)
            let moveCard = SKAction.moveTo(CGPoint(x: xPos, y: yPos), duration: 0.5)
            let rotateCard = SKAction.rotateToAngle(player.card.zRotation, duration: 0.5)
            let flipCard = SKAction.runBlock({card.texture = card.frontTexture})
            card.runAction(rotateCard)
            card.runAction(SKAction.sequence([moveCard, flipCard]))
            card.zPosition = player.card.zPosition + 1
            player.card = card
            player.card.owner = player
            cardsInPlay.append(card)
            deckOfCards.removeLast()
        }
    }
    
    func moveCards(card1: Card, card2: Card) {
        let moveToCard1 = SKAction.moveTo(card1.position, duration: 0.5)
        let moveToCard2 = SKAction.moveTo(card2.position, duration: 0.5)
        let rotateCard1 = SKAction.rotateToAngle(card2.zRotation, duration: 0.5)
        let rotateCard2 = SKAction.rotateToAngle(card1.zRotation, duration: 0.5)
        
        if card1.texture == card1.frontTexture {
            card1.flip()
        }
        if card2.texture == card2.frontTexture {
            card2.flip()
        }
        
        card1.runAction(moveToCard2)
        card1.runAction(rotateCard1)
        card2.runAction(moveToCard1)
        card2.runAction(rotateCard2)
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
        card.position = CGPoint(x: frame.maxX * 0.75, y: frame.maxY / 4)
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
        
        referenceCard.zRotation = 90.toRadians()
        referenceCard.position.x = centerPoint.x - radius
        referenceCard.xScale = 0.2; referenceCard.yScale = 0.2
        
        while CGRectGetMinX(referenceCard.frame) < 0 {
            radius = radius - 8
            referenceCard.position.x = centerPoint.x - radius
        }
        
        let block = {
            let angle: CGFloat = (((360 / CGFloat(self.GS.orderedPlayers.count)) * CGFloat(self.cardsInPlay.count + (2 - self.playerIndexOrder))).toRadians()) - 90.toRadians()
            let position = CGPointMake(centerPoint.x + (cos(angle) * radius), centerPoint.y + (sin(angle) * radius))
            let actionMove = SKAction.moveTo(position, duration: 0.5)
            let actionRotate = SKAction.rotateToAngle((angle + 90.toRadians()), duration: 0.5)
            self.deckOfCards.last?.runAction(actionMove)
            self.deckOfCards.last?.runAction(actionRotate)
            
            if self.roundNubmer == 1 {
                let playerLabel = SKLabelNode(fontNamed: "Chalkduster")
                let fivePercentWidth = self.frame.size.width * 0.05
                let fivePercentHeight = self.frame.size.height * 0.05
                playerLabel.text = self.GS.orderedPlayers[self.loopableIndex(self.cardsInPlay.count + 1, range: self.GS.orderedPlayers.count)].name
                playerLabel.fontSize = 12
                playerLabel.position = CGPointMake(position.x + (cos(angle) * ((self.deckOfCards.last!.size.width / 2) + fivePercentWidth)), position.y + (sin(angle) * ((self.deckOfCards.last!.size.height / 2) + fivePercentHeight)))
                playerLabel.zRotation = angle + 90.toRadians()
                playerLabel.zPosition = 1.0
                self.addChild(playerLabel)
            }
            
            
            self.cardsInPlay.append(self.deckOfCards.last!)
            self.GS.orderedPlayers[self.loopableIndex(self.cardsInPlay.count, range: self.GS.orderedPlayers.count)].card = self.deckOfCards.last!
            self.deckOfCards.last!.owner = self.GS.orderedPlayers[self.loopableIndex(self.cardsInPlay.count, range: self.GS.orderedPlayers.count)]
            self.deckOfCards.removeLast()
        }
        let wait = SKAction.waitForDuration(0.5)
        let runBlock = SKAction.runBlock(block)
        let sequence = SKAction.sequence([runBlock, wait])
        let actionRepeat = SKAction.repeatAction(sequence, count: players)
        self.runAction(actionRepeat)
    }
    
    func runEndOfRoundFunctions() {
        let lowestCardRank: Int = {
            var rank = 13
            for player in GS.orderedPlayers {
                if player.card.rank < rank {
                    rank = player.card.rank
                }
            }
            return rank
        }()
        var playersLost: [String] = []
        for player in GS.orderedPlayers {
            player.card.texture = player.card.frontTexture
            if player.card.rank == lowestCardRank {
                player.lives = player.lives - 1
                playersLost.append(player.name)
            }
        }
        var lostPlayersString = ""
        for player in playersLost {
            lostPlayersString += player + ", "
        }
        self.updateLabel.text = "\(lostPlayersString)lost this round."
        
        let waitFive = SKAction.waitForDuration(5)
        let trashCards = SKAction.runBlock({self.sendCardsToTrash()})
        self.runAction(SKAction.sequence([waitFive, trashCards]))
        
        // IF EVERY PLAYER ONLY HAS 1 LIFE LEFT -> GO INTO DOUBLE GAME
        // UPDATE LEADERBOARD
        
        let currentDealerIndex: Int = {
            var index: Int = 0
            for player in 0 ..< self.GS.orderedPlayers.count {
                if GS.orderedPlayers[player].peerID == GS.currentDealer.peerID {
                    index = player
                }
            }
            return index
        }()
        let nextPlayer = GS.orderedPlayers[loopableIndex(currentDealerIndex + 1, range: GS.orderedPlayers.count)]
        
        self.GS.currentDealer = nextPlayer
        let waitSix = SKAction.waitForDuration(6)
        let goIntoNextRound = SKAction.runBlock({self.runBeginingOfRoundFunctions()})
        self.runAction(SKAction.sequence([waitSix, goIntoNextRound]))
    }
    
    func sendCardsToTrash() {
        for card in cardsInPlay {
            let trashPosition = CGPoint(x: frame.maxX * 0.9, y: frame.maxY / 4)
            let randomRotation = (CGFloat(arc4random_uniform(12)) - 6) * CGFloat(M_PI) / 180
            let moveToTrash = SKAction.moveTo(trashPosition, duration: 1)
            let rotateToStraight = SKAction.rotateToAngle(randomRotation, duration: 1)
            card.runAction(moveToTrash)
            card.runAction(rotateToStraight)
            cardsInPlay.removeAtIndex(cardsInPlay.indexOf(card)!)
            cardsInTrash.append(card)
        }
    }
    
    
    
    func runBeginingOfRoundFunctions() {
        roundNubmer  = roundNubmer + 1
        roundLabel.text = "Round \(roundNubmer)"
        let wait = SKAction.waitForDuration(1.5)
        let addRoundLabel = SKAction.runBlock({self.addChild(self.roundLabel)})
        let removeLabel = SKAction.runBlock({self.roundLabel.removeFromParent()})
        self.runAction(SKAction.sequence([wait, addRoundLabel, wait, removeLabel]))
        
        if myPlayer.peerID == GS.currentDealer.peerID {
            updateLabel.text = "\(myPlayer.name) is dealing the cards"
            GS.bluetoothService.sendData("updateLabel\(myPlayer.name) is dealing the cards")
            let waitForthree = SKAction.waitForDuration(3)
            let addDealButton = SKAction.runBlock({self.addChild(self.dealButton)})
            self.runAction(SKAction.sequence([waitForthree, addDealButton]))
        }
        
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
    func playerTradedWithDeck(player: Player) {
        self.tradeCardWithDeck(player)
    }
    func endRound() {
        let wait = SKAction.waitForDuration(2.9)
        let block = SKAction.runBlock({self.runEndOfRoundFunctions()})
        self.runAction(SKAction.sequence([wait, block]))
    }
    func trashCards() {
        self.sendCardsToTrash()
    }
}




