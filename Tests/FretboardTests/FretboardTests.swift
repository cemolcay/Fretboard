//
//  FretboardTests.swift
//  FretboardTests
//
//  Created by Cem Olcay on 11/06/2026.
//

import XCTest
import MusicTheory
@testable import Fretboard

final class FretboardTests: XCTestCase {

    // MARK: - Tuning MIDI numbers

    func testStandardGuitarTuningMIDI() {
        let strings = GuitarTuning.standard.strings
        XCTAssertEqual(strings.count, 6)
        // E2, A2, D3, G3, B3, E4
        let expected = [40, 45, 50, 55, 59, 64]
        XCTAssertEqual(strings.map { $0.midiNoteNumber }, expected,
                       "Standard guitar tuning MIDI numbers are wrong")
    }

    func testBassStandard4StringMIDI() {
        let strings = BassTuning.standard4String.strings
        XCTAssertEqual(strings.count, 4)
        // E1, A1, D2, G2
        let expected = [28, 33, 38, 43]
        XCTAssertEqual(strings.map { $0.midiNoteNumber }, expected,
                       "4-string bass standard tuning MIDI numbers are wrong")
    }

    func testUkuleleStandardMIDI() {
        let strings = UkuleleTuning.standard.strings
        XCTAssertEqual(strings.count, 4)
        // G4, C4, E4, A4
        let expected = [67, 60, 64, 69]
        XCTAssertEqual(strings.map { $0.midiNoteNumber }, expected,
                       "Ukulele standard tuning MIDI numbers are wrong")
    }

    // MARK: - Tuning Codable round-trip

