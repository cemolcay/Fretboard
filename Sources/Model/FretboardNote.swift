//
//  FretboardNote.swift
//  Fretboard
//
//  Created by Cem Olcay on 11/06/2026.
//

import MusicTheory

/// A single fret-cell in the fretboard grid, carrying its pitch and position.
///
/// `FretboardNote` is pure data — it carries no selection or visual state.
/// All rendering decisions (which dots to show, highlight state, capo mode)
/// are owned by `FretboardScene`.
public struct FretboardNote: Codable, Hashable, Identifiable {

    /// Unique identifier derived from position (stable across tuning changes for the same fret/string).
    public var id: String { "\(stringIndex)-\(fretIndex)" }

    /// The sounding pitch at this position.
    public var pitch: Pitch

    /// 0-based column index in the fret direction (0 = open string or `startIndex`).
    public var fretIndex: Int

    /// 0-based row index (0 = lowest string in the `orderedStrings` array).
    public var stringIndex: Int

    public init(pitch: Pitch, fretIndex: Int, stringIndex: Int) {
        self.pitch = pitch
        self.fretIndex = fretIndex
        self.stringIndex = stringIndex
    }
}
