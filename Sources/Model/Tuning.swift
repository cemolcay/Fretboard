//
//  Tuning.swift
//  Fretboard
//
//  Created by Cem Olcay on 11/06/2026.
//

import MusicTheory

// MARK: - Tuning

/// Describes the open-string pitches of any fretted instrument.
/// Codable for persistence; user-defined tunings are created with `init(name:strings:)`.
public struct Tuning: Codable, Hashable, CustomStringConvertible {

    /// Display name, e.g. "Standard" or "My Custom Tuning".
    public var name: String

    /// Open-position pitches, ordered lowest string first (e.g. E2…E4 for standard guitar).
    public var strings: [Pitch]

    public init(name: String, strings: [Pitch]) {
        self.name = name
        self.strings = strings
    }

    public var description: String { name }
}

// MARK: - Guitar Tunings

/// Factory methods for common six-string guitar tunings.
public enum GuitarTuning {
    public static let standard = Tuning(name: "Standard", strings: [
        Pitch(noteName: .e, octave: 2),
        Pitch(noteName: .a, octave: 2),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .g, octave: 3),
        Pitch(noteName: .b, octave: 3),
        Pitch(noteName: .e, octave: 4),
    ])
    public static let dropD = Tuning(name: "Drop D", strings: [
        Pitch(noteName: .d, octave: 2),
        Pitch(noteName: .a, octave: 2),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .g, octave: 3),
        Pitch(noteName: .b, octave: 3),
        Pitch(noteName: .e, octave: 4),
    ])
    public static let halfStepDown = Tuning(name: "Half Step Down", strings: [
        Pitch(noteName: .eb, octave: 2),
        Pitch(noteName: .ab, octave: 2),
        Pitch(noteName: .db, octave: 3),
        Pitch(noteName: .gb, octave: 3),
        Pitch(noteName: .bb, octave: 3),
        Pitch(noteName: .eb, octave: 4),
    ])
    public static let fullStepDown = Tuning(name: "Full Step Down", strings: [
        Pitch(noteName: .d, octave: 2),
        Pitch(noteName: .g, octave: 2),
        Pitch(noteName: .c, octave: 3),
        Pitch(noteName: .f, octave: 3),
        Pitch(noteName: .a, octave: 3),
        Pitch(noteName: .d, octave: 4),
    ])
    public static let oneAndHalfStepDown = Tuning(name: "One and Half Step Down", strings: [
        Pitch(noteName: .db, octave: 2),
        Pitch(noteName: .gb, octave: 2),
        Pitch(noteName: .b, octave: 2),
        Pitch(noteName: .e, octave: 3),
        Pitch(noteName: .ab, octave: 3),
        Pitch(noteName: .db, octave: 4),
    ])
    public static let doubleDropD = Tuning(name: "Double Drop D", strings: [
        Pitch(noteName: .d, octave: 2),
        Pitch(noteName: .a, octave: 2),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .g, octave: 3),
        Pitch(noteName: .b, octave: 3),
        Pitch(noteName: .d, octave: 4),
    ])
    public static let dropC = Tuning(name: "Drop C", strings: [
        Pitch(noteName: .c, octave: 2),
        Pitch(noteName: .g, octave: 2),
        Pitch(noteName: .c, octave: 3),
        Pitch(noteName: .f, octave: 3),
        Pitch(noteName: .a, octave: 3),
        Pitch(noteName: .d, octave: 4),
    ])
    public static let dropDFlat = Tuning(name: "Drop D♭", strings: [
        Pitch(noteName: .db, octave: 2),
        Pitch(noteName: .ab, octave: 2),
        Pitch(noteName: .db, octave: 3),
        Pitch(noteName: .gb, octave: 3),
        Pitch(noteName: .bb, octave: 3),
        Pitch(noteName: .eb, octave: 4),
    ])
    public static let dropB = Tuning(name: "Drop B", strings: [
        Pitch(noteName: .b, octave: 1),
        Pitch(noteName: .gb, octave: 2),
        Pitch(noteName: .b, octave: 2),
        Pitch(noteName: .e, octave: 3),
        Pitch(noteName: .ab, octave: 3),
        Pitch(noteName: .db, octave: 4),
    ])
    public static let dropBFlat = Tuning(name: "Drop B♭", strings: [
        Pitch(noteName: .bb, octave: 1),
        Pitch(noteName: .f, octave: 2),
        Pitch(noteName: .bb, octave: 2),
        Pitch(noteName: .eb, octave: 3),
        Pitch(noteName: .g, octave: 3),
        Pitch(noteName: .c, octave: 4),
    ])
    public static let dropA = Tuning(name: "Drop A", strings: [
        Pitch(noteName: .a, octave: 1),
        Pitch(noteName: .e, octave: 2),
        Pitch(noteName: .a, octave: 2),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .gb, octave: 3),
        Pitch(noteName: .b, octave: 3),
    ])
    public static let openD = Tuning(name: "Open D", strings: [
        Pitch(noteName: .d, octave: 2),
        Pitch(noteName: .a, octave: 2),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .gb, octave: 3),
        Pitch(noteName: .a, octave: 3),
        Pitch(noteName: .d, octave: 4),
    ])
    public static let openDMinor = Tuning(name: "Open D Minor", strings: [
        Pitch(noteName: .d, octave: 2),
        Pitch(noteName: .a, octave: 2),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .f, octave: 3),
        Pitch(noteName: .a, octave: 3),
        Pitch(noteName: .d, octave: 4),
    ])
    public static let openG = Tuning(name: "Open G", strings: [
        Pitch(noteName: .d, octave: 2),
        Pitch(noteName: .g, octave: 2),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .g, octave: 3),
        Pitch(noteName: .b, octave: 3),
        Pitch(noteName: .d, octave: 4),
    ])
    public static let openGMinor = Tuning(name: "Open G Minor", strings: [
        Pitch(noteName: .d, octave: 2),
        Pitch(noteName: .g, octave: 2),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .g, octave: 3),
        Pitch(noteName: .bb, octave: 3),
        Pitch(noteName: .d, octave: 4),
    ])
    public static let openC = Tuning(name: "Open C", strings: [
        Pitch(noteName: .c, octave: 2),
        Pitch(noteName: .g, octave: 2),
        Pitch(noteName: .c, octave: 3),
        Pitch(noteName: .g, octave: 3),
        Pitch(noteName: .c, octave: 4),
        Pitch(noteName: .e, octave: 4),
    ])
    public static let openDFlat = Tuning(name: "Open D♭", strings: [
        Pitch(noteName: .db, octave: 2),
        Pitch(noteName: .gb, octave: 2),
        Pitch(noteName: .b, octave: 3),
        Pitch(noteName: .e, octave: 3),
        Pitch(noteName: .ab, octave: 3),
        Pitch(noteName: .db, octave: 4),
    ])
    public static let openCMinor = Tuning(name: "Open C Minor", strings: [
        Pitch(noteName: .c, octave: 2),
        Pitch(noteName: .g, octave: 2),
        Pitch(noteName: .c, octave: 3),
        Pitch(noteName: .g, octave: 3),
        Pitch(noteName: .c, octave: 4),
        Pitch(noteName: .eb, octave: 4),
    ])
    public static let openE7 = Tuning(name: "Open E7", strings: [
        Pitch(noteName: .e, octave: 2),
        Pitch(noteName: .ab, octave: 2),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .e, octave: 3),
        Pitch(noteName: .b, octave: 3),
        Pitch(noteName: .e, octave: 4),
    ])
    public static let openEMinor7 = Tuning(name: "Open E Minor 7", strings: [
        Pitch(noteName: .e, octave: 2),
        Pitch(noteName: .b, octave: 2),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .g, octave: 3),
        Pitch(noteName: .b, octave: 3),
        Pitch(noteName: .e, octave: 4),
    ])
    public static let openGMajor7 = Tuning(name: "Open G Major 7", strings: [
        Pitch(noteName: .d, octave: 2),
        Pitch(noteName: .g, octave: 2),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .gb, octave: 3),
        Pitch(noteName: .b, octave: 3),
        Pitch(noteName: .d, octave: 4),
    ])
    public static let openAMinor = Tuning(name: "Open A Minor", strings: [
        Pitch(noteName: .e, octave: 2),
        Pitch(noteName: .a, octave: 2),
        Pitch(noteName: .e, octave: 3),
        Pitch(noteName: .a, octave: 3),
        Pitch(noteName: .c, octave: 4),
        Pitch(noteName: .e, octave: 4),
    ])
    public static let openAMinor7 = Tuning(name: "Open A Minor 7", strings: [
        Pitch(noteName: .e, octave: 2),
        Pitch(noteName: .a, octave: 2),
        Pitch(noteName: .e, octave: 3),
        Pitch(noteName: .g, octave: 3),
        Pitch(noteName: .c, octave: 4),
        Pitch(noteName: .e, octave: 4),
    ])
    public static let openE = Tuning(name: "Open E", strings: [
        Pitch(noteName: .e, octave: 2),
        Pitch(noteName: .b, octave: 2),
        Pitch(noteName: .e, octave: 3),
        Pitch(noteName: .ab, octave: 3),
        Pitch(noteName: .b, octave: 3),
        Pitch(noteName: .e, octave: 4),
    ])
    public static let openA = Tuning(name: "Open A", strings: [
        Pitch(noteName: .e, octave: 2),
        Pitch(noteName: .a, octave: 2),
        Pitch(noteName: .db, octave: 3),
        Pitch(noteName: .e, octave: 3),
        Pitch(noteName: .a, octave: 3),
        Pitch(noteName: .e, octave: 4),
    ])
    public static let c = Tuning(name: "C", strings: [
        Pitch(noteName: .c, octave: 2),
        Pitch(noteName: .f, octave: 2),
        Pitch(noteName: .bb, octave: 2),
        Pitch(noteName: .eb, octave: 3),
        Pitch(noteName: .g, octave: 3),
        Pitch(noteName: .c, octave: 4),
    ])
    public static let dFlat = Tuning(name: "D♭", strings: [
        Pitch(noteName: .db, octave: 2),
        Pitch(noteName: .gb, octave: 2),
        Pitch(noteName: .b, octave: 2),
        Pitch(noteName: .e, octave: 3),
        Pitch(noteName: .ab, octave: 3),
        Pitch(noteName: .db, octave: 4),
    ])
    public static let bFlat = Tuning(name: "B♭", strings: [
        Pitch(noteName: .bb, octave: 1),
        Pitch(noteName: .eb, octave: 2),
        Pitch(noteName: .ab, octave: 2),
        Pitch(noteName: .db, octave: 3),
        Pitch(noteName: .f, octave: 3),
        Pitch(noteName: .bb, octave: 3),
    ])
    public static let baritone = Tuning(name: "Baritone", strings: [
        Pitch(noteName: .a, octave: 1),
        Pitch(noteName: .d, octave: 2),
        Pitch(noteName: .g, octave: 2),
        Pitch(noteName: .c, octave: 3),
        Pitch(noteName: .e, octave: 3),
        Pitch(noteName: .a, octave: 3),
    ])
    public static let dadddd = Tuning(name: "DADDDD", strings: [
        Pitch(noteName: .d, octave: 2),
        Pitch(noteName: .a, octave: 2),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .d, octave: 4),
        Pitch(noteName: .d, octave: 4),
    ])
    public static let cgdgbd = Tuning(name: "CGDGBD", strings: [
        Pitch(noteName: .c, octave: 2),
        Pitch(noteName: .g, octave: 2),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .g, octave: 3),
        Pitch(noteName: .b, octave: 3),
        Pitch(noteName: .d, octave: 4),
    ])
    public static let cgdgbe = Tuning(name: "CGDGBE", strings: [
        Pitch(noteName: .c, octave: 2),
        Pitch(noteName: .g, octave: 2),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .g, octave: 3),
        Pitch(noteName: .b, octave: 3),
        Pitch(noteName: .e, octave: 4),
    ])
    public static let dadead = Tuning(name: "DADEAD", strings: [
        Pitch(noteName: .d, octave: 2),
        Pitch(noteName: .a, octave: 2),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .e, octave: 3),
        Pitch(noteName: .a, octave: 3),
        Pitch(noteName: .d, octave: 4),
    ])
    public static let dgdgad = Tuning(name: "DGDGAD", strings: [
        Pitch(noteName: .d, octave: 2),
        Pitch(noteName: .g, octave: 2),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .g, octave: 3),
        Pitch(noteName: .a, octave: 3),
        Pitch(noteName: .d, octave: 4),
    ])
    public static let openDSus2 = Tuning(name: "Open D Sus2", strings: [
        Pitch(noteName: .d, octave: 2),
        Pitch(noteName: .a, octave: 2),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .g, octave: 3),
        Pitch(noteName: .a, octave: 3),
        Pitch(noteName: .d, octave: 4),
    ])
    public static let openGSus2 = Tuning(name: "Open G Sus2", strings: [
        Pitch(noteName: .d, octave: 2),
        Pitch(noteName: .g, octave: 2),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .g, octave: 3),
        Pitch(noteName: .c, octave: 4),
        Pitch(noteName: .d, octave: 4),
    ])
    public static let g6 = Tuning(name: "G6", strings: [
        Pitch(noteName: .d, octave: 2),
        Pitch(noteName: .g, octave: 2),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .g, octave: 3),
        Pitch(noteName: .b, octave: 3),
        Pitch(noteName: .e, octave: 4),
    ])
    public static let modalG = Tuning(name: "Modal G", strings: [
        Pitch(noteName: .d, octave: 2),
        Pitch(noteName: .g, octave: 2),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .g, octave: 3),
        Pitch(noteName: .c, octave: 4),
        Pitch(noteName: .d, octave: 4),
    ])
    public static let overtone = Tuning(name: "Overtone", strings: [
        Pitch(noteName: .c, octave: 3),
        Pitch(noteName: .e, octave: 3),
        Pitch(noteName: .g, octave: 3),
        Pitch(noteName: .bb, octave: 3),
        Pitch(noteName: .c, octave: 4),
        Pitch(noteName: .d, octave: 4),
    ])
    public static let pentatonic = Tuning(name: "Pentatonic", strings: [
        Pitch(noteName: .a, octave: 2),
        Pitch(noteName: .c, octave: 3),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .e, octave: 3),
        Pitch(noteName: .g, octave: 3),
        Pitch(noteName: .a, octave: 4),
    ])
    public static let minorTriad = Tuning(name: "Minor Triad", strings: [
        Pitch(noteName: .c, octave: 3),
        Pitch(noteName: .eb, octave: 3),
        Pitch(noteName: .gb, octave: 3),
        Pitch(noteName: .a, octave: 3),
        Pitch(noteName: .c, octave: 4),
        Pitch(noteName: .eb, octave: 4),
    ])
    public static let majorTriad = Tuning(name: "Major Triad", strings: [
        Pitch(noteName: .c, octave: 3),
        Pitch(noteName: .e, octave: 3),
        Pitch(noteName: .ab, octave: 3),
        Pitch(noteName: .c, octave: 4),
        Pitch(noteName: .e, octave: 4),
        Pitch(noteName: .ab, octave: 4),
    ])
    public static let allFourths = Tuning(name: "All Fourths", strings: [
        Pitch(noteName: .e, octave: 2),
        Pitch(noteName: .a, octave: 2),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .g, octave: 3),
        Pitch(noteName: .c, octave: 4),
        Pitch(noteName: .f, octave: 4),
    ])
    public static let augmentedFourths = Tuning(name: "Augmented Fourths", strings: [
        Pitch(noteName: .c, octave: 2),
        Pitch(noteName: .gb, octave: 2),
        Pitch(noteName: .c, octave: 3),
        Pitch(noteName: .gb, octave: 3),
        Pitch(noteName: .c, octave: 4),
        Pitch(noteName: .gb, octave: 4),
    ])
    public static let slowMotion = Tuning(name: "Slow Motion", strings: [
        Pitch(noteName: .d, octave: 2),
        Pitch(noteName: .g, octave: 2),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .f, octave: 3),
        Pitch(noteName: .c, octave: 4),
        Pitch(noteName: .d, octave: 4),
    ])
    public static let admiral = Tuning(name: "Admiral", strings: [
        Pitch(noteName: .c, octave: 2),
        Pitch(noteName: .g, octave: 2),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .g, octave: 3),
        Pitch(noteName: .b, octave: 3),
        Pitch(noteName: .c, octave: 4),
    ])
    public static let buzzard = Tuning(name: "Buzzard", strings: [
        Pitch(noteName: .c, octave: 2),
        Pitch(noteName: .f, octave: 2),
        Pitch(noteName: .c, octave: 3),
        Pitch(noteName: .g, octave: 3),
        Pitch(noteName: .bb, octave: 3),
        Pitch(noteName: .f, octave: 4),
    ])
    public static let face = Tuning(name: "Face", strings: [
        Pitch(noteName: .c, octave: 2),
        Pitch(noteName: .g, octave: 2),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .g, octave: 3),
        Pitch(noteName: .a, octave: 3),
        Pitch(noteName: .d, octave: 4),
    ])
    public static let fourAndTwenty = Tuning(name: "Four and Twenty", strings: [
        Pitch(noteName: .d, octave: 2),
        Pitch(noteName: .a, octave: 2),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .a, octave: 3),
        Pitch(noteName: .d, octave: 4),
    ])
    public static let ostrich = Tuning(name: "Ostrich", strings: [
        Pitch(noteName: .d, octave: 2),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .d, octave: 4),
        Pitch(noteName: .d, octave: 4),
    ])
    public static let capo200 = Tuning(name: "Capo 200", strings: [
        Pitch(noteName: .c, octave: 2),
        Pitch(noteName: .g, octave: 2),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .eb, octave: 3),
        Pitch(noteName: .d, octave: 4),
        Pitch(noteName: .eb, octave: 4),
    ])
    public static let balalaika = Tuning(name: "Balalaika", strings: [
        Pitch(noteName: .e, octave: 2),
        Pitch(noteName: .a, octave: 2),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .e, octave: 3),
        Pitch(noteName: .e, octave: 3),
        Pitch(noteName: .a, octave: 3),
    ])
    public static let charango = Tuning(name: "Charango", strings: [
        Pitch(noteName: .g, octave: 2),
        Pitch(noteName: .c, octave: 3),
        Pitch(noteName: .e, octave: 3),
        Pitch(noteName: .a, octave: 3),
        Pitch(noteName: .e, octave: 4),
    ])
    public static let citternOne = Tuning(name: "Cittern One", strings: [
        Pitch(noteName: .c, octave: 2),
        Pitch(noteName: .f, octave: 2),
        Pitch(noteName: .c, octave: 3),
        Pitch(noteName: .g, octave: 3),
        Pitch(noteName: .c, octave: 4),
        Pitch(noteName: .d, octave: 4),
    ])
    public static let citternTwo = Tuning(name: "Cittern Two", strings: [
        Pitch(noteName: .c, octave: 2),
        Pitch(noteName: .g, octave: 2),
        Pitch(noteName: .c, octave: 3),
        Pitch(noteName: .g, octave: 3),
        Pitch(noteName: .c, octave: 4),
        Pitch(noteName: .g, octave: 4),
    ])
    public static let dobro = Tuning(name: "Dobro", strings: [
        Pitch(noteName: .g, octave: 2),
        Pitch(noteName: .b, octave: 2),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .g, octave: 3),
        Pitch(noteName: .b, octave: 3),
        Pitch(noteName: .d, octave: 4),
    ])
    public static let lefty = Tuning(name: "Lefty", strings: [
        Pitch(noteName: .e, octave: 4),
        Pitch(noteName: .b, octave: 3),
        Pitch(noteName: .g, octave: 3),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .a, octave: 2),
        Pitch(noteName: .e, octave: 2),
    ])
    public static let mandoGuitar = Tuning(name: "Mando Guitar", strings: [
        Pitch(noteName: .c, octave: 2),
        Pitch(noteName: .g, octave: 2),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .a, octave: 3),
        Pitch(noteName: .e, octave: 4),
        Pitch(noteName: .b, octave: 4),
    ])
    public static let rustyCage = Tuning(name: "Rusty Cage", strings: [
        Pitch(noteName: .b, octave: 1),
        Pitch(noteName: .a, octave: 2),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .g, octave: 3),
        Pitch(noteName: .b, octave: 3),
        Pitch(noteName: .e, octave: 4),
    ])

    /// All standard six-string guitar tunings.
    public static let all: [Tuning] = [
        standard, dropD, halfStepDown, fullStepDown, oneAndHalfStepDown, doubleDropD,
        dropC, dropDFlat, dropB, dropBFlat, dropA,
        openD, openDMinor, openG, openGMinor, openC, openDFlat, openCMinor,
        openE7, openEMinor7, openGMajor7, openAMinor, openAMinor7, openE, openA,
        c, dFlat, bFlat, baritone,
        dadddd, cgdgbd, cgdgbe, dadead, dgdgad,
        openDSus2, openGSus2, g6, modalG,
        overtone, pentatonic, minorTriad, majorTriad, allFourths, augmentedFourths,
        slowMotion, admiral, buzzard, face, fourAndTwenty, ostrich, capo200,
        balalaika, charango, citternOne, citternTwo, dobro, lefty, mandoGuitar, rustyCage,
    ]
}

