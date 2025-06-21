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
            VStack(spacing: 10) {
                Text("⚔️ Hexagon Strategy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Turn-Based Strategy Game")
                    .font(.subtitle)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 50)
            
            Spacer()
            
            // Game mode buttons
            VStack(spacing: 20) {
                // Single Player Button
                Button(action: {
                    showSinglePlayer = true
                }) {
                    HStack {
                        Image(systemName: "person.fill")
                            .font(.title2)
                        Text("Single Player")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.gradient)
                    )
                    .foregroundColor(.white)
                }
                .shadow(radius: 5)
                
                // Multiplayer Button
                Button(action: {
                    showMultiplayer = true
                }) {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .font(.title2)
                        Text("Multiplayer")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.gradient)
                    )
                    .foregroundColor(.white)
                }
                .shadow(radius: 5)
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
                colors: [Color.blue.opacity(0.1), Color.green.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
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