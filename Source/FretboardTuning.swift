//
//  FretboardTuning.swift
//  Fretboard
//
//  Created by Cem Olcay on 20/04/2017.
//
//

#if os(iOS) || os(tvOS)
  import UIKit
#elseif os(OSX)
  import AppKit
#endif
import MusicTheorySwift

// MARK: - FretboardTuning

/// Describes strings and their open position notes on any fretboard.
public protocol FretboardTuning: CustomStringConvertible {

  /// Open position notes of strings on fretboard. From top to down in horizontal fashion.
  var strings: [Note] { get }
}

// MARK: - GuitarTuning

/// Six string guitar tunings.
public enum GuitarTuning: FretboardTuning {
  case standard
  case dropD
  case halfStepDown
  case fullStepDown
  case oneAndHalfStepDown
  case doubleDropD
  case dropC
  case dropDFlat
  case dropB
  case dropBFlat
  case dropA
  case openD
  case openDMinor
  case openG
  case openGMinor
  case openC
  case openDFlat
  case openCMinor
  case openE7
  case openEMinor7
  case openGMajor7
  case openAMinor
  case openAMinor7
  case openE
  case openA
  case c
  case dFlat
  case bFlat
  case baritone
  case dadddd
  case cgdgbd
  case cgdgbe
  case dadead
  case dgdgad
  case openDSus2
  case openGSus2
  case g6
  case modalG
  case overtone
  case pentatonic
  case minorThriad
  case majorThriad
  case allFourths
  case agumentedFourths
  case slowMotion
  case admiral
  case buzzard
  case face
  case fourAndTwenty
  case ostrich
  case capo200
  case balalaika
  case charango
  case citternOne
  case citternTwo
  case dobro
  case leftty
  case mandoguitar
  case rustyCage