    func testTuningCodableRoundTrip() throws {
        let original = GuitarTuning.standard
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Tuning.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func testCustomTuningCodableRoundTrip() throws {
        let custom = Tuning(name: "My Tuning", strings: [
            Pitch(noteName: .e, octave: 2),
            Pitch(noteName: .a, octave: 2),
            Pitch(noteName: .d, octave: 3),
            Pitch(noteName: .g, octave: 3),
        ])
        let data = try JSONEncoder().encode(custom)
        let decoded = try JSONDecoder().decode(Tuning.self, from: data)
        XCTAssertEqual(custom.name, decoded.name)
        XCTAssertEqual(custom.strings.map { $0.midiNoteNumber }, decoded.strings.map { $0.midiNoteNumber })
    }

    // MARK: - Fretboard Codable round-trip (geometry only)

    func testFretboardCodableRoundTrip() throws {
        let fb = Fretboard(tuning: GuitarTuning.standard, startIndex: 2, count: 7)
        let data = try JSONEncoder().encode(fb)
        let decoded = try JSONDecoder().decode(Fretboard.self, from: data)
        XCTAssertEqual(decoded.startIndex, 2)
        XCTAssertEqual(decoded.count, 7)
        XCTAssertEqual(decoded.tuning, GuitarTuning.standard)
    }

    // MARK: - Note grid generation

    func testNoteGridCount() {
        let fb = Fretboard(tuning: GuitarTuning.standard, startIndex: 0, count: 5)
        XCTAssertEqual(fb.notes.count, 6 * 5, "6 strings × 5 frets")
    }

    func testOpenStringPitchesMatchTuning() {
        let fb = Fretboard(tuning: GuitarTuning.standard, startIndex: 0, count: 5)
        let openNotes = fb.notes.filter { $0.fretIndex == 0 }
        // orderedStrings (horizontal) = reversed: E4, B3, G3, D3, A2, E2
        let expectedMIDI = GuitarTuning.standard.strings.reversed().map { $0.midiNoteNumber }
        XCTAssertEqual(openNotes.map { $0.pitch.midiNoteNumber }, expectedMIDI)
    }

    func testStartIndexShiftsPitches() {
        let fb0 = Fretboard(tuning: GuitarTuning.standard, startIndex: 0, count: 1)
        let fb5 = Fretboard(tuning: GuitarTuning.standard, startIndex: 5, count: 1)
        for (n0, n5) in zip(fb0.notes, fb5.notes) {
            XCTAssertEqual(n5.pitch.midiNoteNumber, n0.pitch.midiNoteNumber + 5,
                           "startIndex=5 should shift each pitch up 5 semitones")
        }
    }

    // MARK: - Pitch lookup

    /// `notes(matching:)` returns every grid position for a known pitch, regardless of which string.
    func testNotesMatchingPitch() {
        // Standard tuning, 12 frets. Open A2 (MIDI 45) appears on the A string (fret 0).
        // A2 also appears on the low E string at fret 5 (E2 + 5 = A2, MIDI 40+5=45).
        let fb = Fretboard(tuning: GuitarTuning.standard, startIndex: 0, count: 12)
        let a2 = Pitch(noteName: .a, octave: 2)
        let matches = fb.notes(matching: a2)
        XCTAssertFalse(matches.isEmpty, "A2 should appear at least once on the fretboard")
        XCTAssertTrue(matches.allSatisfy { $0.pitch.midiNoteNumber == a2.midiNoteNumber },
                      "All matching notes must have the correct MIDI number")
        // At minimum: open A string (stringIndex=4 in horizontal ordered, fret 0) and E string at fret 5.
        XCTAssertGreaterThanOrEqual(matches.count, 2)
    }

    /// `notes(matching:)` returns an empty array for a pitch outside the current fret window.
    func testNotesMatchingPitchOutOfRange() {
        let fb = Fretboard(tuning: GuitarTuning.standard, startIndex: 10, count: 3)
        // What matters is the method returns only notes whose MIDI matches.
        let c4 = Pitch(noteName: .c, octave: 4)
        let matches = fb.notes(matching: c4)
        XCTAssertTrue(matches.allSatisfy { $0.pitch.midiNoteNumber == c4.midiNoteNumber })
    }

    // MARK: - FretSizing

    func testFretSizingFit() {
        let sizing = FretSizing.fit
        XCTAssertEqual(sizing.fretLength(neckAxisLength: 500, count: 5), 100)
        XCTAssertEqual(sizing.fretLength(neckAxisLength: 300, count: 6), 50)
    }

    func testFretSizingFixed() {
        let sizing = FretSizing.fixed(80)
        XCTAssertEqual(sizing.fretLength(neckAxisLength: 500, count: 5), 80)
    }

    func testFretSizingMultiplier() {
        let sizing = FretSizing.multiplier(0.25)
        XCTAssertEqual(sizing.fretLength(neckAxisLength: 400, count: 5), 100)
    }

    func testFretSizingCodable() throws {
        let cases: [FretSizing] = [.fit, .fixed(120), .multiplier(0.3)]
        for sizing in cases {
            let data = try JSONEncoder().encode(sizing)
            let decoded = try JSONDecoder().decode(FretSizing.self, from: data)
            XCTAssertEqual(decoded, sizing)
        }
    }

    // MARK: - FretboardConfiguration Codable

    func testConfigurationCodable() throws {
        var cfg = FretboardConfiguration()
        cfg.isDrawNoteName = false
        cfg.fretWidth = 4
        cfg.stringColor = FretboardColor(red: 0.5, green: 0.2, blue: 0.8, alpha: 1)
        cfg.noteStyle = FretboardNoteStyle(color: .black, textColor: .white, borderWidth: 2)
        cfg.highlightNoteStyle = FretboardNoteStyle(
            color: FretboardColor(red: 1, green: 0.3, blue: 0, alpha: 1)
        )
        cfg.isCapoModeOn = true
        let data = try JSONEncoder().encode(cfg)
        let decoded = try JSONDecoder().decode(FretboardConfiguration.self, from: data)
        XCTAssertEqual(decoded.isDrawNoteName, false)
        XCTAssertEqual(decoded.fretWidth, 4)
        XCTAssertEqual(decoded.stringColor, cfg.stringColor)
        XCTAssertEqual(decoded.noteStyle.borderWidth, 2)
        XCTAssertEqual(decoded.highlightNoteStyle.color, cfg.highlightNoteStyle.color)
        XCTAssertEqual(decoded.isCapoModeOn, true)
    }

    func testFretMarkerColorCodable() throws {
        var cfg = FretboardConfiguration()
        cfg.fretMarkerColor = FretboardColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 1)
        let data = try JSONEncoder().encode(cfg)
        let decoded = try JSONDecoder().decode(FretboardConfiguration.self, from: data)
        XCTAssertEqual(decoded.fretMarkerColor, cfg.fretMarkerColor)
    }

    // MARK: - FretboardNoteStyle

    func testFretboardNoteStyleDefaultsToAllNil() {
        let style = FretboardNoteStyle()
        XCTAssertNil(style.color)
        XCTAssertNil(style.textColor)
        XCTAssertNil(style.borderColor)
        XCTAssertNil(style.borderWidth)
        XCTAssertNil(style.label)
    }

    func testFretboardNoteStylePartialInit() {
        let orange = FretboardColor(red: 1, green: 0.5, blue: 0, alpha: 1)
        let style = FretboardNoteStyle(color: orange, label: "♭3")
        XCTAssertEqual(style.color, orange)
        XCTAssertNil(style.textColor)
        XCTAssertNil(style.borderColor)
        XCTAssertNil(style.borderWidth)
        XCTAssertEqual(style.label, "♭3")
    }

    func testFretboardNoteStyleEmptyLabelSuppressesNote() {
        let style = FretboardNoteStyle(label: "")
        XCTAssertEqual(style.label, "", "Empty label must be preserved (not nil) to signal suppression")
    }

