/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
The single player game view that displays the AI vs Human gameplay.
*/

import SwiftUI

struct SinglePlayerView: View {
    @StateObject private var singlePlayerGame = SinglePlayerGame()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            // Enhanced Header
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.red.opacity(0.8), Color.red.opacity(0.6)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .ignoresSafeArea(edges: .top)
                
                VStack(spacing: 8) {
                    HStack {
                        Button {
                            // Add haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                    .font(.headline)
                                Text("Back")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Button {
                            // Add haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            singlePlayerGame.startNewGame()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.headline)
                                Text("New Game")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // AI Challenge Title
                    VStack(spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: "brain.head.profile")
                                .font(.title2)
                                .foregroundColor(.white)
                            
                            Text("AI Ultra Difficulty")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        Text("Turn \(singlePlayerGame.gameMap.turnNumber)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(.vertical, 12)
            }
            .frame(height: 120)
            
            // Game interface
            GameMapView(gameMap: singlePlayerGame.gameMap)
        }
        .navigationBarHidden(true)
        .onAppear {
            singlePlayerGame.startNewGame()
        }
        .alert("Game Over", isPresented: $singlePlayerGame.gameEnded, actions: {
            Button("New Game") {
                singlePlayerGame.startNewGame()
            }
            Button("Back to Menu") {
                presentationMode.wrappedValue.dismiss()
            }
        }, message: {
            Text(singlePlayerGame.gameResultMessage)
        })
    }
}

struct SinglePlayerView_Previews: PreviewProvider {
    static var previews: some View {
        SinglePlayerView()
    }
}