  public var strings: [Note] {
    switch self {
    case .standard:
      return [
        Note(type: .e, octave: 2),
        Note(type: .a, octave: 2),
        Note(type: .d, octave: 3),
        Note(type: .g, octave: 3),
        Note(type: .b, octave: 3),
        Note(type: .e, octave: 4)
      ]
    case .dropD:
      return [
        Note(type: .d, octave: 2),
        Note(type: .a, octave: 2),
        Note(type: .d, octave: 3),
        Note(type: .g, octave: 3),
        Note(type: .b, octave: 3),
        Note(type: .e, octave: 4)
      ]
    case .halfStepDown:
      return [
        Note(type: .eFlat, octave: 2),
        Note(type: .aFlat, octave: 2),
        Note(type: .dFlat, octave: 3),
        Note(type: .gFlat, octave: 3),
        Note(type: .bFlat, octave: 3),
        Note(type: .eFlat, octave: 4)
      ]
    case .fullStepDown:
      return [
        Note(type: .d, octave: 2),
        Note(type: .g, octave: 2),
        Note(type: .c, octave: 3),
        Note(type: .f, octave: 3),
        Note(type: .a, octave: 3),
        Note(type: .d, octave: 4)
      ]
    case .oneAndHalfStepDown:
      return [
        Note(type: .dFlat, octave: 2),
        Note(type: .gFlat, octave: 2),
        Note(type: .b, octave: 2),
        Note(type: .e, octave: 3),
        Note(type: .aFlat, octave: 3),
        Note(type: .dFlat, octave: 4)
      ]
    case .doubleDropD:
      return [
        Note(type: .d, octave: 2),
        Note(type: .a, octave: 2),
        Note(type: .d, octave: 3),
        Note(type: .g, octave: 3),
        Note(type: .b, octave: 3),
        Note(type: .d, octave: 4)
      ]
    case .dropC:
      return [
        Note(type: .c, octave: 2),
        Note(type: .g, octave: 2),
        Note(type: .c, octave: 3),
        Note(type: .f, octave: 3),
        Note(type: .a, octave: 3),
        Note(type: .d, octave: 4)
      ]
    case .dropDFlat:
      return [
        Note(type: .dFlat, octave: 2),
        Note(type: .aFlat, octave: 2),
        Note(type: .dFlat, octave: 3),
        Note(type: .gFlat, octave: 3),
        Note(type: .bFlat, octave: 3),
        Note(type: .eFlat, octave: 4)
      ]
    case .dropB:
      return [
        Note(type: .b, octave: 1),
        Note(type: .gFlat, octave: 2),
        Note(type: .b, octave: 2),
        Note(type: .e, octave: 3),
        Note(type: .aFlat, octave: 3),
        Note(type: .dFlat, octave: 4)
      ]
    case .dropBFlat:
      return [
        Note(type: .bFlat, octave: 1),
        Note(type: .f, octave: 2),
        Note(type: .bFlat, octave: 2),
        Note(type: .eFlat, octave: 3),
        Note(type: .g, octave: 3),
        Note(type: .c, octave: 4)
      ]
    case .dropA:
      return [
        Note(type: .a, octave: 1),
        Note(type: .e, octave: 2),
        Note(type: .a, octave: 2),
        Note(type: .d, octave: 3),
        Note(type: .gFlat, octave: 3),
        Note(type: .b, octave: 3)
      ]
    case .openD:
      return [
        Note(type: .d, octave: 2),
        Note(type: .a, octave: 2),
        Note(type: .d, octave: 3),
        Note(type: .gFlat, octave: 3),
        Note(type: .a, octave: 3),
        Note(type: .d, octave: 4)
      ]
    case .openDMinor:
      return [
        Note(type: .d, octave: 2),
        Note(type: .a, octave: 2),
        Note(type: .d, octave: 3),
        Note(type: .f, octave: 3),
        Note(type: .a, octave: 3),
        Note(type: .d, octave: 4)
      ]
    case .openG:
      return [
        Note(type: .d, octave: 2),
        Note(type: .g, octave: 2),
        Note(type: .d, octave: 3),
        Note(type: .g, octave: 3),
        Note(type: .b, octave: 3),
        Note(type: .d, octave: 4)
      ]
    case .openGMinor:
      return [
        Note(type: .d, octave: 2),
        Note(type: .g, octave: 2),
        Note(type: .d, octave: 3),
        Note(type: .g, octave: 3),
        Note(type: .bFlat, octave: 3),
        Note(type: .d, octave: 4)
      ]
    case .openC:
      return [
        Note(type: .c, octave: 2),
        Note(type: .g, octave: 2),
        Note(type: .c, octave: 3),
        Note(type: .g, octave: 3),
        Note(type: .c, octave: 4),
        Note(type: .e, octave: 4)
      ]
    case .openDFlat:
      return [
        Note(type: .dFlat, octave: 2),
        Note(type: .gFlat, octave: 2),
        Note(type: .b, octave: 3),
        Note(type: .e, octave: 3),
        Note(type: .aFlat, octave: 3),
        Note(type: .dFlat, octave: 4)
      ]
    case .openCMinor:
      return [
        Note(type: .c, octave: 2),
        Note(type: .g, octave: 2),
        Note(type: .c, octave: 3),
        Note(type: .g, octave: 3),
        Note(type: .c, octave: 4),
        Note(type: .eFlat, octave: 4)
      ]
    case .openE7:
      return [
        Note(type: .e, octave: 2),
        Note(type: .aFlat, octave: 2),
        Note(type: .d, octave: 3),
        Note(type: .e, octave: 3),
        Note(type: .b, octave: 3),
        Note(type: .e, octave: 4)
      ]
    case .openEMinor7:
      return [
        Note(type: .e, octave: 2),
        Note(type: .b, octave: 2),
        Note(type: .d, octave: 3),
        Note(type: .g, octave: 3),
        Note(type: .b, octave: 3),
        Note(type: .e, octave: 4)
      ]
    case .openGMajor7:
      return [
        Note(type: .d, octave: 2),
        Note(type: .g, octave: 2),
        Note(type: .d, octave: 3),
        Note(type: .gFlat, octave: 3),
        Note(type: .b, octave: 3),
        Note(type: .d, octave: 4)
      ]
    case .openAMinor:
      return [
        Note(type: .e, octave: 2),
        Note(type: .a, octave: 2),
        Note(type: .e, octave: 3),
        Note(type: .a, octave: 3),
        Note(type: .c, octave: 4),
        Note(type: .e, octave: 4)
      ]
    case .openAMinor7:
      return [
        Note(type: .e, octave: 2),
        Note(type: .a, octave: 2),
        Note(type: .e, octave: 3),
        Note(type: .g, octave: 3),
        Note(type: .c, octave: 4),
        Note(type: .e, octave: 4)
      ]
    case .openE:
      return [
        Note(type: .e, octave: 2),
        Note(type: .b, octave: 2),
        Note(type: .e, octave: 3),
        Note(type: .aFlat, octave: 3),
        Note(type: .b, octave: 3),
        Note(type: .e, octave: 4)
      ]
    case .openA:
      return [
        Note(type: .e, octave: 2),
        Note(type: .a, octave: 2),
        Note(type: .dFlat, octave: 3),
        Note(type: .e, octave: 3),
        Note(type: .a, octave: 3),
        Note(type: .e, octave: 4)
      ]
    case .c:
      return [
        Note(type: .c, octave: 2),
        Note(type: .f, octave: 2),
        Note(type: .bFlat, octave: 2),
        Note(type: .eFlat, octave: 3),
        Note(type: .g, octave: 3),
        Note(type: .c, octave: 4)
      ]
    case .dFlat:
      return [
        Note(type: .dFlat, octave: 2),
        Note(type: .gFlat, octave: 2),
        Note(type: .b, octave: 2),
        Note(type: .e, octave: 3),
        Note(type: .aFlat, octave: 3),
        Note(type: .dFlat, octave: 4)
      ]
    case .bFlat:
      return [
        Note(type: .bFlat, octave: 1),
        Note(type: .eFlat, octave: 2),
        Note(type: .aFlat, octave: 2),
        Note(type: .dFlat, octave: 3),
        Note(type: .f, octave: 3),
        Note(type: .bFlat, octave: 3)
      ]
    case .baritone:
      return [
        Note(type: .a, octave: 1),
        Note(type: .d, octave: 2),
        Note(type: .g, octave: 2),
        Note(type: .c, octave: 3),
        Note(type: .e, octave: 3),
        Note(type: .a, octave: 3)
      ]
    case .dadddd:
      return [
        Note(type: .d, octave: 2),
        Note(type: .a, octave: 2),
        Note(type: .d, octave: 3),
        Note(type: .d, octave: 3),
        Note(type: .d, octave: 4),
        Note(type: .d, octave: 4)
      ]
    case .cgdgbd:
      return [
        Note(type: .c, octave: 2),
        Note(type: .g, octave: 2),
        Note(type: .d, octave: 3),
        Note(type: .g, octave: 3),
        Note(type: .b, octave: 3),
        Note(type: .d, octave: 4)
      ]
    case .cgdgbe:
      return [
        Note(type: .c, octave: 2),
        Note(type: .g, octave: 2),
        Note(type: .d, octave: 3),
        Note(type: .g, octave: 3),
        Note(type: .b, octave: 3),
        Note(type: .e, octave: 4)
      ]
    case .dadead:
      return [
        Note(type: .d, octave: 2),
        Note(type: .a, octave: 2),
        Note(type: .d, octave: 3),
        Note(type: .e, octave: 3),
        Note(type: .a, octave: 3),
        Note(type: .d, octave: 4)
      ]
    case .dgdgad:
      return [
        Note(type: .d, octave: 2),
        Note(type: .g, octave: 2),
        Note(type: .d, octave: 3),
        Note(type: .g, octave: 3),
        Note(type: .a, octave: 3),
        Note(type: .d, octave: 4)
      ]
    case .openDSus2:
      return [
        Note(type: .d, octave: 2),
        Note(type: .a, octave: 2),
        Note(type: .d, octave: 3),
        Note(type: .g, octave: 3),
        Note(type: .a, octave: 3),
        Note(type: .d, octave: 4)
      ]
    case .openGSus2:
      return [
        Note(type: .d, octave: 2),
        Note(type: .g, octave: 2),
        Note(type: .d, octave: 3),
        Note(type: .g, octave: 3),
        Note(type: .c, octave: 4),
        Note(type: .d, octave: 4)
      ]
    case .g6:
      return [
        Note(type: .d, octave: 2),
        Note(type: .g, octave: 2),
        Note(type: .d, octave: 3),
        Note(type: .g, octave: 3),
        Note(type: .b, octave: 3),
        Note(type: .e, octave: 4)
      ]
    case .modalG:
      return [
        Note(type: .d, octave: 2),
        Note(type: .g, octave: 2),
        Note(type: .d, octave: 3),
        Note(type: .g, octave: 3),
        Note(type: .c, octave: 4),
        Note(type: .d, octave: 4)
      ]
    case .overtone:
      return [
        Note(type: .c, octave: 3),
        Note(type: .e, octave: 3),
        Note(type: .g, octave: 3),
        Note(type: .bFlat, octave: 3),
        Note(type: .c, octave: 4),
        Note(type: .d, octave: 4)
      ]
    case .pentatonic:
      return [
        Note(type: .a, octave: 2),
        Note(type: .c, octave: 3),
        Note(type: .d, octave: 3),
        Note(type: .e, octave: 3),
        Note(type: .g, octave: 3),
        Note(type: .a, octave: 4)
      ]
    case .minorThriad:
      return [
        Note(type: .c, octave: 3),
        Note(type: .eFlat, octave: 3),
        Note(type: .gFlat, octave: 3),
        Note(type: .a, octave: 3),
        Note(type: .c, octave: 4),
        Note(type: .eFlat, octave: 4)
      ]
    case .majorThriad:
      return [
        Note(type: .c, octave: 3),
        Note(type: .e, octave: 3),
        Note(type: .aFlat, octave: 3),
        Note(type: .c, octave: 4),
        Note(type: .e, octave: 4),
        Note(type: .aFlat, octave: 4)
      ]
    case .allFourths:
      return [
        Note(type: .e, octave: 2),
        Note(type: .a, octave: 2),
        Note(type: .d, octave: 3),
        Note(type: .g, octave: 3),
        Note(type: .c, octave: 4),
        Note(type: .f, octave: 4)
      ]
    case .agumentedFourths:
      return [
        Note(type: .c, octave: 2),
        Note(type: .gFlat, octave: 2),
        Note(type: .c, octave: 3),
        Note(type: .gFlat, octave: 3),
        Note(type: .c, octave: 4),
        Note(type: .gFlat, octave: 4)
      ]
    case .slowMotion:
      return [
        Note(type: .d, octave: 2),
        Note(type: .g, octave: 2),
        Note(type: .d, octave: 3),
        Note(type: .f, octave: 3),
        Note(type: .c, octave: 4),
        Note(type: .d, octave: 4)
      ]
    case .admiral:
      return [
        Note(type: .c, octave: 2),
        Note(type: .g, octave: 2),
        Note(type: .d, octave: 3),
        Note(type: .g, octave: 3),
        Note(type: .b, octave: 3),
        Note(type: .c, octave: 4)
      ]
    case .buzzard:
      return [
        Note(type: .c, octave: 2),
        Note(type: .f, octave: 2),
        Note(type: .c, octave: 3),
        Note(type: .g, octave: 3),
        Note(type: .bFlat, octave: 3),
        Note(type: .f, octave: 4)
      ]
    case .face:
      return [
        Note(type: .c, octave: 2),
        Note(type: .g, octave: 2),
        Note(type: .d, octave: 3),
        Note(type: .g, octave: 3),
        Note(type: .a, octave: 3),
        Note(type: .d, octave: 4)
      ]
    case .fourAndTwenty:
      return [
        Note(type: .d, octave: 2),
        Note(type: .a, octave: 2),
        Note(type: .d, octave: 3),
        Note(type: .d, octave: 3),
        Note(type: .a, octave: 3),
        Note(type: .d, octave: 4)
      ]
    case .ostrich:
      return [
        Note(type: .d, octave: 2),
        Note(type: .d, octave: 3),
        Note(type: .d, octave: 3),
        Note(type: .d, octave: 3),
        Note(type: .d, octave: 4),
        Note(type: .d, octave: 4)
      ]
    case .capo200:
      return [
        Note(type: .c, octave: 2),
        Note(type: .g, octave: 2),
        Note(type: .d, octave: 3),
        Note(type: .eFlat, octave: 3),
        Note(type: .d, octave: 4),
        Note(type: .eFlat, octave: 4)
      ]
    case .balalaika:
      return [
        Note(type: .e, octave: 2),
        Note(type: .a, octave: 2),
        Note(type: .d, octave: 3),
        Note(type: .e, octave: 3),
        Note(type: .e, octave: 3),
        Note(type: .a, octave: 3)
      ]
    case .charango:
      return [
        Note(type: .g, octave: 2),
        Note(type: .c, octave: 3),
        Note(type: .e, octave: 3),
        Note(type: .a, octave: 3),
        Note(type: .e, octave: 4)
      ]
    case .citternOne:
      return [
        Note(type: .c, octave: 2),
        Note(type: .f, octave: 2),
        Note(type: .c, octave: 3),
        Note(type: .g, octave: 3),
        Note(type: .c, octave: 4),
        Note(type: .d, octave: 4)
      ]
    case .citternTwo:
      return [
        Note(type: .c, octave: 2),
        Note(type: .g, octave: 2),
        Note(type: .c, octave: 3),
        Note(type: .g, octave: 3),
        Note(type: .c, octave: 4),
        Note(type: .g, octave: 4)
      ]
    case .dobro:
      return [
        Note(type: .g, octave: 2),
        Note(type: .b, octave: 2),
        Note(type: .d, octave: 3),
        Note(type: .g, octave: 3),
        Note(type: .b, octave: 3),
        Note(type: .d, octave: 4)
      ]
    case .leftty:
      return [
        Note(type: .e, octave: 4),
        Note(type: .b, octave: 3),
        Note(type: .g, octave: 3),
        Note(type: .d, octave: 3),
        Note(type: .a, octave: 2),
        Note(type: .e, octave: 2)
      ]
    case .mandoguitar:
      return [
        Note(type: .c, octave: 2),
        Note(type: .g, octave: 2),
        Note(type: .d, octave: 3),
        Note(type: .a, octave: 3),
        Note(type: .e, octave: 4),
        Note(type: .b, octave: 4)
      ]
    case .rustyCage:
      return [
        Note(type: .b, octave: 1),
        Note(type: .a, octave: 2),
        Note(type: .d, octave: 3),
        Note(type: .g, octave: 3),
        Note(type: .b, octave: 3),
        Note(type: .e, octave: 4)
      ]
    }
  }

