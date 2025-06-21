//
//  GameUnit.swift
//  TurnBasedGameSample
//
//  Created for Hexagon Strategy Game
//

import Foundation
import SwiftUI

/// Represents the type of game unit
enum UnitType: String, Codable, CaseIterable {
    // Soldiers
    case scout = "scout"
    case warrior = "warrior"
    case knight = "knight"
    case champion = "champion"
    
    // Buildings
    case watchtower = "watchtower"
    case fortress = "fortress"
    case house = "house"
    
    var isBuilding: Bool {
        switch self {
        case .watchtower, .fortress, .house:
            return true
        default:
            return false
        }
    }
    
    var isSoldier: Bool {
        switch self {
        case .scout, .warrior, .knight, .champion:
            return true
        default:
            return false
        }
    }
    
    var isTower: Bool {
        switch self {
        case .watchtower, .fortress:
            return true
        default:
            return false
        }
    }
}

/// Represents which player owns a unit
enum PlayerSide: String, Codable {
    case player1 = "player1"
    case player2 = "player2"
    
    var opponent: PlayerSide {
        switch self {
        case .player1: return .player2
        case .player2: return .player1
        }
    }
}

/// Base class for all game units (soldiers, towers, houses)
class GameUnit: Identifiable, Codable, ObservableObject {
    let id = UUID()
    let type: UnitType
    let owner: PlayerSide
    let position: HexCoordinate
    
    @Published var currentHealth: Int
    @Published var hasMovedThisTurn: Bool = false
    @Published var hasAttackedThisTurn: Bool = false
    
    // Base stats that define the unit
    let maxHealth: Int
    let attack: Int
    let cost: Int
    let movementRange: Int
    let attackRange: Int
    
    init(type: UnitType, owner: PlayerSide, position: HexCoordinate, 
         maxHealth: Int, attack: Int, cost: Int, movementRange: Int = 1, attackRange: Int = 1) {
        self.type = type
        self.owner = owner
        self.position = position
        self.maxHealth = maxHealth
        self.currentHealth = maxHealth
        self.attack = attack
        self.cost = cost
        self.movementRange = movementRange
        self.attackRange = attackRange
    }
    
    // MARK: - Codable
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let type = try container.decode(UnitType.self, forKey: .type)
        let owner = try container.decode(PlayerSide.self, forKey: .owner)
        let position = try container.decode(HexCoordinate.self, forKey: .position)
        
        let currentHealth = try container.decode(Int.self, forKey: .currentHealth)
        let hasMovedThisTurn = try container.decode(Bool.self, forKey: .hasMovedThisTurn)
        let hasAttackedThisTurn = try container.decode(Bool.self, forKey: .hasAttackedThisTurn)
        
        let maxHealth = try container.decode(Int.self, forKey: .maxHealth)
        let attack = try container.decode(Int.self, forKey: .attack)
        let cost = try container.decode(Int.self, forKey: .cost)
        let movementRange = try container.decode(Int.self, forKey: .movementRange)
        let attackRange = try container.decode(Int.self, forKey: .attackRange)
        
        // Call the designated initializer to satisfy all `let` properties
        self.init(type: type,
                  owner: owner,
                  position: position,
                  maxHealth: maxHealth,
                  attack: attack,
                  cost: cost,
                  movementRange: movementRange,
                  attackRange: attackRange)
        
