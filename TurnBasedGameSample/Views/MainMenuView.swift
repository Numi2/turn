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
                ResponsiveButton(
                    title: "Single Player",
                    icon: "person.fill",
                    color: .blue
                ) {
                    showSinglePlayer = true
                }
                
                // Multiplayer Button
                ResponsiveButton(
                    title: "Multiplayer", 
                    icon: "person.2.fill",
                    color: .green
                ) {
                    showMultiplayer = true
                }
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

struct ResponsiveButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            action()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(isPressed ? 0.8 : 1.0),
                                color.opacity(isPressed ? 0.6 : 0.8)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: color.opacity(0.4), radius: isPressed ? 2 : 8, x: 0, y: isPressed ? 2 : 4)
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}
