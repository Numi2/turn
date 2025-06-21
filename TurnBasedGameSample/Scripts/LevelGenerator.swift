//
//  LevelGenerator.swift
//  TurnBasedGameSample
//
//  Created for Hexagon Strategy Game
//

import Foundation

/// Generates game levels, balances units, and creates map configurations
struct LevelGenerator {
    
    // MARK: - Level Configuration
    
    struct LevelConfig {
        let name: String
        let mapRadius: Int
        let player1StartGold: Int
        let player2StartGold: Int
        let player1StartUnits: [(UnitType, HexCoordinate)]
        let player2StartUnits: [(UnitType, HexCoordinate)]
        let neutralBuildings: [(UnitType, HexCoordinate)] // For future expansion
        let description: String
        
        init(name: String, mapRadius: Int, startGold: Int = 100, 
             p1Units: [(UnitType, HexCoordinate)] = [], 
             p2Units: [(UnitType, HexCoordinate)] = [],
             neutralBuildings: [(UnitType, HexCoordinate)] = [],
             description: String = "") {
            self.name = name
            self.mapRadius = mapRadius
            self.player1StartGold = startGold
            self.player2StartGold = startGold
            self.player1StartUnits = p1Units
            self.player2StartUnits = p2Units
            self.neutralBuildings = neutralBuildings
            self.description = description
        }
    }
    
    // MARK: - Predefined Levels
    
    static let standardLevels: [LevelConfig] = [
        // Tutorial Level - Small map, basic units
        LevelConfig(
            name: "Tutorial",
            mapRadius: 3,
            startGold: 50,
            p1Units: [
                (.scout, HexCoordinate(q: 0, r: 2)),
                (.house, HexCoordinate(q: 1, r: 2))
            ],
            p2Units: [
                (.scout, HexCoordinate(q: 0, r: -2)),
                (.house, HexCoordinate(q: -1, r: -2))
            ],
            description: "Learn the basics with a small map and simple units"
        ),
        
        // Balanced Start - Medium map, equal forces
        LevelConfig(
            name: "Balanced Start",
            mapRadius: 4,
            startGold: 100,
            p1Units: [
                (.scout, HexCoordinate(q: -1, r: 3)),
                (.house, HexCoordinate(q: 0, r: 3)),
                (.scout, HexCoordinate(q: 1, r: 3))
            ],
            p2Units: [
                (.scout, HexCoordinate(q: -1, r: -3)),
                (.house, HexCoordinate(q: 0, r: -3)),
                (.scout, HexCoordinate(q: 1, r: -3))
            ],
            description: "Standard balanced game with equal starting forces"
        ),
        
        // Economic Focus - Fewer units, more houses
        LevelConfig(
            name: "Economic Focus",
            mapRadius: 5,
            startGold: 150,
            p1Units: [
                (.house, HexCoordinate(q: -1, r: 4)),
                (.house, HexCoordinate(q: 0, r: 4)),
                (.house, HexCoordinate(q: 1, r: 4)),
                (.warrior, HexCoordinate(q: 0, r: 3))
            ],
            p2Units: [
                (.house, HexCoordinate(q: -1, r: -4)),
                (.house, HexCoordinate(q: 0, r: -4)),
                (.house, HexCoordinate(q: 1, r: -4)),
                (.warrior, HexCoordinate(q: 0, r: -3))
            ],
            description: "Focus on economic development with multiple starting houses"
        ),
        
        // Fortress Defense - Defensive scenario
        LevelConfig(
            name: "Fortress Defense",
            mapRadius: 4,
            startGold: 80,
            p1Units: [
                (.watchtower, HexCoordinate(q: 0, r: 3)),
                (.warrior, HexCoordinate(q: -1, r: 3)),
                (.warrior, HexCoordinate(q: 1, r: 3)),
                (.house, HexCoordinate(q: 0, r: 2))
            ],
            p2Units: [
                (.watchtower, HexCoordinate(q: 0, r: -3)),
                (.warrior, HexCoordinate(q: -1, r: -3)),
                (.warrior, HexCoordinate(q: 1, r: -3)),
                (.house, HexCoordinate(q: 0, r: -2))
            ],
            description: "Defensive gameplay with starting towers and warriors"
        ),
        
        // Large Battle - Big map for epic games
        LevelConfig(
            name: "Large Battle",
            mapRadius: 6,
            startGold: 200,
            p1Units: [
                (.scout, HexCoordinate(q: -2, r: 5)),
                (.warrior, HexCoordinate(q: -1, r: 5)),
                (.house, HexCoordinate(q: 0, r: 5)),
                (.warrior, HexCoordinate(q: 1, r: 5)),
                (.scout, HexCoordinate(q: 2, r: 5)),
                (.watchtower, HexCoordinate(q: 0, r: 4))
            ],
            p2Units: [
                (.scout, HexCoordinate(q: -2, r: -5)),
                (.warrior, HexCoordinate(q: -1, r: -5)),
                (.house, HexCoordinate(q: 0, r: -5)),
                (.warrior, HexCoordinate(q: 1, r: -5)),
                (.scout, HexCoordinate(q: 2, r: -5)),
                (.watchtower, HexCoordinate(q: 0, r: -4))
            ],
            description: "Large-scale warfare on an expanded battlefield"
        )
    ]
    
