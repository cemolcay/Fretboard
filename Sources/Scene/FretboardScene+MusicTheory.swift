//
//  FretboardScene+MusicTheory.swift
//  Fretboard
//
//  Created by Cem Olcay on 11/06/2026.
//

import MusicTheory

// MARK: - Scale / Chord convenience

/// Convenience methods that expand a `Scale` or `Chord` to concrete `Pitch` instances across the
/// visible octaves and forward them to `showPitches(_:style:)`.
///
/// These sit in a separate file so apps that do their own music-theory resolution can import only
/// the core API without this overhead.
public extension FretboardScene {

    /// Shows all notes of `scale` across every octave currently visible on the fretboard.
    ///
    /// Equivalent to:
    /// ```swift
    /// let pitches = scale.noteNames.flatMap { n in fretboard.octaves.map { Pitch(noteName: n, octave: $0) } }
    /// scene.showPitches(pitches, style: style)
    /// ```
    func showScale(_ scale: Scale, style: FretboardNoteStyle? = nil) {
        let pitches = scale.noteNames.flatMap { noteName in
            fretboard.octaves.map { Pitch(noteName: noteName, octave: $0) }
        }
        showPitches(pitches, style: style)
    }

    /// Shows all notes of `chord` across every octave currently visible on the fretboard.
    func showChord(_ chord: Chord, style: FretboardNoteStyle? = nil) {
        let pitches = chord.noteNames.flatMap { noteName in
            fretboard.octaves.map { Pitch(noteName: noteName, octave: $0) }
        }
        showPitches(pitches, style: style)
    }
}
