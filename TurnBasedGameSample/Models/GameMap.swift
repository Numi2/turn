//
//  GameMap.swift
//  TurnBasedGameSample
//
//  Created for Hexagon Strategy Game
//

import Foundation
import SwiftUI

/// Represents the current phase of a player's turn
enum TurnPhase: String, Codable {
    case income = "income"
    case build = "build"
    case move = "move"
    case combat = "combat"
    case endTurn = "endTurn"
    
    var description: String {
        switch self {
        case .income: return "Income Phase"
        case .build: return "Build Phase"
        case .move: return "Move Phase"
        case .combat: return "Combat Phase"
        case .endTurn: return "End Turn"
        }
    }
    
    var next: TurnPhase {
        switch self {
        case .income: return .build
        case .build: return .move
        case .move: return .combat
        case .combat: return .endTurn
        case .endTurn: return .income
        }
    }
}

/// Manages the hexagonal game map and all game state
class GameMap: ObservableObject, Codable {
    
    // Map configuration
    let mapRadius: Int
    let validPositions: Set<HexCoordinate>
    
    // Game state
    @Published var units: [HexCoordinate: GameUnit] = [:]
    @Published var currentPlayer: PlayerSide = .player1
    @Published var turnPhase: TurnPhase = .build
    @Published var turnNumber: Int = 1
    
    // Player resources
    @Published var player1Gold: Int = 100
    @Published var player2Gold: Int = 100
    
    // UI state
    @Published var selectedUnit: GameUnit? = nil
    @Published var highlightedPositions: Set<HexCoordinate> = []
    @Published var gameMode: GameMode = .selectUnit
    
    enum GameMode {
        case selectUnit
        case moveUnit
        case attackUnit
        case buildUnit
    }
    
    // Game statistics
    var player1Houses: Int { countUnits(of: .house, for: .player1) }
    var player2Houses: Int { countUnits(of: .house, for: .player2) }
    
    init(radius: Int = 4) {
        self.mapRadius = radius
        self.validPositions = HexCoordinate.generateHexMap(radius: radius)
        setupInitialUnits()
    }
    
    // MARK: - Unit Management
    
    func unit(at position: HexCoordinate) -> GameUnit? {
        return units[position]
    }
    
    func isEmpty(at position: HexCoordinate) -> Bool {
        return units[position] == nil
    }
    
    func isValidPosition(_ position: HexCoordinate) -> Bool {
        return validPositions.contains(position)
    }
    
    @discardableResult
    func placeUnit(_ unit: GameUnit, at position: HexCoordinate) -> Bool {
        guard isValidPosition(position) && isEmpty(at: position) else {
            return false
        }
        units[position] = unit
        return true
    }
    
    @discardableResult
    func removeUnit(at position: HexCoordinate) -> GameUnit? {
        return units.removeValue(forKey: position)
    }
    
    func moveUnit(from: HexCoordinate, to: HexCoordinate) -> Bool {
        guard let unit = units[from],
              unit.owner == currentPlayer,
              unit.canMove,
              isValidPosition(to),
              isEmpty(at: to) else {
            return false
        }
        
        // Check if the move is within the unit's movement range
        let possibleMoves = unit.possibleMoves(on: self)
        guard possibleMoves.contains(to) else {
            return false
        }
        
        // Remove from old position
        units.removeValue(forKey: from)
        
        // Create new unit at new position (since position is immutable)
        let movedUnit = GameUnit.create(type: unit.type, owner: unit.owner, position: to)
        movedUnit.currentHealth = unit.currentHealth
        movedUnit.hasMovedThisTurn = true
        movedUnit.hasAttackedThisTurn = unit.hasAttackedThisTurn
        
        // Place at new position
        units[to] = movedUnit
        
        return true
    }
    
    func attackUnit(attacker attackerPos: HexCoordinate, target targetPos: HexCoordinate) -> Bool {
        guard let attacker = units[attackerPos],
              let target = units[targetPos],
              attacker.owner == currentPlayer,
              attacker.canAttack,
              target.owner != attacker.owner else {
            return false
        }
        
        // Check if target is within range
        let possibleTargets = attacker.possibleTargets(on: self)
        guard possibleTargets.contains(targetPos) else {
            return false
        }
        
        // Deal damage
        target.takeDamage(attacker.attack)
        attacker.hasAttackedThisTurn = true
        
        // Remove unit if destroyed
        if !target.isAlive {
            removeUnit(at: targetPos)
        }
        
        return true
    }
    
    // MARK: - Building System
    
    func canBuildUnit(type: UnitType, at position: HexCoordinate, for player: PlayerSide) -> Bool {
        guard isValidPosition(position) && isEmpty(at: position) else {
            return false
        }
        
        let cost = getUnitCost(type: type, for: player)
        let currentGold = player == .player1 ? player1Gold : player2Gold
        
        return currentGold >= cost
    }
    
    func buildUnit(type: UnitType, at position: HexCoordinate, for player: PlayerSide) -> Bool {
        guard canBuildUnit(type: type, at: position, for: player) else {
            return false
        }
        
        let cost = getUnitCost(type: type, for: player)
        let unit = GameUnit.create(type: type, owner: player, position: position)
        
        // Deduct cost
        if player == .player1 {
            player1Gold -= cost
        } else {
            player2Gold -= cost
        }
        
        // Place unit
        units[position] = unit
        return true
    }
    
    func getUnitCost(type: UnitType, for player: PlayerSide) -> Int {
        if type == .house {
            let existingHouses = countUnits(of: .house, for: player)
            return GameUnit.getHouseCost(existingHouses: existingHouses)
        }
        return GameUnit.create(type: type, owner: player, position: HexCoordinate(q: 0, r: 0)).cost
    }
    
