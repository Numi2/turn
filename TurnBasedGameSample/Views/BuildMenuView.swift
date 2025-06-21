//
//  BuildMenuView.swift
//  TurnBasedGameSample
//
//  Created for Hexagon Strategy Game
//

import SwiftUI

/// Build menu for purchasing and placing units
struct BuildMenuView: View {
    @ObservedObject var gameMap: GameMap
    let targetPosition: HexCoordinate
    @Binding var isPresented: Bool
    
    @State private var selectedUnitType: UnitType? = nil
    
    private let soldierTypes: [UnitType] = [.scout, .warrior, .knight, .champion]
    private let buildingTypes: [UnitType] = [.house, .watchtower, .fortress]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Enhanced Header
                buildMenuHeader
                
                // Unit categories
                ScrollView {
                    VStack(spacing: 24) {
                        // Soldiers section
                        unitSection(title: "⚔️ Soldiers", unitTypes: soldierTypes, color: .blue)
                        
                        // Buildings section
                        unitSection(title: "🏠 Buildings", unitTypes: buildingTypes, color: .green)
                    }
                    .padding(20)
                }
                
                // Enhanced build button
                buildButton
            }
            .navigationTitle("Build Units")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var buildMenuHeader: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Build Location")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Position: \(targetPosition.description)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.yellow)
                        .font(.title2)
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Gold")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(currentPlayerGold)")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.yellow.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            
            if !gameMap.isEmpty(at: targetPosition) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Position occupied - Cannot build here")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.1))
                )
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(.systemGray6), Color(.systemGray5)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Unit Sections
    
    private func unitSection(title: String, unitTypes: [UnitType], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(unitTypes, id: \.self) { unitType in
                    unitCard(for: unitType)
                }
            }
        }
    }
    
    private func unitCard(for unitType: UnitType) -> some View {
        let unit = GameUnit.create(type: unitType, owner: gameMap.currentPlayer, position: targetPosition)
        let cost = gameMap.getUnitCost(type: unitType, for: gameMap.currentPlayer)
        let canAfford = currentPlayerGold >= cost
        let isSelected = selectedUnitType == unitType
        
        return VStack(spacing: 8) {
            // Unit icon
            Text(unit.emoji)
                .font(.system(size: 40))
            
            // Unit name
            Text(unit.displayName)
                .font(.headline)
                .lineLimit(1)
            
            // Unit stats
            VStack(spacing: 2) {
                if unit.maxHealth > 0 {
                    statRow(icon: "heart.fill", value: "\(unit.maxHealth)", color: .red)
                }
                if unit.attack > 0 {
                    statRow(icon: "sword.fill", value: "\(unit.attack)", color: .orange)
                }
                if unit.movementRange > 0 {
                    statRow(icon: "figure.walk", value: "\(unit.movementRange)", color: .blue)
                }
                if unit.attackRange > 1 {
                    statRow(icon: "scope", value: "\(unit.attackRange)", color: .purple)
                }
            }
            
            // Cost
            HStack(spacing: 4) {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.yellow)
                Text("\(cost)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(canAfford ? .primary : .red)
            }
            
            // Special info for houses
            if unitType == .house {
                Text("+10 gold/turn")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 140)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? unit.color.opacity(0.3) : Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? unit.color : Color.clear, lineWidth: 2)
                )
        )
        .opacity(canAfford ? 1.0 : 0.6)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .onTapGesture {
            if canAfford {
                selectedUnitType = unitType
            }
        }
    }
    
    private func statRow(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            Text(value)
                .font(.caption2)
                .fontWeight(.medium)
        }
    }
    
    // MARK: - Build Button
    
    private var buildButton: some View {
        VStack(spacing: 12) {
            if let selectedType = selectedUnitType {
                let cost = gameMap.getUnitCost(type: selectedType, for: gameMap.currentPlayer)
                
                HStack {
                    HStack(spacing: 8) {
                        let unit = GameUnit.create(type: selectedType, owner: gameMap.currentPlayer, position: targetPosition)
                        Text(unit.emoji)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Build \(selectedType.rawValue.capitalized)")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text("Ready to construct")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.yellow)
                        Text("\(cost)")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.yellow.opacity(0.2))
                    )
                }
                .padding(.horizontal, 20)
            }
            
            Button(action: buildSelectedUnit) {
                HStack(spacing: 8) {
                    Image(systemName: canBuildSelectedUnit ? "hammer.fill" : "questionmark.circle")
                        .font(.headline)
                      
                    
                    Text(selectedUnitType != nil ? "Build Unit" : "Select a Unit to Build")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(canBuildSelectedUnit ? 
                              LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .top, endPoint: .bottom) :
                              LinearGradient(colors: [.gray.opacity(0.6), .gray.opacity(0.4)], startPoint: .top, endPoint: .bottom))
                        .shadow(color: canBuildSelectedUnit ? .blue.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
                )
                .scaleEffect(canBuildSelectedUnit ? 1.0 : 0.98)
                .animation(.easeInOut(duration: 0.2), value: canBuildSelectedUnit)
            }
            .disabled(!canBuildSelectedUnit)
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                colors: [Color(.systemGray6), Color(.systemGray5)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Computed Properties
    
    private var currentPlayerGold: Int {
        return gameMap.currentPlayer == .player1 ? gameMap.player1Gold : gameMap.player2Gold
    }
    
    private var canBuildSelectedUnit: Bool {
        guard let selectedType = selectedUnitType else { return false }
        return gameMap.canBuildUnit(type: selectedType, at: targetPosition, for: gameMap.currentPlayer)
    }
    
    // MARK: - Actions
    
    private func buildSelectedUnit() {
        guard let selectedType = selectedUnitType else { return }
        
        if gameMap.buildUnit(type: selectedType, at: targetPosition, for: gameMap.currentPlayer) {
            isPresented = false
        }
    }
}

// MARK: - Preview

struct BuildMenuView_Previews: PreviewProvider {
    @State static var isPresented = true
    
    static var previews: some View {
        BuildMenuView(
            gameMap: GameMap(radius: 4),
            targetPosition: HexCoordinate(q: 0, r: 0),
            isPresented: $isPresented
        )
    }
}