  public var description: String {
    switch self {
    case .standard:
      return "Standard"
    case .dropD:
      return "Drop D"
    case .halfStepDown:
      return "Half Step Down"
    case .fullStepDown:
      return "Full Step Down"
    case .oneAndHalfStepDown:
      return "One and Half Step Down"
    case .doubleDropD:
      return "Double Drop D"
    case .dropC:
      return "Drop C"
    case .dropDFlat:
      return "Drop D♭"
    case .dropB:
      return "Drop B"
    case .dropBFlat:
      return "Drop B♭"
    case .dropA:
      return "Drop A"
    case .openD:
      return "Open D"
    case .openDMinor:
      return "Open D Minor"
    case .openG:
      return "Open G"
    case .openGMinor:
      return "Open G Minor"
    case .openC:
      return "Open C"
    case .openDFlat:
      return "Open D♭"
    case .openCMinor:
      return "Open C Minor"
    case .openE7:
      return "Open E7"
    case .openEMinor7:
      return "Open EMinor7"
    case .openGMajor7:
      return "Open GMajor7"
    case .openAMinor:
      return "Open A Minor"
    case .openAMinor7:
      return "Open AMinor7"
    case .openE:
      return "Open E"
    case .openA:
      return "Open A"
    case .c:
      return "C"
    case .dFlat:
      return "D♭"
    case .bFlat:
      return "B♭"
    case .baritone:
      return "Baritone"
    case .dadddd:
      return "DADDDD"
    case .cgdgbd:
      return "CGDGBD"
    case .cgdgbe:
      return "CGDGBE"
    case .dadead:
      return "DADEAD"
    case .dgdgad:
      return "DGDGAD"
    case .openDSus2:
      return "Open DSus2"
    case .openGSus2:
      return "Open GSus2"
    case .g6:
      return "G6"
    case .modalG:
      return "Modal G"
    case .overtone:
      return "Overtone"
    case .pentatonic:
      return "Pentatonic"
    case .minorThriad:
      return "Minor Thriad"
    case .majorThriad:
      return "Major Thriad"
    case .allFourths:
      return "All Fourths"
    case .agumentedFourths:
      return "Agumented Fourts"
    case .slowMotion:
      return "Slow Motion"
    case .admiral:
      return "Admiral"
    case .buzzard:
      return "Buzzard"
    case .face:
      return "Face"
    case .fourAndTwenty:
      return "Four and Twenty"
    case .ostrich:
      return "Ostrich"
    case .capo200:
      return "Capo 200"
    case .balalaika:
      return "Balalaika"
    case .charango:
      return "Charango"
    case .citternOne:
      return "Cittern One"
    case .citternTwo:
      return "Cittern Two"
    case .dobro:
      return "Dobro"
    case .leftty:
      return "Lefty"
    case .mandoguitar:
      return "Mandoguitar"
    case .rustyCage:
      return "Rusty Cage"
    }
  }
}