    // MARK: - Turn Management
    
    func nextPhase() {
        switch turnPhase {
        case .income:
            // Income is now collected at the beginning of the turn via `endTurn()`
            // Simply advance to Build phase if ever encountered
            turnPhase = .build
        case .build:
            turnPhase = .move
        case .move:
            turnPhase = .combat
        case .combat:
            turnPhase = .endTurn
        case .endTurn:
            endTurn()
        }
        
        // Clear UI state
        selectedUnit = nil
        highlightedPositions = []
        gameMode = .selectUnit
    }
    
    func endTurn() {
        // Reset all units' turn flags for current player
        for unit in units.values where unit.owner == currentPlayer {
            unit.resetTurnFlags()
        }
        
        // Switch to next player
        currentPlayer = currentPlayer.opponent
        
        // Collect income for the player whose turn is beginning
        collectIncome()
        
        // Begin the new turn directly in the Build phase
        turnPhase = .build
        
        // Increment turn number when player 1's turn starts
        if currentPlayer == .player1 {
            turnNumber += 1
        }
    }
    
    func collectIncome() {
        let player1Income = countUnits(of: .house, for: .player1) * 10
        let player2Income = countUnits(of: .house, for: .player2) * 10
        
        player1Gold += player1Income
        player2Gold += player2Income
    }
    
    // MARK: - Helper Functions
    
    func countUnits(of type: UnitType, for player: PlayerSide) -> Int {
        return units.values.count { $0.type == type && $0.owner == player && $0.isAlive }
    }
    
    func getUnits(for player: PlayerSide) -> [GameUnit] {
        return units.values.filter { $0.owner == player && $0.isAlive }
    }
    
    func setupInitialUnits() {
        // Player 1 starting units (bottom of map)
        let p1StartPositions = [
            HexCoordinate(q: -2, r: 3),
            HexCoordinate(q: -1, r: 3),
            HexCoordinate(q: 0, r: 3),
            HexCoordinate(q: 1, r: 3),
            HexCoordinate(q: 2, r: 3)
        ]
        
        // Player 2 starting units (top of map)
        let p2StartPositions = [
            HexCoordinate(q: -2, r: -3),
            HexCoordinate(q: -1, r: -3),
            HexCoordinate(q: 0, r: -3),
            HexCoordinate(q: 1, r: -3),
            HexCoordinate(q: 2, r: -3)
        ]
        
        // Place initial scouts for each player
        if p1StartPositions.count >= 2 && p2StartPositions.count >= 2 {
            // Player 1 units
            placeUnit(GameUnit.create(type: .scout, owner: .player1, position: p1StartPositions[1]), at: p1StartPositions[1])
            placeUnit(GameUnit.create(type: .house, owner: .player1, position: p1StartPositions[2]), at: p1StartPositions[2])
            placeUnit(GameUnit.create(type: .scout, owner: .player1, position: p1StartPositions[3]), at: p1StartPositions[3])
            
            // Player 2 units
            placeUnit(GameUnit.create(type: .scout, owner: .player2, position: p2StartPositions[1]), at: p2StartPositions[1])
            placeUnit(GameUnit.create(type: .house, owner: .player2, position: p2StartPositions[2]), at: p2StartPositions[2])
            placeUnit(GameUnit.create(type: .scout, owner: .player2, position: p2StartPositions[3]), at: p2StartPositions[3])
        }
    }
    
    // MARK: - Win Conditions
    
    func checkWinCondition() -> PlayerSide? {
        let p1Units = getUnits(for: .player1)
        let p2Units = getUnits(for: .player2)
        
        // Elimination victory
        if p1Units.isEmpty {
            return .player2
        }
        if p2Units.isEmpty {
            return .player1
        }
        
        // Economic victory (5+ houses)
        if player1Houses >= 5 {
            return .player1
        }
        if player2Houses >= 5 {
            return .player2
        }
        
        return nil
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case mapRadius, units, currentPlayer, turnPhase, turnNumber
        case player1Gold, player2Gold
    }

    // Custom decoder – calls the designated initializer to ensure all
    // `let` properties are set correctly before the remaining state is applied.
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode values that are needed for the designated initializer first
        let radius = try container.decode(Int.self, forKey: .mapRadius)
        self.init(radius: radius)

        // Remaining persisted state
        let unitsArray = try container.decode([GameUnit].self, forKey: .units)
        self.units = Dictionary(uniqueKeysWithValues: unitsArray.map { ($0.position, $0) })

        self.currentPlayer  = try container.decode(PlayerSide.self, forKey: .currentPlayer)
        self.turnPhase      = try container.decode(TurnPhase.self, forKey: .turnPhase)
        self.turnNumber     = try container.decode(Int.self, forKey: .turnNumber)
        self.player1Gold    = try container.decode(Int.self, forKey: .player1Gold)
        self.player2Gold    = try container.decode(Int.self, forKey: .player2Gold)

        // UI-only runtime state – ensure it starts clean.
        self.selectedUnit = nil
        self.highlightedPositions = []
        self.gameMode = .selectUnit
    }

    // Encoder remains straightforward – just mirror the CodingKeys above.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(mapRadius,    forKey: .mapRadius)
        try container.encode(Array(units.values), forKey: .units)
        try container.encode(currentPlayer, forKey: .currentPlayer)
        try container.encode(turnPhase,    forKey: .turnPhase)
        try container.encode(turnNumber,   forKey: .turnNumber)
        try container.encode(player1Gold,  forKey: .player1Gold)
        try container.encode(player2Gold,  forKey: .player2Gold)
    }
}

