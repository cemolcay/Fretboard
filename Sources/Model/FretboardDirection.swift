//
//  FretboardDirection.swift
//  Fretboard
//
//  Created by Cem Olcay on 11/06/2026.
//

import Foundation

/// The orientation of the fretboard rendering.
public enum FretboardDirection: String, Codable, Hashable, CaseIterable {
    /// Strings run left-to-right; frets advance from left to right.
    case horizontal
    /// Strings run top-to-bottom; frets advance from top to bottom.
    case vertical
}