extension GuitarTuning {
  public static let all: [GuitarTuning] = [
    .standard,
    .dropD,
    .halfStepDown,
    .fullStepDown,
    .oneAndHalfStepDown,
    .doubleDropD,
    .dropC,
    .dropDFlat,
    .dropB,
    .dropBFlat,
    .dropA,
    .openD,
    .openDMinor,
    .openG,
    .openGMinor,
    .openC,
    .openDFlat,
    .openCMinor,
    .openE7,
    .openEMinor7,
    .openGMajor7,
    .openAMinor,
    .openAMinor7,
    .openE,
    .openA,
    .c,
    .dFlat,
    .bFlat,
    .baritone,
    .dadddd,
    .cgdgbd,
    .cgdgbe,
    .dadead,
    .dgdgad,
    .openDSus2,
    .openGSus2,
    .g6,
    .modalG,
    .overtone,
    .pentatonic,
    .minorThriad,
    .majorThriad,
    .allFourths,
    .agumentedFourths,
    .slowMotion,
    .admiral,
    .buzzard,
    .face,
    .fourAndTwenty,
    .ostrich,
    .capo200,
    .balalaika,
    .charango,
    .citternOne,
    .citternTwo,
    .dobro,
    .leftty,
    .mandoguitar,
    .rustyCage
  ]
}

