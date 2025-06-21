//
//  GameMapView.swift
//  TurnBasedGameSample
//
//  Created for Hexagon Strategy Game
//

import SwiftUI

/// Main view that displays the hexagonal game map
struct GameMapView: View {
    @ObservedObject var gameMap: GameMap
    @State private var selectedCoordinate: HexCoordinate? = nil
    @State private var showBuildMenu: Bool = false
    
    private let hexSize: CGFloat = 50
    private let hexSpacing: CGFloat = 45
    
    var body: some View {
        VStack(spacing: 0) {
            // Game status bar
            gameStatusBar
            
            // Map display
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                ZStack {
                    // Enhanced background with subtle pattern
                    LinearGradient(
                        colors: [Color(.systemGray6), Color(.systemGray5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    // Hexagon map
                    LazyVStack(spacing: -hexSpacing * 0.25) {
                        ForEach(sortedRows, id: \.self) { row in
                            hexagonRow(for: row)
                        }
                    }
                    .padding(hexSize)
                }
                .frame(minWidth: mapWidth, minHeight: mapHeight)
            }
            .clipped()
            .background(
                LinearGradient(
                    colors: [Color(.systemGray6), Color(.systemGray5)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Control panel
            controlPanel
        }
        .onReceive(gameMap.$selectedUnit) { unit in
            if let unit = unit {
                selectedCoordinate = unit.position
                updateHighlights()
            }
        }
        .onChange(of: selectedCoordinate) { _ in
            handleHexagonSelection()
        }
        .sheet(isPresented: $showBuildMenu) {
            BuildMenuView(
                gameMap: gameMap,
                targetPosition: selectedCoordinate ?? HexCoordinate(q: 0, r: 0),
                isPresented: $showBuildMenu
            )
        }
    }
    
    // MARK: - Game Status Bar
    
    private var gameStatusBar: some View {
        VStack(spacing: 12) {
            HStack {
                // Current player indicator with enhanced styling
                HStack(spacing: 8) {
                    Circle()
                        .fill(gameMap.currentPlayer == .player1 ? .blue : .red)
                        .frame(width: 12, height: 12)
                    
                    Text("Turn: \(gameMap.currentPlayer == .player1 ? "Player 1" : "Player 2")")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(gameMap.currentPlayer == .player1 ? .blue : .red)
                }
                
                Spacer()
                
                // Turn number with badge style
                Text("Turn \(gameMap.turnNumber)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(12)
            }
            
            HStack {
                // Current phase with modern styling
                Text(gameMap.turnPhase.description)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(LinearGradient(
                                colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                    )
                    .foregroundColor(.white)
                
                Spacer()
                
                // Enhanced player resources
                HStack(spacing: 20) {
                    ResourceDisplay(
                        icon: "dollarsign.circle.fill",
                        value: gameMap.currentPlayer == .player1 ? gameMap.player1Gold : gameMap.player2Gold,
                        color: .yellow,
                        label: "Gold"
                    )
                    
                    ResourceDisplay(
                        icon: "house.fill",
                        value: gameMap.currentPlayer == .player1 ? gameMap.player1Houses : gameMap.player2Houses,
                        color: .green,
                        label: "Houses"
                    )
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color(.systemGray6), Color(.systemGray5)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Control Panel
    
    private var controlPanel: some View {
        VStack(spacing: 16) {
            // Selected unit info with enhanced styling
            if let selectedUnit = gameMap.selectedUnit {
                selectedUnitInfo(selectedUnit)
            }
            
            // Modern action buttons
            HStack(spacing: 12) {
                // Move/Attack buttons
                if let selectedUnit = gameMap.selectedUnit {
                    Button {
                        gameMap.gameMode = .moveUnit
                        updateHighlights()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "figure.walk")
                                .font(.headline)
                            Text("Move")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedUnit.canMove && gameMap.turnPhase == .move ? 
                                      LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .top, endPoint: .bottom) :
                                      LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.2)], startPoint: .top, endPoint: .bottom))
                        )
                        .foregroundColor(selectedUnit.canMove && gameMap.turnPhase == .move ? .white : .gray)
                    }
                    .disabled(!selectedUnit.canMove || gameMap.turnPhase != .move)
                    
                    Button {
                        gameMap.gameMode = .attackUnit
                        updateHighlights()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "sword.fill")
                                .font(.headline)
                            Text("Attack")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedUnit.canAttack && gameMap.turnPhase == .combat ? 
                                      LinearGradient(colors: [.red, .red.opacity(0.8)], startPoint: .top, endPoint: .bottom) :
                                      LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.2)], startPoint: .top, endPoint: .bottom))
                        )
                        .foregroundColor(selectedUnit.canAttack && gameMap.turnPhase == .combat ? .white : .gray)
                    }
                    .disabled(!selectedUnit.canAttack || gameMap.turnPhase != .combat)
                }
                
                // Build button
                Button {
                    if selectedCoordinate != nil && gameMap.isEmpty(at: selectedCoordinate!) {
                        showBuildMenu = true
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "hammer.fill")
                            .font(.headline)
                        Text("Build")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(gameMap.turnPhase == .build && selectedCoordinate != nil && gameMap.isEmpty(at: selectedCoordinate!) ? 
                                  LinearGradient(colors: [.green, .green.opacity(0.8)], startPoint: .top, endPoint: .bottom) :
                                  LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.2)], startPoint: .top, endPoint: .bottom))
                    )
                    .foregroundColor(gameMap.turnPhase == .build && selectedCoordinate != nil && gameMap.isEmpty(at: selectedCoordinate!) ? .white : .gray)
                }
                .disabled(gameMap.turnPhase != .build || selectedCoordinate == nil || !gameMap.isEmpty(at: selectedCoordinate!))
                
                // Next phase button
                Button {
                    gameMap.nextPhase()
                    clearSelection()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.headline)
                        Text("Next Phase")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(colors: [.purple, .purple.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                    )
                    .foregroundColor(.white)
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color(.systemGray6), Color(.systemGray5)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Helper Views
    
    private func selectedUnitInfo(_ unit: GameUnit) -> some View {
        HStack(spacing: 12) {
            // Unit icon with background
            ZStack {
                Circle()
                    .fill(unit.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Text(unit.emoji)
                    .font(.title)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(unit.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 12) {
                    // Health bar
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Health")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            ProgressView(value: Double(unit.currentHealth), total: Double(unit.maxHealth))
                                .progressViewStyle(LinearProgressViewStyle(tint: .red))
                                .frame(width: 60)
                            
                            Text("\(unit.currentHealth)/\(unit.maxHealth)")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                    
                    if unit.attack > 0 {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Attack")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 2) {
                                Image(systemName: "sword.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Text("\(unit.attack)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    
                    if unit.movementRange > 0 {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Movement")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 2) {
                                Image(systemName: "figure.walk")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Text("\(unit.movementRange)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            // Unit status indicators with better styling
            VStack(alignment: .trailing, spacing: 6) {
                if unit.hasMovedThisTurn {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("Moved")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                if unit.hasAttackedThisTurn {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                        Text("Attacked")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(unit.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(unit.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Map Layout
    
    private var sortedRows: [Int] {
        let allCoordinates = Array(gameMap.validPositions)
        let uniqueRows = Set(allCoordinates.map { $0.r })
        return uniqueRows.sorted()
    }
    
    private func hexagonRow(for row: Int) -> some View {
        let coordinatesInRow = gameMap.validPositions.filter { $0.r == row }.sorted { $0.q < $1.q }
        let rowOffset = CGFloat(row) * hexSpacing * 0.5
        
        return HStack(spacing: -hexSpacing * 0.25) {
            ForEach(coordinatesInRow, id: \.self) { coordinate in
                hexagonView(for: coordinate)
            }
        }
        .offset(x: rowOffset)
    }
    
    private func hexagonView(for coordinate: HexCoordinate) -> some View {
        let unit = gameMap.unit(at: coordinate)
        let isSelected = selectedCoordinate == coordinate
        let isHighlighted = gameMap.highlightedPositions.contains(coordinate)
        let highlightColor = getHighlightColor(for: coordinate)
        
        return HexagonView(
            coordinate: coordinate,
            unit: unit,
            isSelected: isSelected,
            isHighlighted: isHighlighted,
            highlightColor: highlightColor,
            size: hexSize,
            selectedCoordinate: $selectedCoordinate
        )
    }
    
    // MARK: - Computed Properties
    
    private var mapWidth: CGFloat {
        return CGFloat(gameMap.mapRadius * 2 + 1) * hexSpacing * 1.5
    }
    
    private var mapHeight: CGFloat {
        return CGFloat(gameMap.mapRadius * 2 + 1) * hexSpacing * 1.2
    }
    
    // MARK: - Game Logic
    
    private func handleHexagonSelection() {
        guard let coordinate = selectedCoordinate else {
            clearSelection()
            return
        }
        
        switch gameMap.gameMode {
        case .selectUnit:
            handleUnitSelection(at: coordinate)
            
        case .moveUnit:
            handleMoveAction(to: coordinate)
            
        case .attackUnit:
            handleAttackAction(at: coordinate)
            
        case .buildUnit:
            // Building is handled by the build menu
            break
        }
    }
    
    private func handleUnitSelection(at coordinate: HexCoordinate) {
        if let unit = gameMap.unit(at: coordinate),
           unit.owner == gameMap.currentPlayer {
            gameMap.selectedUnit = unit
            updateHighlights()
        } else {
            clearSelection()
        }
    }
    
    private func handleMoveAction(to coordinate: HexCoordinate) {
        guard let selectedUnit = gameMap.selectedUnit else { return }
        
        if gameMap.moveUnit(from: selectedUnit.position, to: coordinate) {
            gameMap.selectedUnit = gameMap.unit(at: coordinate) // Update to moved unit
            gameMap.gameMode = .selectUnit
            updateHighlights()
        }
    }
    
    private func handleAttackAction(at coordinate: HexCoordinate) {
        guard let selectedUnit = gameMap.selectedUnit else { return }
        
        if gameMap.attackUnit(attacker: selectedUnit.position, target: coordinate) {
            gameMap.gameMode = .selectUnit
            updateHighlights()
        }
    }
    
    private func updateHighlights() {
        guard let selectedUnit = gameMap.selectedUnit else {
            gameMap.highlightedPositions = []
            return
        }
        
        switch gameMap.gameMode {
        case .selectUnit:
            gameMap.highlightedPositions = []
            
        case .moveUnit:
            gameMap.highlightedPositions = selectedUnit.possibleMoves(on: gameMap)
            
        case .attackUnit:
            gameMap.highlightedPositions = selectedUnit.possibleTargets(on: gameMap)
            
        case .buildUnit:
            gameMap.highlightedPositions = []
        }
    }
    
    private func getHighlightColor(for coordinate: HexCoordinate) -> Color {
        switch gameMap.gameMode {
        case .moveUnit:
            return .blue
        case .attackUnit:
            return .red
        case .buildUnit:
            return .green
        default:
            return .blue
        }
    }
    
    private func clearSelection() {
        gameMap.selectedUnit = nil
        gameMap.highlightedPositions = []
        gameMap.gameMode = .selectUnit
        selectedCoordinate = nil
    }
}

// MARK: - Supporting Views

struct ResourceDisplay: View {
    let icon: String
    let value: Int
    let color: Color
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text("\(value)")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}



// MARK: - Preview

struct GameMapView_Previews: PreviewProvider {
    static var previews: some View {
        GameMapView(gameMap: GameMap(radius: 4))
            .preferredColorScheme(.light)
    }
}