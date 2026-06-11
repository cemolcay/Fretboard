//
//  Collection+Safe.swift
//  Fretboard
//
//  Created by Cem Olcay on 11/06/2026.
//

import Foundation

extension Collection where Indices.Iterator.Element == Index {
    /// Returns the element at the given index if it is within bounds, otherwise `nil`.
    subscript(safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