// MARK: - BassTuning

/// Four, five and six string tunings for bass guitar.
public enum BassTuning: FretboardTuning {
  case standard4String
  case standard5String
  case standard6String
  case dropD4String
  case dropB4String
  case openA4String
  case openE4String
  case e7sus44string
  case gsus44String
  case tenor4String
  case piccolo4String
  case halfStepDown4String
  case halfStepDown5String
  case halfStepDown6String
  case fullStepDown4String
  case fullStepDown5String
  case eadgcf6String
  case fbeadg6String
  case standard7String
  case fbeadgc7String
  case standard8String

  public var strings: [Note] {
    switch self {
    case .standard4String:
      return [
        Note(type: .e, octave: 1),
        Note(type: .a, octave: 1),
        Note(type: .d, octave: 2),
        Note(type: .g, octave: 2),
      ]
    case .standard5String:
      return [
        Note(type: .b, octave: 0),
        Note(type: .e, octave: 1),
        Note(type: .a, octave: 1),
        Note(type: .d, octave: 2),
        Note(type: .g, octave: 2),
      ]
    case .standard6String:
      return [
        Note(type: .b, octave: 0),
        Note(type: .e, octave: 1),
        Note(type: .a, octave: 1),
        Note(type: .d, octave: 2),
        Note(type: .g, octave: 2),
        Note(type: .c, octave: 3),
      ]
    case .dropD4String:
      return [
        Note(type: .d, octave: 1),
        Note(type: .a, octave: 1),
        Note(type: .d, octave: 2),
        Note(type: .g, octave: 2),
      ]
    case .dropB4String:
      return [
        Note(type: .d, octave: 1),
        Note(type: .a, octave: 1),
        Note(type: .d, octave: 2),
        Note(type: .g, octave: 2),
      ]
    case .openA4String:
      return [
        Note(type: .e, octave: 1),
        Note(type: .a, octave: 1),
        Note(type: .e, octave: 2),
        Note(type: .a, octave: 2),
      ]
    case .openE4String:
      return [
        Note(type: .e, octave: 1),
        Note(type: .b, octave: 1),
        Note(type: .e, octave: 2),
        Note(type: .aFlat, octave: 2),
      ]
    case .e7sus44string:
      return [
        Note(type: .b, octave: 1),
        Note(type: .e, octave: 1),
        Note(type: .a, octave: 2),
        Note(type: .d, octave: 2),
      ]
    case .gsus44String:
      return [
        Note(type: .d, octave: 1),
        Note(type: .a, octave: 1),
        Note(type: .d, octave: 2),
        Note(type: .g, octave: 2),
      ]
    case .tenor4String:
      return [
        Note(type: .a, octave: 1),
        Note(type: .d, octave: 1),
        Note(type: .g, octave: 2),
        Note(type: .c, octave: 2),
      ]
    case .piccolo4String:
      return [
        Note(type: .e, octave: 2),
        Note(type: .a, octave: 2),
        Note(type: .d, octave: 3),
        Note(type: .g, octave: 3),
      ]
    case .halfStepDown4String:
      return [
        Note(type: .eFlat, octave: 1),
        Note(type: .aFlat, octave: 1),
        Note(type: .dFlat, octave: 2),
        Note(type: .gFlat, octave: 2),
      ]
    case .halfStepDown5String:
      return[
        Note(type: .bFlat, octave: 0),
        Note(type: .eFlat, octave: 1),
        Note(type: .aFlat, octave: 1),
        Note(type: .dFlat, octave: 2),
        Note(type: .gFlat, octave: 2),
      ]
    case .halfStepDown6String:
      return [
        Note(type: .bFlat, octave: 0),
        Note(type: .eFlat, octave: 1),
        Note(type: .aFlat, octave: 1),
        Note(type: .dFlat, octave: 2),
        Note(type: .gFlat, octave: 2),
        Note(type: .b, octave: 3),
      ]
    case .fullStepDown4String:
      return [
        Note(type: .d, octave: 1),
        Note(type: .g, octave: 1),
        Note(type: .c, octave: 2),
        Note(type: .f, octave: 2),
      ]
    case .fullStepDown5String:
      return [
        Note(type: .a, octave: 0),
        Note(type: .d, octave: 1),
        Note(type: .g, octave: 1),
        Note(type: .c, octave: 2),
        Note(type: .f, octave: 2)
      ]
    case .eadgcf6String:
      return [
        Note(type: .e, octave: 0),
        Note(type: .a, octave: 1),
        Note(type: .d, octave: 1),
        Note(type: .g, octave: 2),
        Note(type: .c, octave: 2),
        Note(type: .f, octave: 3),
      ]
    case .fbeadg6String:
      return [
        Note(type: .gFlat, octave: 0),
        Note(type: .b, octave: 1),
        Note(type: .e, octave: 1),
        Note(type: .a, octave: 2),
        Note(type: .d, octave: 2),
        Note(type: .g, octave: 3),
      ]
    case .standard7String:
      return [
        Note(type: .b, octave: 0),
        Note(type: .e, octave: 1),
        Note(type: .a, octave: 1),
        Note(type: .d, octave: 2),
        Note(type: .g, octave: 2),
        Note(type: .d, octave: 3),
        Note(type: .c, octave: 3),
      ]
    case .fbeadgc7String:
      return [
        Note(type: .gFlat, octave: 0),
        Note(type: .b, octave: 1),
        Note(type: .e, octave: 1),
        Note(type: .a, octave: 2),
        Note(type: .d, octave: 2),
        Note(type: .g, octave: 3),
        Note(type: .c, octave: 3),
      ]
    case .standard8String:
      return [
        Note(type: .gFlat, octave: 0),
        Note(type: .b, octave: 0),
        Note(type: .e, octave: 1),
        Note(type: .a, octave: 1),
        Note(type: .d, octave: 2),
        Note(type: .g, octave: 2),
        Note(type: .c, octave: 3),
        Note(type: .f, octave: 3),
      ]
    }
  }