// MARK: - Bass Tunings

/// Factory methods for common bass guitar tunings.
public enum BassTuning {
    public static let standard4String = Tuning(name: "4 String Standard", strings: [
        Pitch(noteName: .e, octave: 1),
        Pitch(noteName: .a, octave: 1),
        Pitch(noteName: .d, octave: 2),
        Pitch(noteName: .g, octave: 2),
    ])
    public static let standard5String = Tuning(name: "5 String Standard", strings: [
        Pitch(noteName: .b, octave: 0),
        Pitch(noteName: .e, octave: 1),
        Pitch(noteName: .a, octave: 1),
        Pitch(noteName: .d, octave: 2),
        Pitch(noteName: .g, octave: 2),
    ])
    public static let standard6String = Tuning(name: "6 String Standard", strings: [
        Pitch(noteName: .b, octave: 0),
        Pitch(noteName: .e, octave: 1),
        Pitch(noteName: .a, octave: 1),
        Pitch(noteName: .d, octave: 2),
        Pitch(noteName: .g, octave: 2),
        Pitch(noteName: .c, octave: 3),
    ])
    public static let standard7String = Tuning(name: "7 String Standard", strings: [
        Pitch(noteName: .b, octave: 0),
        Pitch(noteName: .e, octave: 1),
        Pitch(noteName: .a, octave: 1),
        Pitch(noteName: .d, octave: 2),
        Pitch(noteName: .g, octave: 2),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .c, octave: 3),
    ])
    public static let standard8String = Tuning(name: "8 String Standard", strings: [
        Pitch(noteName: .gb, octave: 0),
        Pitch(noteName: .b, octave: 0),
        Pitch(noteName: .e, octave: 1),
        Pitch(noteName: .a, octave: 1),
        Pitch(noteName: .d, octave: 2),
        Pitch(noteName: .g, octave: 2),
        Pitch(noteName: .c, octave: 3),
        Pitch(noteName: .f, octave: 3),
    ])
    public static let dropD4String = Tuning(name: "4 String Drop D", strings: [
        Pitch(noteName: .d, octave: 1),
        Pitch(noteName: .a, octave: 1),
        Pitch(noteName: .d, octave: 2),
        Pitch(noteName: .g, octave: 2),
    ])
    public static let dropB4String = Tuning(name: "4 String Drop B", strings: [
        Pitch(noteName: .b, octave: 0),
        Pitch(noteName: .gb, octave: 1),
        Pitch(noteName: .b, octave: 1),
        Pitch(noteName: .e, octave: 2),
    ])
    public static let openA4String = Tuning(name: "4 String Open A", strings: [
        Pitch(noteName: .e, octave: 1),
        Pitch(noteName: .a, octave: 1),
        Pitch(noteName: .e, octave: 2),
        Pitch(noteName: .a, octave: 2),
    ])
    public static let openE4String = Tuning(name: "4 String Open E", strings: [
        Pitch(noteName: .e, octave: 1),
        Pitch(noteName: .b, octave: 1),
        Pitch(noteName: .e, octave: 2),
        Pitch(noteName: .ab, octave: 2),
    ])
    public static let e7sus44String = Tuning(name: "4 String E7sus4", strings: [
        Pitch(noteName: .b, octave: 1),
        Pitch(noteName: .e, octave: 1),
        Pitch(noteName: .a, octave: 2),
        Pitch(noteName: .d, octave: 2),
    ])
    public static let gsus44String = Tuning(name: "4 String Gsus4", strings: [
        Pitch(noteName: .d, octave: 1),
        Pitch(noteName: .a, octave: 1),
        Pitch(noteName: .d, octave: 2),
        Pitch(noteName: .g, octave: 2),
    ])
    public static let tenor4String = Tuning(name: "4 String Tenor", strings: [
        Pitch(noteName: .a, octave: 1),
        Pitch(noteName: .d, octave: 1),
        Pitch(noteName: .g, octave: 2),
        Pitch(noteName: .c, octave: 2),
    ])
    public static let piccolo4String = Tuning(name: "4 String Piccolo", strings: [
        Pitch(noteName: .e, octave: 2),
        Pitch(noteName: .a, octave: 2),
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .g, octave: 3),
    ])
    public static let halfStepDown4String = Tuning(name: "4 String Half Step Down", strings: [
        Pitch(noteName: .eb, octave: 1),
        Pitch(noteName: .ab, octave: 1),
        Pitch(noteName: .db, octave: 2),
        Pitch(noteName: .gb, octave: 2),
    ])
    public static let halfStepDown5String = Tuning(name: "5 String Half Step Down", strings: [
        Pitch(noteName: .bb, octave: 0),
        Pitch(noteName: .eb, octave: 1),
        Pitch(noteName: .ab, octave: 1),
        Pitch(noteName: .db, octave: 2),
        Pitch(noteName: .gb, octave: 2),
    ])
    public static let halfStepDown6String = Tuning(name: "6 String Half Step Down", strings: [
        Pitch(noteName: .bb, octave: 0),
        Pitch(noteName: .eb, octave: 1),
        Pitch(noteName: .ab, octave: 1),
        Pitch(noteName: .db, octave: 2),
        Pitch(noteName: .gb, octave: 2),
        Pitch(noteName: .b, octave: 3),
    ])
    public static let fullStepDown4String = Tuning(name: "4 String Full Step Down", strings: [
        Pitch(noteName: .d, octave: 1),
        Pitch(noteName: .g, octave: 1),
        Pitch(noteName: .c, octave: 2),
        Pitch(noteName: .f, octave: 2),
    ])
    public static let fullStepDown5String = Tuning(name: "5 String Full Step Down", strings: [
        Pitch(noteName: .a, octave: 0),
        Pitch(noteName: .d, octave: 1),
        Pitch(noteName: .g, octave: 1),
        Pitch(noteName: .c, octave: 2),
        Pitch(noteName: .f, octave: 2),
    ])
    public static let eadgcf6String = Tuning(name: "6 String EADGCF", strings: [
        Pitch(noteName: .e, octave: 0),
        Pitch(noteName: .a, octave: 1),
        Pitch(noteName: .d, octave: 1),
        Pitch(noteName: .g, octave: 2),
        Pitch(noteName: .c, octave: 2),
        Pitch(noteName: .f, octave: 3),
    ])
    public static let fbeadg6String = Tuning(name: "6 String F#BEADG", strings: [
        Pitch(noteName: .gb, octave: 0),
        Pitch(noteName: .b, octave: 1),
        Pitch(noteName: .e, octave: 1),
        Pitch(noteName: .a, octave: 2),
        Pitch(noteName: .d, octave: 2),
        Pitch(noteName: .g, octave: 3),
    ])
    public static let fbeadgc7String = Tuning(name: "7 String F#BEADGC", strings: [
        Pitch(noteName: .gb, octave: 0),
        Pitch(noteName: .b, octave: 1),
        Pitch(noteName: .e, octave: 1),
        Pitch(noteName: .a, octave: 2),
        Pitch(noteName: .d, octave: 2),
        Pitch(noteName: .g, octave: 3),
        Pitch(noteName: .c, octave: 3),
    ])

    /// All standard bass tunings.
    public static let all: [Tuning] = [
        standard4String, standard5String, standard6String, standard7String, standard8String,
        dropD4String, dropB4String, openA4String, openE4String,
        e7sus44String, gsus44String, tenor4String, piccolo4String,
        halfStepDown4String, halfStepDown5String, halfStepDown6String,
        fullStepDown4String, fullStepDown5String,
        eadgcf6String, fbeadg6String, fbeadgc7String,
    ]
}

