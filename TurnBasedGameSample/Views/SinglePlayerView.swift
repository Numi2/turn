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
            // Header
            HStack {
                Button("Back") {
                    presentationMode.wrappedValue.dismiss()
                }
                .padding(.leading)
                
                Spacer()
                
                VStack {
                    Text("🤖 AI Ultra Difficulty")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text("Turn \(singlePlayerGame.gameMap.turnNumber)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("New Game") {
                    singlePlayerGame.startNewGame()
                }
                .padding(.trailing)
            }
            .padding(.vertical)
            .background(Color(.systemGray6))
            
            // Game interface
            GameMapView(gameMap: singlePlayerGame.gameMap)
        }
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