        // Apply the remaining mutable state decoded from JSON
        self.currentHealth = currentHealth
        self.hasMovedThisTurn = hasMovedThisTurn
        self.hasAttackedThisTurn = hasAttackedThisTurn
    }
    
    // MARK: - Computed Properties
    
    var isAlive: Bool {
        return currentHealth > 0
    }
    
    var isFullHealth: Bool {
        return currentHealth >= maxHealth
    }
    
    var healthPercentage: Double {
        return Double(currentHealth) / Double(maxHealth)
    }
    
    var canMove: Bool {
        return !hasMovedThisTurn && isAlive && !type.isBuilding
    }
    
    var canAttack: Bool {
        return !hasAttackedThisTurn && isAlive
    }
    
    /// Get all positions this unit can move to
    func possibleMoves(on map: GameMap) -> Set<HexCoordinate> {
        guard canMove else { return [] }
        
        var reachable = Set<HexCoordinate>()
        var frontier = [position]
        var visited = Set<HexCoordinate>([position])
        
        for _ in 1...movementRange {
            var nextFrontier: [HexCoordinate] = []
            
            for currentPos in frontier {
                for neighbor in currentPos.neighbors {
                    if !visited.contains(neighbor) && map.isValidPosition(neighbor) && map.isEmpty(at: neighbor) {
                        visited.insert(neighbor)
                        nextFrontier.append(neighbor)
                        reachable.insert(neighbor)
                    }
                }
            }
            
            frontier = nextFrontier
            if frontier.isEmpty { break }
        }
        
        return reachable
    }
    
    /// Get all positions this unit can attack
    func possibleTargets(on map: GameMap) -> Set<HexCoordinate> {
        guard canAttack else { return [] }
        
        let targetPositions = position.neighbors(within: attackRange)
        return Set(targetPositions.filter { pos in
            guard let unit = map.unit(at: pos) else { return false }
            return unit.owner != self.owner && unit.isAlive
        })
    }
    
    // MARK: - Actions
    
    func takeDamage(_ damage: Int) {
        currentHealth = max(0, currentHealth - damage)
    }
    
    func heal(_ amount: Int) {
        currentHealth = min(maxHealth, currentHealth + amount)
    }
    
    func resetTurnFlags() {
        hasMovedThisTurn = false
        hasAttackedThisTurn = false
    }
    
    // MARK: - Display Properties
    
    var displayName: String {
        return type.rawValue.capitalized
    }
    
    var emoji: String {
        switch type {
        case .scout: return "🏃"
        case .warrior: return "⚔️"
        case .knight: return "🛡️"
        case .champion: return "👑"
        case .watchtower: return "🗼"
        case .fortress: return "🏰"
        case .house: return "🏠"
        }
    }
    
    var color: Color {
        switch owner {
        case .player1: return .blue
        case .player2: return .red
        }
    }
}

// MARK: - Codable Implementation

extension GameUnit {
    enum CodingKeys: String, CodingKey {
        case type, owner, position, currentHealth, hasMovedThisTurn, hasAttackedThisTurn
        case maxHealth, attack, cost, movementRange, attackRange
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type, forKey: .type)
        try container.encode(owner, forKey: .owner)
        try container.encode(position, forKey: .position)
        try container.encode(currentHealth, forKey: .currentHealth)
        try container.encode(hasMovedThisTurn, forKey: .hasMovedThisTurn)
        try container.encode(hasAttackedThisTurn, forKey: .hasAttackedThisTurn)
        
        try container.encode(maxHealth, forKey: .maxHealth)
        try container.encode(attack, forKey: .attack)
        try container.encode(cost, forKey: .cost)
        try container.encode(movementRange, forKey: .movementRange)
        try container.encode(attackRange, forKey: .attackRange)
    }
}

// MARK: - Unit Factory

extension GameUnit {
    
    /// Create a unit of the specified type
    static func create(type: UnitType, owner: PlayerSide, position: HexCoordinate) -> GameUnit {
        switch type {
        case .scout:
            return GameUnit(type: type, owner: owner, position: position,
                          maxHealth: 20, attack: 5, cost: 10, movementRange: 3, attackRange: 1)
        case .warrior:
            return GameUnit(type: type, owner: owner, position: position,
                          maxHealth: 40, attack: 10, cost: 25, movementRange: 2, attackRange: 1)
        case .knight:
            return GameUnit(type: type, owner: owner, position: position,
                          maxHealth: 70, attack: 18, cost: 50, movementRange: 2, attackRange: 1)
        case .champion:
            return GameUnit(type: type, owner: owner, position: position,
                          maxHealth: 120, attack: 30, cost: 100, movementRange: 2, attackRange: 1)
        case .watchtower:
            return GameUnit(type: type, owner: owner, position: position,
                          maxHealth: 60, attack: 8, cost: 40, movementRange: 0, attackRange: 2)
        case .fortress:
            return GameUnit(type: type, owner: owner, position: position,
                          maxHealth: 120, attack: 15, cost: 80, movementRange: 0, attackRange: 3)
        case .house:
            return GameUnit(type: type, owner: owner, position: position,
                          maxHealth: 50, attack: 0, cost: 30, movementRange: 0, attackRange: 0)
        }
    }
    
    /// Get the cost for building a house (progressive pricing)
    static func getHouseCost(existingHouses: Int) -> Int {
        return 30 + (existingHouses * 20)
    }
}

