/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
Single player game controller that manages game state and AI opponent.
*/

import Foundation
import SwiftUI
import Combine

@MainActor
class SinglePlayerGame: ObservableObject {
    @Published var gameMap: GameMap = GameMap(radius: 4)
    @Published var gameEnded: Bool = false
    @Published var gameResultMessage: String = ""
    
    private let gameAI: GameAI
    private var aiTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.gameAI = GameAI(difficulty: .ultra, playerSide: .player2)
        setupGameMapObserver()
    }
    
    deinit {
        aiTask?.cancel()
        cancellables.removeAll()
    }
    
    /// Set up observer for game map changes
    private func setupGameMapObserver() {
        gameMap.objectWillChange
            .sink { [weak self] in
                Task { @MainActor in
                    await self?.handleGameStateChange()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Start a new single player game
    func startNewGame() {
        // Cancel any existing AI task
        aiTask?.cancel()
        
        // Reset game state
        gameMap = GameMap(radius: 4)
        gameEnded = false
        gameResultMessage = ""
        
        // Player 1 is human, Player 2 is AI
        gameMap.currentPlayer = .player1
        gameMap.turnPhase = .income
        
        // Clear old subscriptions and set up new ones
        cancellables.removeAll()
        setupGameMapObserver()
    }
    
    /// Handle game state changes and trigger AI when appropriate
    private func handleGameStateChange() async {
        // Check win condition
        if let winner = gameMap.checkWinCondition() {
            handleGameEnd(winner: winner)
            return
        }
        
        // Trigger AI move if it's AI's turn
        if gameMap.currentPlayer == .player2 && !gameEnded {
            // Cancel any existing AI task
            aiTask?.cancel()
            
            // Start new AI task
            aiTask = Task {
                await gameAI.makeMove(gameMap: gameMap)
            }
        }
    }
    
    /// Handle game end
    private func handleGameEnd(winner: PlayerSide) {
        aiTask?.cancel()
        
        switch winner {
        case .player1:
            gameResultMessage = "🎉 You Won!\nCongratulations! You defeated the Ultra AI!"
        case .player2:
            gameResultMessage = "💀 You Lost!\nThe Ultra AI was victorious. Try again!"
        }
        
        gameEnded = true
    }
}