  public var description: String {
    switch self {
    case .standard4String:
      return "4 String Standard"
    case .standard5String:
      return "5 String Standard"
    case .standard6String:
      return "6 String Standard"
    case .standard7String:
      return "7 String standard"
    case .standard8String:
      return "8 String Standard"
    case .dropD4String:
      return "4 String Drop D"
    case .dropB4String:
      return "4 String Drop B"
    case .openA4String:
      return "4 String Open A"
    case .openE4String:
      return "4 String Open E"
    case .e7sus44string:
      return "4 String E7sus4"
    case .gsus44String:
      return "4 String Gsus4"
    case .tenor4String:
      return "4 String Tenor"
    case .piccolo4String:
      return "4 String Piccolo"
    case .halfStepDown4String:
      return "4 String Half Step Down"
    case .halfStepDown5String:
      return "5 String Half Step Down"
    case .halfStepDown6String:
      return "6 String Half Step Down"
    case .fullStepDown4String:
      return "4 String Full Step Down"
    case .fullStepDown5String:
      return "5 String Full Step Down"
    case .eadgcf6String:
      return "6 String EADGCF"
    case .fbeadg6String:
      return "6 String F#BEADG"
    case .fbeadgc7String:
      return "7 String F#BEADGC"
    }
  }
}