// MARK: - Ukulele Tunings

/// Factory methods for common ukulele tunings.
public enum UkuleleTuning {
    public static let standard = Tuning(name: "Ukulele Standard", strings: [
        Pitch(noteName: .g, octave: 4),
        Pitch(noteName: .c, octave: 4),
        Pitch(noteName: .e, octave: 4),
        Pitch(noteName: .a, octave: 4),
    ])
    public static let soprano = Tuning(name: "Ukulele Soprano", strings: [
        Pitch(noteName: .a, octave: 4),
        Pitch(noteName: .d, octave: 4),
        Pitch(noteName: .gb, octave: 4),
        Pitch(noteName: .b, octave: 4),
    ])
    public static let baritone = Tuning(name: "Ukulele Baritone", strings: [
        Pitch(noteName: .d, octave: 3),
        Pitch(noteName: .g, octave: 3),
        Pitch(noteName: .b, octave: 3),
        Pitch(noteName: .e, octave: 4),
    ])
    public static let tenor = Tuning(name: "Ukulele Tenor", strings: [
        Pitch(noteName: .g, octave: 3),
        Pitch(noteName: .c, octave: 4),
        Pitch(noteName: .e, octave: 4),
        Pitch(noteName: .a, octave: 4),
    ])

    /// All standard ukulele tunings.
    public static let all: [Tuning] = [standard, soprano, baritone, tenor]
}
