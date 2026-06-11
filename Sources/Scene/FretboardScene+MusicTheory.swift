//
//  FretboardScene+MusicTheory.swift
//  Fretboard
//
//  Created by Cem Olcay on 11/06/2026.
//

import MusicTheory

// MARK: - Scale / Chord convenience

/// Convenience methods that expand a `Scale` or `Chord` to concrete `Pitch` instances across the
/// visible octaves and forward them to the core `showNotes(_:)` API.
///
/// These sit in a separate file so apps that do their own music-theory resolution can import only
/// the core API without this overhead.
public extension FretboardScene {

    /// Shows all notes of `scale` across every octave currently visible on the fretboard.
    ///
    /// Equivalent to resolving `scale` to pitches yourself and calling `showNotes(_:)`.
    func show(scale: Scale) {
        let pitches = scale.noteNames.flatMap { noteName in
            fretboard.octaves.map { Pitch(noteName: noteName, octave: $0) }
        }
        showNotes(pitches)
    }

    /// Shows all notes of `chord` across every octave currently visible on the fretboard.
    func show(chord: Chord) {
        let pitches = chord.noteNames.flatMap { noteName in
            fretboard.octaves.map { Pitch(noteName: noteName, octave: $0) }
        }
        showNotes(pitches)
    }
}