    // MARK: - Dynamic Level Generation
    
    /// Generate a random level based on difficulty and style preferences
    static func generateRandomLevel(difficulty: Difficulty, style: GameStyle, mapSize: MapSize) -> LevelConfig {
        let radius = mapSize.radius
        let goldMultiplier = difficulty.goldMultiplier
        let unitCount = difficulty.unitCount
        
        let baseGold = Int(100 * goldMultiplier)
        
        switch style {
        case .balanced:
            return generateBalancedLevel(radius: radius, gold: baseGold, unitCount: unitCount)
        case .economic:
            return generateEconomicLevel(radius: radius, gold: baseGold, unitCount: unitCount)
        case .military:
            return generateMilitaryLevel(radius: radius, gold: baseGold, unitCount: unitCount)
        case .defensive:
            return generateDefensiveLevel(radius: radius, gold: baseGold, unitCount: unitCount)
        }
    }
    
    enum Difficulty {
        case easy, normal, hard
        
        var goldMultiplier: Double {
            switch self {
            case .easy: return 1.5
            case .normal: return 1.0
            case .hard: return 0.7
            }
        }
        
        var unitCount: Int {
            switch self {
            case .easy: return 2
            case .normal: return 3
            case .hard: return 4
            }
        }
    }
    
    enum GameStyle {
        case balanced, economic, military, defensive
    }
    
    enum MapSize {
        case small, medium, large
        
        var radius: Int {
            switch self {
            case .small: return 3
            case .medium: return 4
            case .large: return 6
            }
        }
    }
    
    // MARK: - Specific Level Generators
    
    private static func generateBalancedLevel(radius: Int, gold: Int, unitCount: Int) -> LevelConfig {
        let p1StartRow = radius - 1
        let p2StartRow = -(radius - 1)
        
        var p1Units: [(UnitType, HexCoordinate)] = []
        var p2Units: [(UnitType, HexCoordinate)] = []
        
        // Always start with a house in the center
        p1Units.append((.house, HexCoordinate(q: 0, r: p1StartRow)))
        p2Units.append((.house, HexCoordinate(q: 0, r: p2StartRow)))
        
        // Add balanced units around the house
        let unitTypes: [UnitType] = [.scout, .warrior, .scout]
        for i in 0..<min(unitCount, unitTypes.count) {
            let offset = i - (unitTypes.count / 2)
            p1Units.append((unitTypes[i], HexCoordinate(q: offset, r: p1StartRow - 1)))
            p2Units.append((unitTypes[i], HexCoordinate(q: offset, r: p2StartRow + 1)))
        }
        
        return LevelConfig(
            name: "Random Balanced (\(radius))",
            mapRadius: radius,
            startGold: gold,
            p1Units: p1Units,
            p2Units: p2Units,
            description: "Randomly generated balanced level"
        )
    }
    