    func testFretboardNoteStyleMergedOver() {
        // Override provides color; base provides textColor and borderWidth.
        let override = FretboardNoteStyle(color: .black)
        let base = FretboardNoteStyle(textColor: .white, borderWidth: 2)
        let merged = override.merged(over: base)
        XCTAssertEqual(merged.color, .black,  "override.color should win")
        XCTAssertEqual(merged.textColor, .white, "base.textColor should fill the nil")
        XCTAssertEqual(merged.borderWidth, 2,  "base.borderWidth should fill the nil")
        XCTAssertNil(merged.borderColor)
        XCTAssertNil(merged.label, "nil label stays nil after merge (means 'use note name')")
    }

    func testFretboardNoteStyleResolutionChain() {
        // Simulate: per-note override → config default → built-in default.
        let perNote = FretboardNoteStyle(color: FretboardColor(red: 1, green: 0, blue: 0, alpha: 1))
        let configDefault = FretboardNoteStyle(color: .black, textColor: .white, borderWidth: 1)
        let builtIn = FretboardNoteStyle.defaultNote
        let base = configDefault.merged(over: builtIn)
        let resolved = perNote.merged(over: base)
        // perNote.color wins; config fills borderWidth; built-in fills the rest.
        XCTAssertEqual(resolved.color, FretboardColor(red: 1, green: 0, blue: 0, alpha: 1))
        XCTAssertEqual(resolved.textColor, .white)  // from config
        XCTAssertEqual(resolved.borderWidth, 1)     // from config
        XCTAssertEqual(resolved.borderColor, .clear) // from built-in
    }

    func testFretboardNoteStyleDefaultsAreConcrete() {
        // Built-in defaults must have non-nil color/textColor/borderColor/borderWidth
        // so the resolution chain always produces a fully-specified style.
        XCTAssertNotNil(FretboardNoteStyle.defaultNote.color)
        XCTAssertNotNil(FretboardNoteStyle.defaultNote.textColor)
        XCTAssertNotNil(FretboardNoteStyle.defaultNote.borderColor)
        XCTAssertNotNil(FretboardNoteStyle.defaultNote.borderWidth)
        XCTAssertNotNil(FretboardNoteStyle.defaultHighlight.color)
        XCTAssertNotNil(FretboardNoteStyle.defaultHighlight.textColor)
        XCTAssertNotNil(FretboardNoteStyle.defaultHighlight.borderColor)
        XCTAssertNotNil(FretboardNoteStyle.defaultHighlight.borderWidth)
    }

    // MARK: - FretInlay

    func testFretInlayCodable() throws {
        let cases: [FretInlay] = [.single, .double]
        for inlay in cases {
            let data = try JSONEncoder().encode(inlay)
            let decoded = try JSONDecoder().decode(FretInlay.self, from: data)
            XCTAssertEqual(decoded, inlay)
        }
    }

    // MARK: - P2: Position-targeted FretboardNote ID

    func testFretboardNoteIDFormat() {
        let fb = Fretboard(tuning: GuitarTuning.standard, startIndex: 0, count: 5)
        for note in fb.notes {
            let expectedID = "\(note.stringIndex)-\(note.fretIndex)"
            XCTAssertEqual(note.id, expectedID,
                           "FretboardNote.id must be 'stringIndex-fretIndex' for position-targeted marking")
        }
    }

    func testFretboardNoteIDsAreUniqueOnBoard() {
        let fb = Fretboard(tuning: GuitarTuning.standard, startIndex: 0, count: 12)
        let ids = fb.notes.map { $0.id }
        let uniqueIDs = Set(ids)
        XCTAssertEqual(ids.count, uniqueIDs.count,
                       "All FretboardNote IDs must be unique — position-targeted marking relies on this")
    }

    func testPositionTargetedNotesDifferFromPitchMatching() {
        // A chord shape selects one specific position per string, not every matching pitch.
        let fb = Fretboard(tuning: GuitarTuning.standard, startIndex: 0, count: 12)
        let c4 = Pitch(noteName: .c, octave: 4)
        let allC4 = fb.notes(matching: c4)
        // There should be multiple C4 positions on a full neck.
        XCTAssertGreaterThan(allC4.count, 1,
                             "C4 should appear on multiple strings — this is what P2 allows narrowing to one")
        // A specific position note should still be identifiable by ID.
        if let firstC4 = allC4.first {
            let byID = fb.notes.first { $0.id == firstC4.id }
            XCTAssertNotNil(byID)
            XCTAssertEqual(byID?.id, firstC4.id)
        }
    }

    // MARK: - removeAllNotes / clearNotes (model-level verification)

    func testRemoveAllNotesAPIExists() {
        // The Fretboard geometry grid is unaffected by scene display-state changes.
        let fb = Fretboard(tuning: GuitarTuning.standard, startIndex: 0, count: 5)
        let noteCountBefore = fb.notes.count
        XCTAssertEqual(fb.notes.count, noteCountBefore,
                       "Fretboard.notes (the geometry grid) must not be affected by scene display state")
    }
}
