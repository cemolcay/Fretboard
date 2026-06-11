//
//  FretboardNote.swift
//  Fretboard
//
//  Created by Cem Olcay on 11/06/2026.
//

import MusicTheory

/// A single fret-cell in the fretboard grid, carrying its pitch, position, and selection state.
public struct FretboardNote: Codable, Hashable, Identifiable {

    /// Unique identifier derived from position (stable across tuning for same fret/string).
    public var id: String { "\(stringIndex)-\(fretIndex)" }

    /// The sounding pitch at this position.
    public var pitch: Pitch

    /// 0-based column index in the fret direction (0 = open string or `startIndex`).
    public var fretIndex: Int

    /// 0-based row index (0 = lowest string in the tuning array).
    public var stringIndex: Int

    /// Whether this note is currently highlighted by a programmatic selection (scale, chord, etc.).
    public var isSelected: Bool = false

    /// The visual role this note plays when `isSelected` is true and capo rendering is enabled.
    public var noteType: FretNoteType = .none

    public init(pitch: Pitch, fretIndex: Int, stringIndex: Int) {
        self.pitch = pitch
        self.fretIndex = fretIndex
        self.stringIndex = stringIndex
    }
}

// MARK: - FretNoteType

/// Describes how a selected note should be drawn — as a standalone dot, or as part of a capo bar.
public enum FretNoteType: String, Codable, Hashable {
    /// An isolated selected note: draw as a filled circle.
    case `default`
    /// First note in a consecutive run across strings at the same fret: rounded cap + bar extending downward.
    case capoStart
    /// A middle note in a capo run: a plain bar.
    case capo
    /// Last note in a consecutive run: bar extending upward + rounded cap.
    case capoEnd
    /// Not selected; draw nothing.
    case none
}