    private static func generateEconomicLevel(radius: Int, gold: Int, unitCount: Int) -> LevelConfig {
        let p1StartRow = radius - 1
        let p2StartRow = -(radius - 1)
        
        var p1Units: [(UnitType, HexCoordinate)] = []
        var p2Units: [(UnitType, HexCoordinate)] = []
        
        // Start with multiple houses
        let houseCount = max(2, unitCount / 2)
        for i in 0..<houseCount {
            let offset = i - (houseCount / 2)
            p1Units.append((.house, HexCoordinate(q: offset, r: p1StartRow)))
            p2Units.append((.house, HexCoordinate(q: offset, r: p2StartRow)))
        }
        
        // Add minimal military units
        p1Units.append((.scout, HexCoordinate(q: 0, r: p1StartRow - 1)))
        p2Units.append((.scout, HexCoordinate(q: 0, r: p2StartRow + 1)))
        
        return LevelConfig(
            name: "Random Economic (\(radius))",
            mapRadius: radius,
            startGold: gold + 50, // Bonus starting gold for economic style
            p1Units: p1Units,
            p2Units: p2Units,
            description: "Randomly generated economic-focused level"
        )
    }
    
    private static func generateMilitaryLevel(radius: Int, gold: Int, unitCount: Int) -> LevelConfig {
        let p1StartRow = radius - 1
        let p2StartRow = -(radius - 1)
        
        var p1Units: [(UnitType, HexCoordinate)] = []
        var p2Units: [(UnitType, HexCoordinate)] = []
        
        // Minimal economy
        p1Units.append((.house, HexCoordinate(q: 0, r: p1StartRow)))
        p2Units.append((.house, HexCoordinate(q: 0, r: p2StartRow)))
        
        // Focus on military units
        let militaryUnits: [UnitType] = [.warrior, .knight, .warrior, .scout, .scout]
        for i in 0..<min(unitCount, militaryUnits.count) {
            let offset = i - (militaryUnits.count / 2)
            let rowOffset = (i % 2 == 0) ? -1 : -2
            
            p1Units.append((militaryUnits[i], HexCoordinate(q: offset, r: p1StartRow + rowOffset)))
            p2Units.append((militaryUnits[i], HexCoordinate(q: offset, r: p2StartRow - rowOffset)))
        }
        
        return LevelConfig(
            name: "Random Military (\(radius))",
            mapRadius: radius,
            startGold: gold - 20, // Less starting gold, more units
            p1Units: p1Units,
            p2Units: p2Units,
            description: "Randomly generated military-focused level"
        )
    }
    
    private static func generateDefensiveLevel(radius: Int, gold: Int, unitCount: Int) -> LevelConfig {
        let p1StartRow = radius - 1
        let p2StartRow = -(radius - 1)
        
        var p1Units: [(UnitType, HexCoordinate)] = []
        var p2Units: [(UnitType, HexCoordinate)] = []
        
        // Start with defensive structures
        p1Units.append((.watchtower, HexCoordinate(q: 0, r: p1StartRow)))
        p2Units.append((.watchtower, HexCoordinate(q: 0, r: p2StartRow)))
        
        // Add house for economy
        p1Units.append((.house, HexCoordinate(q: -1, r: p1StartRow)))
        p2Units.append((.house, HexCoordinate(q: -1, r: p2StartRow)))
        
        // Add defensive units
        let defensiveUnits: [UnitType] = [.warrior, .warrior, .scout]
        for i in 0..<min(unitCount - 1, defensiveUnits.count) {
            let offset = i - 1
            p1Units.append((defensiveUnits[i], HexCoordinate(q: offset, r: p1StartRow - 1)))
            p2Units.append((defensiveUnits[i], HexCoordinate(q: offset, r: p2StartRow + 1)))
        }
        
        return LevelConfig(
            name: "Random Defensive (\(radius))",
            mapRadius: radius,
            startGold: gold,
            p1Units: p1Units,
            p2Units: p2Units,
            description: "Randomly generated defensive-focused level"
        )
    }
    
