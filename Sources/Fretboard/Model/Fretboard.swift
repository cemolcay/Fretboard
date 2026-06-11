//
//  Fretboard.swift
//  Fretboard
//
//  Created by Cem Olcay on 11/06/2026.
//

import MusicTheory

// MARK: - Fretboard

/// Represents the state of a fretboard: its tuning, visible fret range, direction, and selection.
///
/// `Fretboard` is a plain `Codable` class — the consuming app creates, reads, and writes it
/// directly, then passes it to `FretboardScene` (or calls `scene.reload()` after mutations).
/// No observation framework is used; the model is decoupled from any rendering.
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

    /// Whether chord mode is active: only the lowest selected fret per string is shown.
    public var isChordModeOn: Bool {
        didSet { updateNoteTypes() }
    }

    /// Whether capo-style bar rendering is used for consecutive selected notes on the same fret.
    public var isCapoOn: Bool {
        didSet { updateNoteTypes() }
    }

    /// The computed grid of all fret-note positions. Read-only; rebuilt whenever layout properties change.
    public private(set) var notes: [FretboardNote] = []

    // MARK: - Init

    public init(
        tuning: Tuning = GuitarTuning.standard,
        startIndex: Int = 0,
        count: Int = 5,
        direction: FretboardDirection = .horizontal,
        isChordModeOn: Bool = false,
        isCapoOn: Bool = true
    ) {
        self.tuning = tuning
        self.startIndex = max(0, startIndex)
        self.count = max(1, count)
        self.direction = direction
        self.isChordModeOn = isChordModeOn
        self.isCapoOn = isCapoOn
        rebuildNotes()
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case tuning, startIndex, count, direction, isChordModeOn, isCapoOn, notes
    }

    public required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        tuning = try c.decode(Tuning.self, forKey: .tuning)
        startIndex = try c.decode(Int.self, forKey: .startIndex)
        count = try c.decode(Int.self, forKey: .count)
        direction = try c.decode(FretboardDirection.self, forKey: .direction)
        isChordModeOn = try c.decodeIfPresent(Bool.self, forKey: .isChordModeOn) ?? false
        isCapoOn = try c.decodeIfPresent(Bool.self, forKey: .isCapoOn) ?? true
        notes = (try? c.decode([FretboardNote].self, forKey: .notes)) ?? []
        if notes.isEmpty { rebuildNotes() }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(tuning, forKey: .tuning)
        try c.encode(startIndex, forKey: .startIndex)
        try c.encode(count, forKey: .count)
        try c.encode(direction, forKey: .direction)
        try c.encode(isChordModeOn, forKey: .isChordModeOn)
        try c.encode(isCapoOn, forKey: .isCapoOn)
        try c.encode(notes, forKey: .notes)
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
        // Preserve existing selection state where pitch + position matches.
        let selectedMIDIs = Set(notes.filter { $0.isSelected }.map { "\($0.stringIndex)-\($0.fretIndex)" })
        for i in result.indices {
            if selectedMIDIs.contains("\(result[i].stringIndex)-\(result[i].fretIndex)") {
                result[i].isSelected = true
            }
        }
        notes = result
        updateNoteTypes()
    }

    // MARK: - Selection

    /// Selects all fret positions whose pitch enharmonically matches `pitch`.
    public func select(pitch: Pitch) {
        let midi = pitch.midiNoteNumber
        for i in notes.indices where notes[i].pitch.midiNoteNumber == midi {
            notes[i].isSelected = true
        }
        updateNoteTypes()
    }

    /// Selects all fret positions that enharmonically match any pitch in `pitches`.
    public func select(pitches: [Pitch]) {
        let midis = Set(pitches.map { $0.midiNoteNumber })
        for i in notes.indices where midis.contains(notes[i].pitch.midiNoteNumber) {
            notes[i].isSelected = true
        }
        updateNoteTypes()
    }

    /// Selects all fret positions whose pitch class (0–11) matches any note in `scale`.
    /// Uses pitch-class matching so the fretboard lights up regardless of octave or enharmonic spelling.
    public func select(scale: Scale) {
        let pitchClasses = Set(scale.noteNames.map { $0.pitchClass })
        for i in notes.indices where pitchClasses.contains(notes[i].pitch.noteName.pitchClass) {
            notes[i].isSelected = true
        }
        updateNoteTypes()
    }

    /// Selects all fret positions that match any note in `chord` across the visible octaves.
    /// Matches by pitch class so enharmonic spellings are handled correctly.
    public func select(chord: Chord) {
        let pitchClasses = Set(chord.noteNames.map { $0.pitchClass })
        for i in notes.indices where pitchClasses.contains(notes[i].pitch.noteName.pitchClass) {
            notes[i].isSelected = true
        }
        updateNoteTypes()
    }

    /// Deselects all fret positions whose pitch enharmonically matches `pitch`.
    public func deselect(pitch: Pitch) {
        let midi = pitch.midiNoteNumber
        for i in notes.indices where notes[i].pitch.midiNoteNumber == midi {
            notes[i].isSelected = false
        }
        updateNoteTypes()
    }

    /// Deselects all notes.
    public func deselectAll() {
        for i in notes.indices { notes[i].isSelected = false }
        updateNoteTypes()
    }

    // MARK: - Note Type (capo / chord mode)

    /// Recomputes `noteType` for every note based on current selection, `isCapoOn`, and `isChordModeOn`.
    public func updateNoteTypes() {
        guard !notes.isEmpty else { return }

        // Reset all to .none first.
        for i in notes.indices { notes[i].noteType = .none }

        for i in notes.indices {
            guard notes[i].isSelected else { continue }

            let fretIndex = notes[i].fretIndex
            let stringIndex = notes[i].stringIndex

            // Chord mode: suppress higher frets on the same string (keep only the lowest).
            if isChordModeOn {
                let selectedOnString = notes
                    .filter { $0.stringIndex == stringIndex && $0.isSelected }
                    .sorted { $0.fretIndex < $1.fretIndex }
                if selectedOnString.count > 1,
                   let first = selectedOnString.first,
                   first.id != notes[i].id {
                    // This is not the lowest; leave as .none (suppressed).
                    continue
                }
            }

            if isCapoOn {
                // Determine capo role by checking adjacent strings at the same fret.
                let sameFret = notes
                    .filter { $0.fretIndex == fretIndex }
                    .sorted { $0.stringIndex < $1.stringIndex }

                let prevSelected = sameFret[safe: stringIndex - 1]?.isSelected == true
                let nextSelected = sameFret[safe: stringIndex + 1]?.isSelected == true
                let prev2Selected = sameFret[safe: stringIndex - 2]?.isSelected == true
                let next2Selected = sameFret[safe: stringIndex + 2]?.isSelected == true

                if !prevSelected && nextSelected && next2Selected {
                    notes[i].noteType = .capoStart
                } else if !nextSelected && prevSelected && prev2Selected {
                    notes[i].noteType = .capoEnd
                } else if prevSelected && nextSelected {
                    notes[i].noteType = .capo
                } else {
                    notes[i].noteType = .default
                }
            } else {
                notes[i].noteType = .default
            }
        }
    }
}
