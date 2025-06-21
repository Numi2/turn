/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
The main menu view that allows users to choose between single player and multiplayer modes.
*/

import SwiftUI

struct MainMenuView: View {
    @State private var showSinglePlayer = false
    @State private var showMultiplayer = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Game title
            VStack {
                Text("⚔️ Hexagon Strategy")
                    .font(.largeTitle.bold())
                Text("Turn-Based Strategy Game")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 50)
            
            Spacer()
            
            // Game mode buttons
            VStack(spacing: 20) {
                // Single Player Button
                Button {
                    showSinglePlayer = true
                } label: {
                    Label("Single Player", systemImage: "person.fill")
                        .font(.title2)
                      
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .controlSize(.large)
                
                // Multiplayer Button
                Button {
                    showMultiplayer = true
                } label: {
                    Label("Multiplayer", systemImage: "person.2.fill")
                        .font(.title2)
                     
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .controlSize(.large)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Game info
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                    Text("Single Player: AI Ultra Difficulty")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "gamecontroller.fill")
                        .foregroundColor(.blue)
                    Text("Multiplayer: GameKit Turn-Based")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 30)
        }
        .background(
            LinearGradient(
                colors: [Color(white: 0.95), Color(white: 1.0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .fullScreenCover(isPresented: $showSinglePlayer) {
            SinglePlayerView()
        }
        .fullScreenCover(isPresented: $showMultiplayer) {
            MultiPlayerView()
        }
    }
}

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView()
    }
}
