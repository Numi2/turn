//
//  HexCoordinate.swift
//  TurnBasedGameSample
//
//  Created for Hexagon Strategy Game
//

import Foundation
import CoreGraphics

/// Represents a position in a hexagonal grid using axial coordinates (q, r)
/// This system makes hexagon math much simpler than offset coordinates
struct HexCoordinate: Codable, Hashable, Equatable {
    let q: Int // Column (x-axis in hex space)
    let r: Int // Row (y-axis in hex space)
    
    init(q: Int, r: Int) {
        self.q = q
        self.r = r
    }
    
    /// The third coordinate (s) can be derived from q and r
    /// In cube coordinates: q + r + s = 0
    var s: Int {
        return -q - r
    }
    
    /// Convert hex coordinates to cube coordinates for easier calculations
    var cubeCoordinates: (x: Int, y: Int, z: Int) {
        return (x: q, y: -q - r, z: r)
    }
}

// MARK: - Hexagon Math Operations

extension HexCoordinate {
    
    /// Calculate the distance between two hex coordinates
    func distance(to other: HexCoordinate) -> Int {
        let cube1 = self.cubeCoordinates
        let cube2 = other.cubeCoordinates
        
        return (abs(cube1.x - cube2.x) + abs(cube1.y - cube2.y) + abs(cube1.z - cube2.z)) / 2
    }
    
    /// Get all neighboring hexagon coordinates
    var neighbors: [HexCoordinate] {
        let directions = [
            HexCoordinate(q: 1, r: 0),   // East
            HexCoordinate(q: 1, r: -1),  // Northeast
            HexCoordinate(q: 0, r: -1),  // Northwest
            HexCoordinate(q: -1, r: 0),  // West
            HexCoordinate(q: -1, r: 1),  // Southwest
            HexCoordinate(q: 0, r: 1)    // Southeast
        ]
        
        return directions.map { self + $0 }
    }
    
    /// Get neighbors within a specific range
    func neighbors(within range: Int) -> Set<HexCoordinate> {
        var result = Set<HexCoordinate>()
        
        for q in -range...range {
            let r1 = max(-range, -q - range)
            let r2 = min(range, -q + range)
            
            for r in r1...r2 {
                let coord = HexCoordinate(q: self.q + q, r: self.r + r)
                if coord != self { // Exclude self
                    result.insert(coord)
                }
            }
        }
        
        return result
    }
    
    /// Check if this coordinate is within the given range of another coordinate
    func isWithinRange(_ range: Int, of other: HexCoordinate) -> Bool {
        return distance(to: other) <= range
    }
}

// MARK: - Arithmetic Operations

extension HexCoordinate {
    static func + (lhs: HexCoordinate, rhs: HexCoordinate) -> HexCoordinate {
        return HexCoordinate(q: lhs.q + rhs.q, r: lhs.r + rhs.r)
    }
    
    static func - (lhs: HexCoordinate, rhs: HexCoordinate) -> HexCoordinate {
        return HexCoordinate(q: lhs.q - rhs.q, r: lhs.r - rhs.r)
    }
    
    static func * (lhs: HexCoordinate, rhs: Int) -> HexCoordinate {
        return HexCoordinate(q: lhs.q * rhs, r: lhs.r * rhs)
    }
}

// MARK: - Screen Coordinate Conversion

extension HexCoordinate {
    
    /// Convert hex coordinate to screen pixel position
    /// Using flat-top hexagon orientation
    func toPixel(hexSize: CGFloat) -> CGPoint {
        let x = hexSize * (3.0/2.0 * CGFloat(q))
        let y = hexSize * (sqrt(3.0)/2.0 * CGFloat(q) + sqrt(3.0) * CGFloat(r))
        return CGPoint(x: x, y: y)
    }
    
    /// Convert screen pixel position to hex coordinate
    /// Returns the closest hex coordinate to the given pixel
    static func fromPixel(point: CGPoint, hexSize: CGFloat) -> HexCoordinate {
        let q = (2.0/3.0 * point.x) / hexSize
        let r = (-1.0/3.0 * point.x + sqrt(3.0)/3.0 * point.y) / hexSize
        
        return hexRound(q: q, r: r)
    }
    
    /// Round fractional hex coordinates to the nearest integer hex coordinate
    private static func hexRound(q: CGFloat, r: CGFloat) -> HexCoordinate {
        let s = -q - r
        
        var rq = round(q)
        var rr = round(r)
        let rs = round(s)
        
        let qDiff = abs(rq - q)
        let rDiff = abs(rr - r)
        let sDiff = abs(rs - s)
        
        if qDiff > rDiff && qDiff > sDiff {
            rq = -rr - rs
        } else if rDiff > sDiff {
            rr = -rq - rs
        }
        
        return HexCoordinate(q: Int(rq), r: Int(rr))
    }
}

// MARK: - Map Generation Helpers

extension HexCoordinate {
    
    /// Generate all coordinates for a hexagonal map of given radius
    static func generateHexMap(radius: Int) -> Set<HexCoordinate> {
        var coordinates = Set<HexCoordinate>()
        
        for q in -radius...radius {
            let r1 = max(-radius, -q - radius)
            let r2 = min(radius, -q + radius)
            
            for r in r1...r2 {
                coordinates.insert(HexCoordinate(q: q, r: r))
            }
        }
        
        return coordinates
    }
    
    /// Generate coordinates for a rectangular hex map
    static func generateRectangleMap(width: Int, height: Int) -> Set<HexCoordinate> {
        var coordinates = Set<HexCoordinate>()
        
        for r in 0..<height {
            let rOffset = r >> 1 // floor(r/2)
            for q in -rOffset..<(width - rOffset) {
                coordinates.insert(HexCoordinate(q: q, r: r))
            }
        }
        
        return coordinates
    }
}

// MARK: - CustomStringConvertible

extension HexCoordinate: CustomStringConvertible {
    var description: String {
        return "(\(q), \(r))"
    }
}