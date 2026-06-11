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

    // MARK: - Fretboard Codable round-trip

    func testFretboardCodableRoundTrip() throws {
        let fb = Fretboard(tuning: GuitarTuning.standard, startIndex: 2, count: 7)
        fb.select(scale: Scale(type: .major, root: .c))
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

    // MARK: - Scale selection (enharmonic fix)

    func testCMajorScaleSelection() {
        let fb = Fretboard(tuning: GuitarTuning.standard, startIndex: 0, count: 12)
        fb.select(scale: Scale(type: .major, root: .c))
        let selectedPCs = Set(fb.notes.filter { $0.isSelected }.map { $0.pitch.noteName.pitchClass })
        // C major pitch classes: C=0, D=2, E=4, F=5, G=7, A=9, B=11
        XCTAssertEqual(selectedPCs, [0, 2, 4, 5, 7, 9, 11])
    }

    /// Flat-spelled scale must light up sharp-spelled fret positions (enharmonic match).
    func testEnharmonicSelectionFlatScale() {
        let fb = Fretboard(tuning: GuitarTuning.standard, startIndex: 0, count: 12)
        // Db major: Db, Eb, F, Gb, Ab, Bb, C  (all flats)
        fb.select(scale: Scale(type: .major, root: .db))
        // G string (MIDI 55 open) at fret 4 = Ab4 (MIDI 59) if spelled sharp = G#
        // Find a note whose MIDI is a member of Db major regardless of spelling
        let selectedMIDIs = Set(fb.notes.filter { $0.isSelected }.map { $0.pitch.midiNoteNumber })
        // Db=1, Eb=3, F=5, Gb=6, Ab=8, Bb=10, C=0  — pitch classes
        let expectedPCs: Set<Int> = [1, 3, 5, 6, 8, 10, 0]
        let actualPCs = Set(selectedMIDIs.map { $0 % 12 })
        XCTAssertEqual(actualPCs, expectedPCs,
                       "Enharmonic note matching failed for flat-spelled scale")
    }

    // MARK: - Chord selection

    func testCMajorChordSelection() {
        let fb = Fretboard(tuning: GuitarTuning.standard, startIndex: 0, count: 5)
        fb.select(chord: Chord(type: .major, root: .c))
        let selectedPCs = Set(fb.notes.filter { $0.isSelected }.map { $0.pitch.noteName.pitchClass })
        // C major: C=0, E=4, G=7
        XCTAssertEqual(selectedPCs, [0, 4, 7])
    }

    // MARK: - deselectAll

    func testDeselectAll() {
        let fb = Fretboard(tuning: GuitarTuning.standard, startIndex: 0, count: 5)
        fb.select(scale: Scale(type: .major, root: .c))
        fb.deselectAll()
        XCTAssertTrue(fb.notes.allSatisfy { !$0.isSelected })
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
        let data = try JSONEncoder().encode(cfg)
        let decoded = try JSONDecoder().decode(FretboardConfiguration.self, from: data)
        XCTAssertEqual(decoded.isDrawNoteName, false)
        XCTAssertEqual(decoded.fretWidth, 4)
        XCTAssertEqual(decoded.stringColor, cfg.stringColor)
    }
}
