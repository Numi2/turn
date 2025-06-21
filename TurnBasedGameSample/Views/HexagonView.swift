//
//  HexagonView.swift
//  TurnBasedGameSample
//
//  Created for Hexagon Strategy Game
//

import SwiftUI

/// Represents a single hexagon tile on the game map
struct HexagonView: View {
    let coordinate: HexCoordinate
    let unit: GameUnit?
    let isSelected: Bool
    let isHighlighted: Bool
    let highlightColor: Color
    let size: CGFloat
    
    @Binding var selectedCoordinate: HexCoordinate?
    
    init(coordinate: HexCoordinate, 
         unit: GameUnit? = nil, 
         isSelected: Bool = false, 
         isHighlighted: Bool = false, 
         highlightColor: Color = .blue, 
         size: CGFloat = 40,
         selectedCoordinate: Binding<HexCoordinate?>) {
        self.coordinate = coordinate
        self.unit = unit
        self.isSelected = isSelected
        self.isHighlighted = isHighlighted
        self.highlightColor = highlightColor
        self.size = size
        self._selectedCoordinate = selectedCoordinate
    }
    
    var body: some View {
        ZStack {
            // Base hexagon shape
            HexagonShape()
                .fill(hexagonFillColor)
                .frame(width: size, height: size)
                .overlay(
                    HexagonShape()
                        .stroke(hexagonStrokeColor, style: StrokeStyle(lineWidth: strokeWidth))
                )
            
            // Unit display
            if let unit = unit {
                VStack(spacing: 2) {
                    // Unit emoji
                    Text(unit.emoji)
                        .font(.system(size: size * 0.4))
                        .scaleEffect(unit.isAlive ? 1.0 : 0.7)
                        .opacity(unit.isAlive ? 1.0 : 0.5)
                    
                    // Health bar for damaged units
                    if !unit.isFullHealth && unit.isAlive {
                        HealthBarView(
                            current: unit.currentHealth, 
                            maximum: unit.maxHealth, 
                            width: size * 0.6,
                            height: 3
                        )
                    }
                }
            }
            
            // Coordinate display (for debugging - can be removed)
            if unit == nil {
                Text("\(coordinate.q),\(coordinate.r)")
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
                    .opacity(0.3)
            }
            
            // Selection indicator
            if isSelected {
                HexagonShape()
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 3))
                    .frame(width: size * 1.1, height: size * 1.1)
                    .shadow(color: .white, radius: 2)
            }
            
            // Highlight overlay
            if isHighlighted {
                HexagonShape()
                    .fill(highlightColor.opacity(0.3))
                    .frame(width: size, height: size)
                    .overlay(
                        HexagonShape()
                            .stroke(highlightColor, style: StrokeStyle(lineWidth: 2))
                            .frame(width: size, height: size)
                    )
            }
        }
        .onTapGesture {
            selectedCoordinate = coordinate
        }
    }
    
    // MARK: - Computed Properties
    
    private var hexagonFillColor: Color {
        if let unit = unit {
            return unit.color.opacity(0.3)
        } else if isHighlighted {
            return highlightColor.opacity(0.2)
        } else {
            return Color(.systemGray6)
        }
    }
    
    private var hexagonStrokeColor: Color {
        if isSelected {
            return .white
        } else if let unit = unit {
            return unit.color
        } else if isHighlighted {
            return highlightColor
        } else {
            return Color(.systemGray4)
        }
    }
    
    private var strokeWidth: CGFloat {
        if isSelected {
            return 3
        } else if unit != nil || isHighlighted {
            return 2
        } else {
            return 1
        }
    }
}

/// Custom hexagon shape for SwiftUI
struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        var path = Path()
        
        // Create hexagon with flat top orientation
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.closeSubpath()
        return path
    }
}

/// Health bar view for units
struct HealthBarView: View {
    let current: Int
    let maximum: Int
    let width: CGFloat
    let height: CGFloat
    
    private var healthPercentage: Double {
        return Double(current) / Double(maximum)
    }
    
    private var healthColor: Color {
        switch healthPercentage {
        case 0.7...1.0:
            return .green
        case 0.3..<0.7:
            return .yellow
        default:
            return .red
        }
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Background
            Rectangle()
                .fill(Color.black.opacity(0.3))
                .frame(width: width, height: height)
                .cornerRadius(height / 2)
            
            // Health fill
            Rectangle()
                .fill(healthColor)
                .frame(width: width * healthPercentage, height: height)
                .cornerRadius(height / 2)
        }
    }
}

// MARK: - Preview

struct HexagonView_Previews: PreviewProvider {
    @State static var selectedCoord: HexCoordinate? = nil
    
    static var previews: some View {
        VStack(spacing: 20) {
            HStack(spacing: 10) {
                // Empty hexagon
                HexagonView(
                    coordinate: HexCoordinate(q: 0, r: 0),
                    selectedCoordinate: $selectedCoord
                )
                
                // Hexagon with unit
                HexagonView(
                    coordinate: HexCoordinate(q: 1, r: 0),
                    unit: GameUnit.create(type: .scout, owner: .player1, position: HexCoordinate(q: 1, r: 0)),
                    selectedCoordinate: $selectedCoord
                )
                
                // Selected hexagon
                HexagonView(
                    coordinate: HexCoordinate(q: 2, r: 0),
                    unit: GameUnit.create(type: .warrior, owner: .player2, position: HexCoordinate(q: 2, r: 0)),
                    isSelected: true,
                    selectedCoordinate: $selectedCoord
                )
                
                // Highlighted hexagon
                HexagonView(
                    coordinate: HexCoordinate(q: 3, r: 0),
                    isHighlighted: true,
                    highlightColor: .green,
                    selectedCoordinate: $selectedCoord
                )
            }
            
            HStack(spacing: 10) {
                // Damaged unit
                let damagedUnit = GameUnit.create(type: .knight, owner: .player1, position: HexCoordinate(q: 0, r: 1))
                let _ = { damagedUnit.takeDamage(30) }() // Take some damage
                
                HexagonView(
                    coordinate: HexCoordinate(q: 0, r: 1),
                    unit: damagedUnit,
                    selectedCoordinate: $selectedCoord
                )
                
                // Tower
                HexagonView(
                    coordinate: HexCoordinate(q: 1, r: 1),
                    unit: GameUnit.create(type: .watchtower, owner: .player1, position: HexCoordinate(q: 1, r: 1)),
                    selectedCoordinate: $selectedCoord
                )
                
                // House
                HexagonView(
                    coordinate: HexCoordinate(q: 2, r: 1),
                    unit: GameUnit.create(type: .house, owner: .player2, position: HexCoordinate(q: 2, r: 1)),
                    selectedCoordinate: $selectedCoord
                )
                
                // Champion
                HexagonView(
                    coordinate: HexCoordinate(q: 3, r: 1),
                    unit: GameUnit.create(type: .champion, owner: .player1, position: HexCoordinate(q: 3, r: 1)),
                    selectedCoordinate: $selectedCoord
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}
