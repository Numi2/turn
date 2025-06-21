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
                // Header
                buildMenuHeader
                
                // Unit categories
                ScrollView {
                    VStack(spacing: 20) {
                        // Soldiers section
                        unitSection(title: "Soldiers", unitTypes: soldierTypes, color: .blue)
                        
                        // Buildings section
                        unitSection(title: "Buildings", unitTypes: buildingTypes, color: .green)
                    }
                    .padding()
                }
                
                // Build button
                buildButton
            }
            .navigationTitle("Build Units")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var buildMenuHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Position: \(targetPosition.description)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.yellow)
                    Text("\(currentPlayerGold)")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            
            if !gameMap.isEmpty(at: targetPosition) {
                Text("⚠️ Position occupied")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
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
        VStack(spacing: 8) {
            if let selectedType = selectedUnitType {
                let cost = gameMap.getUnitCost(type: selectedType, for: gameMap.currentPlayer)
                
                HStack {
                    Text("Build \(selectedType.rawValue.capitalized)")
                        .font(.headline)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.yellow)
                        Text("\(cost)")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal)
            }
            
            Button(action: buildSelectedUnit) {
                Text(selectedUnitType != nil ? "Build Unit" : "Select a Unit")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(canBuildSelectedUnit ? .blue : .gray)
                    )
            }
            .disabled(!canBuildSelectedUnit)
            .padding()
        }
        .background(Color(.systemGray6))
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