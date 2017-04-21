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

// MARK: - FretboardNote

public func ==(left: FretboardNote?, right: FretboardNote?) -> Bool {
  switch (left, right) {
  case (.none, .none):
    return true
  case (.some(let left), .some(let right)):
    return left.note == right.note &&
      left.stringIndex == right.stringIndex &&
      left.fretIndex == right.fretIndex
  default:
    return false
  }
}

/// Describes a note in fretboard.
public class FretboardNote {
  /// Note that fretboard has.
  public var note: Note

  /// Index of fret on fretboard.
  public var fretIndex: Int

  /// Index of string on fretboard.
  public var stringIndex: Int

  /// Returns wheater is note currently playing / pressing on fretboard.
  public var isSelected: Bool = false

  /// Initilizes with note value.
  ///
  /// - Parameter note: Note on fretboard.
  public init(note: Note, fretIndex: Int, stringIndex: Int) {
    self.note = note
    self.fretIndex = fretIndex
    self.stringIndex = stringIndex
  }
}

// MARK: FretboardDirection

/// Direction of fretboard view.
///
/// - horizontal: Horizontal strings, from left to right frets increases.
/// - vertical: Vertical strings, from top to down frets increases.
public enum FretboardDirection {
  case horizontal
  case vertical
}

// MARK: Fretboard

/// Informs changes on fretboard.
public protocol FretboardDelegate: class {

  /// Informs `FretboardNotes` changes on fretboard when its `tuning`, `startIndex`, `count` or `notes` changes.
  ///
  /// - Parameters:
  ///   - fretboard: Changed fretboard.
  ///   - didNotesChange: New changed notes.
  func fretboard(_ fretboard: Fretboard, didChange: [FretboardNote])

  /// Informs when `FretboardDirection` changes on fretboard.
  ///
  /// - Parameters:
  ///   - fretboard: Changed fretboard.
  ///   - didDirectionChange: New changed direction.
  func fretboard(_ fretboard: Fretboard, didDirectionChange: FretboardDirection)

  /// Informs when note selection changes on fretboard.
  ///
  /// - Parameters:
  ///   - fretboard: Changed fretboard
  ///   - didSelectedNotesChange: New changed notes.
  func fretboad(_ fretboard: Fretboard, didSelectedNotesChange: [FretboardNote])
}

/// Describes a fretboard with tuning and fret count as well as starting fret and direction of view.
public class Fretboard {
  /// String count and their notes of open state, tuning. Defaults standard tuning.
  public var tuning: FretboardTuning {
    didSet {
      notes = getNotes()
      delegate?.fretboard(self, didChange: notes)
    }
  }

  /// Starting fret number. Fret 0 is open string. Defaults 0.
  public var startIndex: Int {
    didSet {
      if startIndex < 0 {
        startIndex = 0
      }
      notes = getNotes()
      delegate?.fretboard(self, didChange: notes)
    }
  }

  /// Fret count. Defaults 5.
  public var count: Int {
    didSet {
      if count < 1 {
        count = 1
      }
      notes = getNotes()
      delegate?.fretboard(self, didChange: notes)
    }
  }

  /// Direction of fretboard view. Defaults horizontal.
  public var direction: FretboardDirection  { didSet { delegate?.fretboard(self, didDirectionChange: direction) }}

  /// Notes on fretboard horizontally. Left to right frets increases, top to down strings increases.
  public private(set) var notes: [FretboardNote]

  /// Optional delegate that informs changes on fretboard.
  public weak var delegate: FretboardDelegate?

  /// Initilizes fretboard with default values.
  public init(
    tuning: FretboardTuning = GuitarTuning.standard,
    startIndex: Int = 0,
    count: Int = 5,
    direction: FretboardDirection = .horizontal) {

    self.tuning = tuning
    self.startIndex = startIndex
    self.count = count
    self.direction = direction
    self.notes = []
    self.notes = getNotes()
  }

  /// Calculates the notes of fretboard from the current `tuning`, `startIndex` and `count` of fretboard.
  ///
  /// - Returns: Notes of fretboard horizontally, from left to right frets increasing, from top to down strings increasing.
  private func getNotes() -> [FretboardNote] {
    var notes: [FretboardNote] = []
    for (stringIndex, string) in strings.enumerated() {
      for (fretIndex, fret) in (startIndex..<startIndex + count).enumerated() {
        notes.append(FretboardNote(
          note: string + fret,
          fretIndex: fretIndex,
          stringIndex: stringIndex))
      }
    }
    return notes
  }

  /// Returns tuned strings by its direction.
  /// Left to right higher pitches in vertical direction.
  /// Bottom to top higer pitches in horizontal direction.
  var strings: [Note] {
    return direction == .horizontal ? tuning.strings.reversed() : tuning.strings
  }

  /// Returns sorted octave range in fretboard.
  public var octaves: [Int] {
    return Set<Int>(notes.flatMap({ $0 }).map({ $0.note.octave })).sorted()
  }

  // MARK: Note Selection

  /// Marks selected the notes in fretboard.
  ///
  /// - Parameter note: To be selected note in fretboard.
  public func select(note: Note) {
    notes.filter({ $0.note == note }).forEach({ $0.isSelected = true })
    delegate?.fretboad(self, didSelectedNotesChange: notes)
  }

  /// Marks the notes selected in fretboard
  ///
  /// - Parameter notes: Notes to be selected.
  public func select(notes: [Note]) {
    let hasNote: (FretboardNote) -> Bool = { fret in
      return notes.contains(where: { $0 == fret.note })
    }

    self.notes.filter(hasNote).forEach({ $0.isSelected = true })
    delegate?.fretboad(self, didSelectedNotesChange: self.notes)
  }

  /// Marks selected the notes of chord in fretboard.
  ///
  /// - Parameter chord: To be selected notes of chord in fretboard.
  public func select(chord: Chord) {
    let notes = chord.notes(octaves: octaves)
    let hasNote: (Note) -> Bool = { note in
      return notes.contains(where: { $0 == note })
    }

    self.notes.forEach{ $0.isSelected = hasNote($0.note) }
    delegate?.fretboad(self, didSelectedNotesChange: self.notes)
  }

  /// Marks selected the notes of scale in fretboard.
  ///
  /// - Parameter scale: To be selected notes of scale in fretboard.
  public func select(scale: Scale) {
    let notes = scale.notes(octaves: octaves)
    let hasNote: (Note) -> Bool = { note in
      return notes.contains(where: { $0 == note })
    }

    self.notes.forEach{ $0.isSelected = hasNote($0.note) }
    delegate?.fretboad(self, didSelectedNotesChange: self.notes)
  }

  /// Marks unselect the notes in fretboard if its already selected.
  ///
  /// - Parameter note: To be unselected note in fretboard.
  public func unselect(note: Note) {
    notes.filter({ $0.note == note }).forEach({ $0.isSelected = false })
    delegate?.fretboad(self, didSelectedNotesChange: notes)
  }

  /// Marks unselect all notes in fretboard.
  public func unselectAll() {
    notes.forEach{ $0.isSelected = false }
    delegate?.fretboad(self, didSelectedNotesChange: notes)
  }
}
