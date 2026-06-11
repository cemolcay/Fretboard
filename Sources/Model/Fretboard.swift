//
//  Fretboard.swift
//  Fretboard
//
//  Created by Cem Olcay on 11/06/2026.
//

import MusicTheory

// MARK: - Fretboard

/// Represents the geometry of a fretboard: its tuning, visible fret range, and direction.
///
/// `Fretboard` is a plain `Codable` value — the consuming app creates, reads, and writes it
/// directly, then passes it to `FretboardScene` (or calls `scene.reload()` after mutations).
/// No observation framework is used; the model is fully decoupled from rendering.
///
/// All selection and visual state (which dots are shown, highlight, capo mode) is owned
/// by `FretboardScene`, not by this model.
public final class Fretboard: Codable {

    // MARK: - Stored Properties

    /// Open-string pitches defining the instrument. Defaults to standard guitar.
    public var tuning: Tuning {
        didSet { rebuildNotes() }
    }

    /// The first fret to display. 0 means open strings are shown. Minimum 0.
    public var startIndex: Int {
        didSet {
            if startIndex < 0 { startIndex = 0 }
            rebuildNotes()
        }
    }

    /// Number of frets to display. Minimum 1.
    public var count: Int {
        didSet {
            if count < 1 { count = 1 }
            rebuildNotes()
        }
    }

    /// Whether strings are laid out horizontally or vertically.
    public var direction: FretboardDirection {
        didSet { rebuildNotes() }
    }

    /// The computed grid of all fret-note positions. Read-only; rebuilt whenever layout properties change.
    public private(set) var notes: [FretboardNote] = []

    // MARK: - Init

    public init(
        tuning: Tuning = GuitarTuning.standard,
        startIndex: Int = 0,
        count: Int = 5,
        direction: FretboardDirection = .horizontal
    ) {
        self.tuning = tuning
        self.startIndex = max(0, startIndex)
        self.count = max(1, count)
        self.direction = direction
        rebuildNotes()
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case tuning, startIndex, count, direction
    }

    public required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        tuning = try c.decode(Tuning.self, forKey: .tuning)
        startIndex = try c.decode(Int.self, forKey: .startIndex)
        count = try c.decode(Int.self, forKey: .count)
        direction = try c.decode(FretboardDirection.self, forKey: .direction)
        rebuildNotes()
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(tuning, forKey: .tuning)
        try c.encode(startIndex, forKey: .startIndex)
        try c.encode(count, forKey: .count)
        try c.encode(direction, forKey: .direction)
    }

    // MARK: - Note Grid

    /// Strings ordered for display: horizontal = low→high bottom-to-top (reversed), vertical = top-to-bottom.
    public var orderedStrings: [Pitch] {
        direction == .horizontal ? tuning.strings.reversed() : tuning.strings
    }

    /// All octaves currently visible on the fretboard, sorted ascending.
    public var octaves: [Int] {
        Array(Set(notes.map { $0.pitch.octave })).sorted()
    }

    private func rebuildNotes() {
        var result: [FretboardNote] = []
        for (stringIndex, openPitch) in orderedStrings.enumerated() {
            for fretOffset in 0..<count {
                let fretNumber = startIndex + fretOffset
                let pitch = openPitch + fretNumber   // Pitch + Int = semitone shift
                result.append(FretboardNote(
                    pitch: pitch,
                    fretIndex: fretOffset,
                    stringIndex: stringIndex))
            }
        }
        notes = result
    }

    // MARK: - Pitch Lookup

    /// Returns all grid positions whose pitch matches `pitch` by MIDI note number (enharmonic-insensitive).
    ///
    /// Used by `FretboardScene` to resolve a pitch to one or more board positions for dot placement.
    /// A single MIDI pitch may appear on multiple strings (e.g. the same note reachable two ways).
    public func notes(matching pitch: Pitch) -> [FretboardNote] {
        let midi = pitch.midiNoteNumber
        return notes.filter { $0.pitch.midiNoteNumber == midi }
    }
}
