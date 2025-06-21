//
//  GameAI.swift
//  TurnBasedGameSample
//
//  Created for Hexagon Strategy Game - AI System
//

import Foundation
import SwiftUI

/// AI difficulty levels
enum AIDifficulty: String, CaseIterable {
    case ultra = "ultra"
    
    var description: String {
        switch self {
        case .ultra: return "Ultra"
        }
    }
}

/// Strategic AI for playing the hexagon strategy game
class GameAI: ObservableObject {
    let difficulty: AIDifficulty
    let playerSide: PlayerSide
    
    init(difficulty: AIDifficulty = .ultra, playerSide: PlayerSide = .player2) {
        self.difficulty = difficulty
        self.playerSide = playerSide
    }
    
    /// Make AI turn decisions based on current game state
    func makeMove(gameMap: GameMap) async {
        guard gameMap.currentPlayer == playerSide else { return }
        
        // Add small delay to make AI moves visible to human player
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        switch gameMap.turnPhase {
        case .income:
            // Income is automatic, just proceed
            _ = await MainActor.run {
                gameMap.nextPhase()
            }
            
        case .build:
            await performBuildPhase(gameMap: gameMap)
            
        case .move:
            await performMovePhase(gameMap: gameMap)
            
        case .combat:
            await performCombatPhase(gameMap: gameMap)
            
        case .endTurn:
            _ = await MainActor.run {
                gameMap.nextPhase()
            }
        }
    }
    
    // MARK: - AI Phase Actions
    
    private func performBuildPhase(gameMap: GameMap) async {
        let myGold = playerSide == .player1 ? gameMap.player1Gold : gameMap.player2Gold
        let myHouses = gameMap.countUnits(of: .house, for: playerSide)
        
        // Ultra AI strategy: Aggressive expansion and military focus
        var builtSomething = false
        
        // Priority 1: Build houses for economy (if we have less than 3)
        if myHouses < 3 && myGold >= gameMap.getUnitCost(type: .house, for: playerSide) {
            if let buildPosition = findBestBuildPosition(for: .house, gameMap: gameMap) {
                _ = await MainActor.run {
                    gameMap.buildUnit(type: .house, at: buildPosition, for: playerSide)
                }
                builtSomething = true
            }
        }
        
        // Priority 2: Build defensive towers if under threat
        let threatLevel = assessThreatLevel(gameMap: gameMap)
        if threatLevel > 2 && myGold >= gameMap.getUnitCost(type: .watchtower, for: playerSide) {
            if let buildPosition = findBestDefensePosition(gameMap: gameMap) {
                _ = await MainActor.run {
                    gameMap.buildUnit(type: .watchtower, at: buildPosition, for: playerSide)
                }
                builtSomething = true
            }
        }
        
        // Priority 3: Build military units aggressively
        if !builtSomething {
            let unitToBuild = chooseOptimalMilitaryUnit(gameMap: gameMap)
            if myGold >= gameMap.getUnitCost(type: unitToBuild, for: playerSide) {
                if let buildPosition = findBestBuildPosition(for: unitToBuild, gameMap: gameMap) {
                    _ = await MainActor.run {
                        gameMap.buildUnit(type: unitToBuild, at: buildPosition, for: playerSide)
                    }
                }
            }
        }
        
        _ = await MainActor.run {
            gameMap.nextPhase()
        }
    }
    
    private func performMovePhase(gameMap: GameMap) async {
        let myUnits = gameMap.getUnits(for: playerSide).filter { $0.canMove }
        
        for unit in myUnits {
            let optimalMove = findOptimalMove(for: unit, gameMap: gameMap)
            if let moveTarget = optimalMove {
                _ = await MainActor.run {
                    gameMap.moveUnit(from: unit.position, to: moveTarget)
                }
                // Small delay between moves for visibility
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            }
        }
        
        _ = await MainActor.run {
            gameMap.nextPhase()
        }
    }
    
    private func performCombatPhase(gameMap: GameMap) async {
        let myUnits = gameMap.getUnits(for: playerSide).filter { $0.canAttack }
        
        // Sort by attack priority (highest damage first)
        let sortedUnits = myUnits.sorted { $0.attack > $1.attack }
        
        for unit in sortedUnits {
            let targets = unit.possibleTargets(on: gameMap)
            if let bestTarget = chooseBestTarget(targets: Array(targets), gameMap: gameMap) {
                _ = await MainActor.run {
                    gameMap.attackUnit(attacker: unit.position, target: bestTarget)
                }
                // Small delay between attacks for visibility
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            }
        }
        
        _ = await MainActor.run {
            gameMap.nextPhase()
        }
    }
    
    // MARK: - AI Decision Making
    
    private func chooseOptimalMilitaryUnit(gameMap: GameMap) -> UnitType {
        let myGold = playerSide == .player1 ? gameMap.player1Gold : gameMap.player2Gold
        
        // Ultra AI prefers powerful units
        if myGold >= 100 {
            return .champion
        } else if myGold >= 50 {
            return .knight
        } else if myGold >= 25 {
            return .warrior
        } else {
            return .scout
        }
    }
    
