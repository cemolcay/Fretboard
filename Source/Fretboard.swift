//
//  Fretboard.swift
//  Fretboard
//
//  Created by Cem Olcay on 09/04/2017.
//
//

#if os(iOS) || os(tvOS)
  import UIKit
#elseif os(OSX)
  import AppKit
#endif
import MusicTheorySwift

#if os(iOS) || os(tvOS)
  public typealias FRView = UIView
  public typealias FRColor = UIColor
  public typealias FRFont = UIFont
  public typealias FRBezierPath = UIBezierPath
#elseif os(OSX)
  public typealias FRView = NSView
  public typealias FRColor = NSColor
  public typealias FRFont = NSFont
  public typealias FRBezierPath = NSBezierPath
#endif

/// Describes a note in fretboard.
public struct FretboardNote {
  /// Note that fretboard has.
  public var note: Note

  /// Returns wheater is note currently playing / pressing on fretboard.
  public var isSelected: Bool = false

  /// Initilizes with note value.
  ///
  /// - Parameter note: Note on fretboard.
  public init(note: Note) {
    self.note = note
  }
}

/// Describes open notes of strings from top to bottom.
///
/// - standard: Standard guitar tuning for 6 string guitar.
/// - dropD: Standard drop D guitar tuning for 6 string guitar.
/// - custom: Custom tuning for custom string count. Each note describes a string.
public enum FretboardTuning {
  case standard
  case dropD
  case custom(tuning: [Note])

  /// Strings and their open notes in tuning.
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
      return FretboardTuning.standard.strings.map({ $0 - 1 })
    case .custom(let tuning):
      return tuning
    }
  }
}

/// Direction of fretboard view.
///
/// - horizontal: Horizontal strings, from left to right frets increases.
/// - vertical: Vertical strings, from top to down frets increases.
public enum FretboardDirection {
  case horizontal
  case vertical
}

/// Describes a fretboard with tuning and fret count as well as starting fret and direction of view.
public struct Fretboard {
  /// String count and their notes of open state, tuning. Defaults standard tuning.
  public var tuning: FretboardTuning = .standard

  /// Starting fret number. Defaults 0.
  public var startIndex: Int = 0

  /// Fret count. Defaults 5.
  public var count: Int = 5

  /// Direction of fretboard view. Defaults horizontal.
  public var direction: FretboardDirection = .horizontal

  /// Initilizes fretboard with default values.
  public init() {}

  /// Notes on fretboard horizontally. Left to right frets increases, top to down strings increases.
  public var notes: [[FretboardNote]] {
    var notes: [[FretboardNote]] = []
    for note in tuning.strings {
      var string: [FretboardNote] = []
      for fret in startIndex..<startIndex + count {
        string.append(FretboardNote(note: note + fret))
      }
      notes.append(string)
    }
    return notes
  }
}
