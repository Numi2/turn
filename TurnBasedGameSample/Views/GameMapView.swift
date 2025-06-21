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
                    // Background
                    Color(.systemGray6)
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
        VStack(spacing: 8) {
            HStack {
                // Current player indicator
                Text("Turn: \(gameMap.currentPlayer == .player1 ? "Player 1" : "Player 2")")
                    .font(.headline)
                    .foregroundColor(gameMap.currentPlayer == .player1 ? .blue : .red)
                
                Spacer()
                
                // Turn number
                Text("Turn \(gameMap.turnNumber)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                // Current phase
                Text(gameMap.turnPhase.description)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
                
                Spacer()
                
                // Player resources
                HStack(spacing: 16) {
                    ResourceDisplay(
                        icon: "dollarsign.circle.fill",
                        value: gameMap.currentPlayer == .player1 ? gameMap.player1Gold : gameMap.player2Gold,
                        color: .yellow
                    )
                    
                    ResourceDisplay(
                        icon: "house.fill",
                        value: gameMap.currentPlayer == .player1 ? gameMap.player1Houses : gameMap.player2Houses,
                        color: .green
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Control Panel
    
    private var controlPanel: some View {
        VStack(spacing: 12) {
            // Selected unit info
            if let selectedUnit = gameMap.selectedUnit {
                selectedUnitInfo(selectedUnit)
            }
            
            // Action buttons
            HStack(spacing: 12) {
                // Move/Attack buttons
                if let selectedUnit = gameMap.selectedUnit {
                    Button("Move") {
                        gameMap.gameMode = .moveUnit
                        updateHighlights()
                    }
                    .disabled(!selectedUnit.canMove || gameMap.turnPhase != .move)
                    .buttonStyle(ActionButtonStyle(color: .blue))
                    
                    Button("Attack") {
                        gameMap.gameMode = .attackUnit
                        updateHighlights()
                    }
                    .disabled(!selectedUnit.canAttack || gameMap.turnPhase != .combat)
                    .buttonStyle(ActionButtonStyle(color: .red))
                }
                
                // Build button
                Button("Build") {
                    if selectedCoordinate != nil && gameMap.isEmpty(at: selectedCoordinate!) {
                        showBuildMenu = true
                    }
                }
                .disabled(gameMap.turnPhase != .build || selectedCoordinate == nil || !gameMap.isEmpty(at: selectedCoordinate!))
                .buttonStyle(ActionButtonStyle(color: .green))
                
                Spacer()
                
                // Next phase button
                Button("Next Phase") {
                    gameMap.nextPhase()
                    clearSelection()
                }
                .buttonStyle(ActionButtonStyle(color: .purple))
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Helper Views
    
    private func selectedUnitInfo(_ unit: GameUnit) -> some View {
        HStack {
            Text(unit.emoji)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(unit.displayName)
                    .font(.headline)
                
                HStack {
                    Text("HP: \(unit.currentHealth)/\(unit.maxHealth)")
                    if unit.attack > 0 {
                        Text("ATK: \(unit.attack)")
                    }
                    if unit.movementRange > 0 {
                        Text("MOV: \(unit.movementRange)")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Unit status indicators
            VStack(alignment: .trailing, spacing: 2) {
                if unit.hasMovedThisTurn {
                    Image(systemName: "figure.walk")
                        .foregroundColor(.orange)
                }
                if unit.hasAttackedThisTurn {
                    Image(systemName: "sword.fill")
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(unit.color.opacity(0.1))
        .cornerRadius(8)
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
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text("\(value)")
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}

struct ActionButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(configuration.isPressed ? 0.8 : 0.6))
            .foregroundColor(.white)
            .cornerRadius(6)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - Preview

struct GameMapView_Previews: PreviewProvider {
    static var previews: some View {
        GameMapView(gameMap: GameMap(radius: 4))
            .preferredColorScheme(.light)
    }
}