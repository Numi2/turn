/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
The multiplayer game view that uses GameKit for turn-based online matches.
*/

import SwiftUI

struct MultiPlayerView: View {
    @StateObject private var game = TurnBasedGame()
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            // Header
            HStack {
                Button("Back") {
                    presentationMode.wrappedValue.dismiss()
                }
                .padding(.leading)
                
                Spacer()
                
                Text("🎮 Multiplayer Mode")
                    .font(.headline)
                    .foregroundColor(.green)
                
                Spacer()
                
                // Placeholder for balance
                Text("")
                    .padding(.trailing)
            }
            .padding(.vertical)
            .background(Color(.systemGray6))
            
            // Display the game title.
            Text("Turn-Based Game")
                .font(.title)
            
            Form {
                Section("Manage Matches") {
                    // Add the start button to initiate a turn-based match.
                    Button("Start Match") {
                        game.startMatch()
                    }
                    .disabled(!game.matchAvailable)
                    
                    Button("Remove All Matches") {
                        Task {
                            await game.removeMatches()
                        }
                    }
                    .disabled(!game.matchAvailable)
                }
            }
        }
        // Authenticate the local player when the game first launches.
        .onAppear {
            if !game.playingGame {
                game.authenticatePlayer()
            }
        }
        // Display the game interface if a match is ongoing.
        .fullScreenCover(isPresented: $game.playingGame) {
            GameView(game: game)
        }
    }
}

struct MultiPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        MultiPlayerView()
    }
}