    // MARK: - Unit Balancing
    
    /// Get suggested unit stats for balanced gameplay
    static func getBalancedUnitStats() -> [UnitType: (health: Int, attack: Int, cost: Int, movement: Int, range: Int)] {
        return [
            .scout: (health: 20, attack: 5, cost: 10, movement: 3, range: 1),
            .warrior: (health: 40, attack: 10, cost: 25, movement: 2, range: 1),
            .knight: (health: 70, attack: 18, cost: 50, movement: 2, range: 1),
            .champion: (health: 120, attack: 30, cost: 100, movement: 2, range: 1),
            .watchtower: (health: 60, attack: 8, cost: 40, movement: 0, range: 2),
            .fortress: (health: 120, attack: 15, cost: 80, movement: 0, range: 3),
            .house: (health: 50, attack: 0, cost: 30, movement: 0, range: 0)
        ]
    }
    
    /// Calculate if current game balance is within acceptable parameters
    static func analyzeBalance(map: GameMap) -> BalanceReport {
        let p1Units = map.getUnits(for: .player1)
        let p2Units = map.getUnits(for: .player2)
        
        let p1TotalValue = p1Units.reduce(0) { $0 + $1.cost }
        let p2TotalValue = p2Units.reduce(0) { $0 + $1.cost }
        
        let p1Income = map.player1Houses * 10
        let p2Income = map.player2Houses * 10
        
        let unitBalance = Double(p1TotalValue) / Double(max(p2TotalValue, 1))
        let incomeBalance = Double(p1Income) / Double(max(p2Income, 1))
        
        return BalanceReport(
            player1UnitValue: p1TotalValue,
            player2UnitValue: p2TotalValue,
            player1Income: p1Income,
            player2Income: p2Income,
            unitBalanceRatio: unitBalance,
            incomeBalanceRatio: incomeBalance,
            isBalanced: (0.7...1.3).contains(unitBalance) && (0.7...1.3).contains(incomeBalance)
        )
    }
    
    struct BalanceReport {
        let player1UnitValue: Int
        let player2UnitValue: Int
        let player1Income: Int
        let player2Income: Int
        let unitBalanceRatio: Double
        let incomeBalanceRatio: Double
        let isBalanced: Bool
        
        var description: String {
            return """
            Balance Report:
            Player 1 Unit Value: \(player1UnitValue) | Player 2 Unit Value: \(player2UnitValue)
            Player 1 Income: \(player1Income) | Player 2 Income: \(player2Income)
            Unit Balance Ratio: \(String(format: "%.2f", unitBalanceRatio))
            Income Balance Ratio: \(String(format: "%.2f", incomeBalanceRatio))
            Status: \(isBalanced ? "✅ Balanced" : "⚠️ Imbalanced")
            """
        }
    }
}

// MARK: - Extension for GameMap

extension GameMap {
    
    /// Apply a level configuration to this map
    func applyLevel(_ config: LevelGenerator.LevelConfig) {
        // Clear existing state
        units.removeAll()
        
        // Set map properties
        player1Gold = config.player1StartGold
        player2Gold = config.player2StartGold
        currentPlayer = .player1
        turnPhase = .build
        turnNumber = 1
        
        // Place Player 1 units
        for (unitType, position) in config.player1StartUnits {
            let unit = GameUnit.create(type: unitType, owner: .player1, position: position)
            units[position] = unit
        }
        
        // Place Player 2 units
        for (unitType, position) in config.player2StartUnits {
            let unit = GameUnit.create(type: unitType, owner: .player2, position: position)
            units[position] = unit
        }
        
        // Reset UI state
        selectedUnit = nil
        highlightedPositions = []
        gameMode = .selectUnit
    }
}