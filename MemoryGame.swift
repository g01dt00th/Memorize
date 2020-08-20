//
//  MemoryGame.swift
//  Memorize
//
//  Created by Daniel Savchak on 25.07.2020.
//  Copyright © 2020 Danylo Savchak. All rights reserved.
//

import Foundation

struct MemoryGame<CardContent, Color> where CardContent: Equatable {
    private(set) var cards: Array<Card>
    private(set) var nameOfGame: String
    private(set) var foregroundColor: Color
    private(set) var score: Int = 0
    
    
    private var indexOfOneAndOnlyFaceUpCard: Int? {
        get { cards.indices.filter { cards[$0].isFaceUp }.only }
        set {
            for index in cards.indices {
                cards[index].isFaceUp = index == newValue
            }
        }
    }
    
    mutating func choose(card: Card) {
        print("card chosen: \(card)")
        if let chosenIndex = cards.firstIndex(mathing: card), !cards[chosenIndex].isFaceUp, !cards[chosenIndex].isMatched {
            if let potentialMatchIndex = indexOfOneAndOnlyFaceUpCard {
                if cards[chosenIndex].content == cards[potentialMatchIndex].content {
                    cards[chosenIndex].isMatched = true
                    cards[potentialMatchIndex].isMatched = true
                    score = score + 2
                }
                else {
                    score = score - 1
                }
                self.cards[chosenIndex].isFaceUp = true
            } else {
                indexOfOneAndOnlyFaceUpCard = chosenIndex
            }
        }
    }
    
    private func shuffle(cards: Array<MemoryGame<CardContent, Color>.Card>) -> Array<MemoryGame<CardContent, Color>.Card>{
        var result = Array<MemoryGame<CardContent, Color>.Card>()
        var i = cards.count
        while i != 0 {
            let randomIndex = Int.random(in: 0..<cards.count)
            var o = 0
            for (_,card) in result.enumerated() {
                if card.id == cards[randomIndex].id {
                    o = 1
                }
            }
            if o == 0 {
                result.append(cards[randomIndex])
                i = i-1
            }
        }
        return result
    }
    
    init(numberOfPairsOfCards: Int,name: String,color: Color, cardContentFactory: (Int) -> CardContent) {
        cards = Array<Card>()
        nameOfGame = name
        foregroundColor = color
        for pairIndex in 0..<numberOfPairsOfCards {
            let content = cardContentFactory(pairIndex)
            cards.append(Card(content: content, id: pairIndex*2))
            cards.append(Card(content: content, id: pairIndex*2+1))
        }
        cards = shuffle(cards: cards)
        // Also it is possible to do cards.shuffle() - array func 
    }
    
    struct Card: Identifiable {
        var isFaceUp: Bool = false {
            didSet {
                if isFaceUp {
                    startUsingBonusTime()
                } else {
                    stopUsingBonusTime()
                }
            }
        }
        var isMatched: Bool = false {
            didSet {
                stopUsingBonusTime()
            }
        }
        var content: CardContent
        var id: Int
        
        var startPositionX: Double = Double.random(in: ClosedRange<Double>(uncheckedBounds: (-100.0,1000.0)))
        var startPositionY: Double = Double.random(in: ClosedRange<Double>(uncheckedBounds: (-100.0,1000.0)))
    
        //MARK: - bonus time
        
        // this could give matching bonus points
        // if the user matches the card
        // before a certain amount of time passes during which the card is face up
        
        // can be zero which means "no bonus available" for this card
        var bonusTimeLimit: TimeInterval = 6
        
        // how long this card has ever been face up
        private var faceUpTime: TimeInterval {
            if let lastFaceUpdate = self.lastFaceUpDate {
                return pastFaceUpTime + Date().timeIntervalSince(lastFaceUpdate)
            } else {
                return pastFaceUpTime
            }
        }
        
        // the last time this card was turned face up ( and is still face up)
        var lastFaceUpDate : Date?
        // the accumulated this card has been face up in the past
        // (i.e. not including the current time it's been face up if it is currently so)
        var pastFaceUpTime: TimeInterval = 0
        
        // how much time left before the bonus opportunity runs out
        var bonusTimeRemaining: TimeInterval {
            max(0,bonusTimeLimit - faceUpTime)
        }
        
        // percentage of the bonus time remaining
        var bonusRemaining: Double {
            (bonusTimeLimit > 0 && bonusTimeLimit > 0) ? bonusTimeRemaining / bonusTimeLimit : 0
        }
        
        // whether the card was matched during the bonus time period
        var hasEarnedBonus: Bool {
            isMatched && bonusTimeRemaining > 0
        }
        
        // whether we are currently face up, unmatched and have not yet use the bonus window
        var isConsumingBonusTime: Bool {
            isFaceUp && !isMatched && bonusTimeRemaining > 0
        }
        
        // called when the card transition to face up state
        private mutating func startUsingBonusTime() {
            if isConsumingBonusTime, lastFaceUpDate == nil {
                lastFaceUpDate = Date()
            }
        }
        
        // called when the card transition goes back face down (or gets matched)
        private mutating func stopUsingBonusTime() {
            pastFaceUpTime = faceUpTime
            self.lastFaceUpDate = nil
        }
    }
}