extension BassTuning {
  public static let all: [BassTuning] = [
    .standard4String,
    .standard5String,
    .standard6String,
    .standard7String,
    .standard8String,
    .dropD4String,
    .dropB4String,
    .openA4String,
    .openE4String,
    .e7sus44string,
    .gsus44String,
    .tenor4String,
    .piccolo4String,
    .halfStepDown4String,
    .halfStepDown5String,
    .halfStepDown6String,
    .fullStepDown4String,
    .fullStepDown5String,
    .eadgcf6String,
    .fbeadg6String,
    .fbeadgc7String,
  ]
}

// MARK: UkeleleTuning

/// Four string tunings for ukelele.
public enum UkeleleTuning: FretboardTuning {
  case standard
  case soprano
  case baritone
  case tenor

  public var strings: [Note] {
    switch self {
    case .standard:
      return [
        Note(type: .g, octave: 4),
        Note(type: .c, octave: 4),
        Note(type: .e, octave: 4),
        Note(type: .a, octave: 4)
      ]
    case .soprano:
      return [
        Note(type: .a, octave: 4),
        Note(type: .d, octave: 4),
        Note(type: .gFlat, octave: 4),
        Note(type: .b, octave: 4)
      ]
    case .baritone:
      return [
        Note(type: .d, octave: 3),
        Note(type: .g, octave: 3),
        Note(type: .b, octave: 3),
        Note(type: .e, octave: 4)
      ]
    case .tenor:
      return [
        Note(type: .g, octave: 3),
        Note(type: .c, octave: 4),
        Note(type: .e, octave: 4),
        Note(type: .a, octave: 4)
      ]
    }
  }

  public var description: String {
    switch self {
    case .standard:
      return "Standard"
    case .soprano:
      return "Soprano"
    case .baritone:
      return "Baritone"
    case .tenor:
      return "Tenor"
    }
  }
}

extension UkeleleTuning {
  public static let all: [UkeleleTuning] = [
    .standard,
    .soprano,
    .baritone,
    .tenor
  ]
}

// MARK: CustomTuning

/// Creates custom tuning with any number of string instrument.
public struct CustomTuning: FretboardTuning {
  public var strings: [Note]
  public var description: String

  public init(strings: [Note], description: String) {
    self.strings = strings
    self.description = description
  }
}
