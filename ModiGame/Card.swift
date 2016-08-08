//
//  CardsHandler.swift
//  Modii
//
//  Created by Ikey Benzaken on 7/17/16.
//  Copyright © 2016 Ikey Benzaken. All rights reserved.
//

import Foundation
import SpriteKit

class Card: SKSpriteNode {
    
    var suit: String!
    var readableRank: String!
    var rank: Int!
    var suitIndex: Int!
    let frontTexture: SKTexture!
    let backTexture: SKTexture!
    var backShowing: Bool = true
    var ownerLabel = SKLabelNode(fontNamed: "Chalkduster")
    var owner: Player!
    
    
    init(suit: String, readableRank: String, rank: Int) {
        
        self.suit = suit
        self.readableRank = readableRank
        self.rank = rank
        
        if suit == "Spades" {suitIndex = 1}
        if suit == "Clubs" {suitIndex = 2}
        if suit == "Hearts" {suitIndex = 3}
        if suit == "Diamonds" {suitIndex = 4}
        
        var prefix: String = String(rank)
        if self.readableRank == "Ace" {prefix = "ace"}
        if self.readableRank == "Jack" {prefix = "jack"}
        if self.readableRank == "Queen" {prefix = "queen"}
        if self.readableRank == "King" {prefix = "king"}
        
        frontTexture = SKTexture(imageNamed: prefix + "_of_" + suit)
        backTexture = SKTexture(imageNamed: "cardBack")
        
        super.init(texture: backTexture, color: .clearColor(), size: frontTexture.size())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("SomeError")
    }
    
    
    func cardInfo() -> (suit: String, readableRank: String, rank: Int, suitIndex: Int) {
        return (self.suit, self.readableRank, self.rank, self.suitIndex)
    }
    
    func flip() {
        if !backShowing {
            self.texture = backTexture
            backShowing = true
        } else {
            self.texture = frontTexture
            backShowing = false
        }
    }
    
    func showPlayerName(playerName: String) {
        ownerLabel.position = CGPoint(x: self.frame.width / 2, y: -self.frame.height)
        print(self.frame)
        ownerLabel.text = playerName
        ownerLabel.fontSize = 48
        self.addChild(ownerLabel)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if owner != nil {
            if owner.peerID  == GameStateSingleton.sharedInstance.myPlayer.peerID {
                flip()
            }
        }
        
    }
    
    
}

