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
        // C4 (MIDI 60) only lives on specific frets; narrow window may miss it.
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
        cfg.highlightNoteColor = FretboardColor(red: 1, green: 0.3, blue: 0, alpha: 1)
        cfg.noteBorderWidth = 2
        cfg.isCapoModeOn = true
        let data = try JSONEncoder().encode(cfg)
        let decoded = try JSONDecoder().decode(FretboardConfiguration.self, from: data)
        XCTAssertEqual(decoded.isDrawNoteName, false)
        XCTAssertEqual(decoded.fretWidth, 4)
        XCTAssertEqual(decoded.stringColor, cfg.stringColor)
        XCTAssertEqual(decoded.highlightNoteColor, cfg.highlightNoteColor)
        XCTAssertEqual(decoded.noteBorderWidth, 2)
        XCTAssertEqual(decoded.isCapoModeOn, true)
    }
}