    private func findBestBuildPosition(for unitType: UnitType, gameMap: GameMap) -> HexCoordinate? {
        let myUnits = gameMap.getUnits(for: playerSide)
        
        // Find empty positions near our units
        var candidates: [HexCoordinate] = []
        
        for unit in myUnits {
            for neighbor in unit.position.neighbors {
                if gameMap.isValidPosition(neighbor) && gameMap.isEmpty(at: neighbor) {
                    candidates.append(neighbor)
                }
            }
        }
        
        // Remove duplicates
        candidates = Array(Set(candidates))
        
        if unitType == .house {
            // Houses prefer positions away from front lines
            return candidates.max { pos1, pos2 in
                let threat1 = calculatePositionThreat(pos1, gameMap: gameMap)
                let threat2 = calculatePositionThreat(pos2, gameMap: gameMap)
                return threat1 > threat2
            }
        } else {
            // Military units prefer positions closer to enemies
            return candidates.min { pos1, pos2 in
                let distance1 = distanceToNearestEnemy(pos1, gameMap: gameMap)
                let distance2 = distanceToNearestEnemy(pos2, gameMap: gameMap)
                return distance1 < distance2
            }
        }
    }
    
    private func findBestDefensePosition(gameMap: GameMap) -> HexCoordinate? {
        let myHouses = gameMap.getUnits(for: playerSide).filter { $0.type == .house }
        
        // Find positions that can defend multiple houses
        var candidates: [HexCoordinate] = []
        
        for house in myHouses {
            for neighbor in house.position.neighbors(within: 2) {
                if gameMap.isValidPosition(neighbor) && gameMap.isEmpty(at: neighbor) {
                    candidates.append(neighbor)
                }
            }
        }
        
        return candidates.max { pos1, pos2 in
            let coverage1 = countProtectedBuildings(pos1, gameMap: gameMap)
            let coverage2 = countProtectedBuildings(pos2, gameMap: gameMap)
            return coverage1 < coverage2
        }
    }
    
    private func findOptimalMove(for unit: GameUnit, gameMap: GameMap) -> HexCoordinate? {
        let possibleMoves = unit.possibleMoves(on: gameMap)
        guard !possibleMoves.isEmpty else { return nil }
        
        if unit.type.isSoldier {
            // Soldiers move toward enemies
            return possibleMoves.min { pos1, pos2 in
                let distance1 = distanceToNearestEnemy(pos1, gameMap: gameMap)
                let distance2 = distanceToNearestEnemy(pos2, gameMap: gameMap)
                return distance1 < distance2
            }
        }
        
        return possibleMoves.randomElement()
    }
    
    private func chooseBestTarget(targets: [HexCoordinate], gameMap: GameMap) -> HexCoordinate? {
        guard !targets.isEmpty else { return nil }
        
        // Ultra AI targets by priority: Houses > Weak units > Strong units
        let targetUnits = targets.compactMap { gameMap.unit(at: $0) }
        
        // Highest priority: Houses (economic targets)
        if let house = targetUnits.first(where: { $0.type == .house }) {
            return house.position
        }
        
        // Second priority: Weakest unit that can be killed
        if let weakTarget = targetUnits.filter({ $0.currentHealth <= 30 }).min(by: { $0.currentHealth < $1.currentHealth }) {
            return weakTarget.position
        }
        
        // Third priority: Highest value target
        return targetUnits.max { $0.cost < $1.cost }?.position
    }
    
    // MARK: - Helper Functions
    
    private func assessThreatLevel(gameMap: GameMap) -> Int {
        let enemyUnits = gameMap.getUnits(for: playerSide.opponent)
        
        var threatLevel = 0
        
        for enemy in enemyUnits {
            let targets = enemy.possibleTargets(on: gameMap)
            for target in targets {
                if let myUnit = gameMap.unit(at: target), myUnit.owner == playerSide {
                    threatLevel += 1
                    if myUnit.type == .house {
                        threatLevel += 2 // Houses are high priority targets
                    }
                }
            }
        }
        
        return threatLevel
    }
    
    private func distanceToNearestEnemy(_ position: HexCoordinate, gameMap: GameMap) -> Int {
        let enemyUnits = gameMap.getUnits(for: playerSide.opponent)
        guard !enemyUnits.isEmpty else { return Int.max }
        
        return enemyUnits.map { position.distance(to: $0.position) }.min() ?? Int.max
    }
    
    private func calculatePositionThreat(_ position: HexCoordinate, gameMap: GameMap) -> Int {
        let enemyUnits = gameMap.getUnits(for: playerSide.opponent)
        var threat = 0
        
        for enemy in enemyUnits {
            let distance = position.distance(to: enemy.position)
            if distance <= enemy.attackRange + enemy.movementRange {
                threat += enemy.attack
            }
        }
        
        return threat
    }
    
    private func countProtectedBuildings(_ position: HexCoordinate, gameMap: GameMap) -> Int {
        let myBuildings = gameMap.getUnits(for: playerSide).filter { $0.type.isBuilding }
        let towerRange = 2 // Watchtower range
        
        return myBuildings.count { building in
            position.distance(to: building.position) <= towerRange
        }
    }
}
