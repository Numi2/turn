/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension for turn-based games that handles match data that the game sends between players.
*/

import Foundation
import GameKit
import SwiftUI

// MARK: Game Data Objects

// A message that one player sends to another.
struct Message: Identifiable {
    var id = UUID()
    var content: String
    var playerName: String
    var isLocalPlayer: Bool = false
}

// A participant object with their items.
struct Participant: Identifiable {
    var id = UUID()
    var player: GKPlayer
    var avatar = Image(systemName: "person")
    var items = 50
}

// Codable game data for sending to players.
struct GameData: Codable {
    var count: Int
    var items: [String: Int]
    
    // New strategy game data
    var gameMap: GameMap?
    var gameVersion: Int = 2 // Version 2 for strategy game
}

extension TurnBasedGame {
    
    // MARK: Codable Game Data
    
    /// Creates a data representation of the game count and items for each player.
    ///
    /// - Returns: A representation of game data that contains only the game scores.
    func encodeGameData() -> Data? {
        // Create a dictionary of items for each player.
        var items = [String: Int]()
        
        // Add the local player's items.
        if let localPlayerName = localParticipant?.player.displayName {
            items[localPlayerName] = localParticipant?.items
        }
        
        // Add the opponent's items.
        if let opponentPlayerName = opponent?.player.displayName {
            items[opponentPlayerName] = opponent?.items
        }
        
        let gameData = GameData(
            count: count, 
            items: items,
            gameMap: isStrategyGame ? gameMap : nil,
            gameVersion: isStrategyGame ? 2 : 1
        )
        return encode(gameData: gameData)
    }
    
    /// Creates a data representation from the game data for sending to other players.
    ///
    /// - Returns: A representation of the game data.
    func encode(gameData: GameData) -> Data? {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        
        do {
            let data = try encoder.encode(gameData)
            return data
        } catch {
            print("Error: \(error.localizedDescription).")
            return nil
        }
    }
    
    /// Decodes a data representation of game data and updates the scores.
    ///
    /// - Parameter matchData: A data representation of the game data.
    func decodeGameData(matchData: Data) {
        let gameData = try? PropertyListDecoder().decode(GameData.self, from: matchData)
        guard let gameData = gameData else { return }

        // Determine if this is a strategy game based on version
        isStrategyGame = gameData.gameVersion >= 2
        
        if isStrategyGame, let receivedGameMap = gameData.gameMap {
            // Update strategy game data
            gameMap = receivedGameMap
            
            // Determine which player is local vs opponent based on current player
            updatePlayerSideMapping()
        } else {
            // Legacy counter game
            count = gameData.count

            // Set the local player's items.
            if let localPlayerName = localParticipant?.player.displayName {
                if let items = gameData.items[localPlayerName] {
                    localParticipant?.items = items
                }
            }

            // Set the opponent's items.
            if let opponentPlayerName = opponent?.player.displayName {
                if let items = gameData.items[opponentPlayerName] {
                    opponent?.items = items
                }
            }
        }
    }
    
    /// Updates the mapping between local/opponent and player1/player2 based on the game state
    private func updatePlayerSideMapping() {
        // This method helps ensure the correct player perspective in multiplayer
        // For now, we'll use a simple approach where the first player to join is player1
        if let localPlayerName = localParticipant?.player.displayName,
           let opponentPlayerName = opponent?.player.displayName {
            
            // For strategy game, we need to determine which PlayerSide the local player is
            // This is a simplified approach - in a full implementation you might want
            // to store this mapping more explicitly in the game data
            
            // The player who started the match is typically player1
            // But for now, we'll use alphabetical order as a consistent way to assign sides
            let isLocalPlayerFirst = localPlayerName < opponentPlayerName
            
            // Update UI to reflect current game state
            // The actual game logic uses the gameMap's currentPlayer property
        }
    }
//        do {
//            if let gameData = try? PropertyListDecoder().decode(GameData.self, from: matchData) {
//                // Set the match count.
//                self.count = gameData.count
//
//                // Set the local player's items.
//                if let localParticipant = self.localParticipant {
//                    if let items = gameData.items[localParticipant.player.displayName] {
//                        self.localParticipant?.items = items
//                    }
//                }
//
//                // Set the opponent's items.
//                if let opponent = self.opponent {
//                    if let items = gameData.items[opponent.player.displayName] {
//                        self.opponent?.items = items
//                    }
//                }
//            }
//        }
    }

