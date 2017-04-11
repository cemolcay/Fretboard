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

// MARK: - Fretboard

/// Describes a note in fretboard.
public class FretboardNote {
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

/// Two dimensional `FretboardNote` array that represents note on horizontal fretboard, from top to down strings increasing, from left ro right frets increasing.
public typealias FretboardNotes = [[FretboardNote]]

/// Informs changes on fretboard.
public protocol FretboardDelegate: class {
  /// Informs `FretboardNotes` changes on fretboard.
  ///
  /// - Parameters:
  ///   - fretboard: Changed fretboard.
  ///   - didNotesChange: New changed notes.
  func fretboard(_ fretboard: Fretboard, didNotesChange: FretboardNotes)

  /// Informs `FretboardDirection` changes on fretboard.
  ///
  /// - Parameters:
  ///   - fretboard: Changed fretboard.
  ///   - didDirectionChange: New changed direction.
  func fretboard(_ fretboard: Fretboard, didDirectionChange: FretboardDirection)
}

/// Describes a fretboard with tuning and fret count as well as starting fret and direction of view.
public class Fretboard {
  /// String count and their notes of open state, tuning. Defaults standard tuning.
  public var tuning: FretboardTuning { didSet { notes = getNotes() }}

  /// Starting fret number. Defaults 0.
  public var startIndex: Int { didSet { notes = getNotes() }}

  /// Fret count. Defaults 5.
  public var count: Int { didSet { notes = getNotes() }}

  /// Direction of fretboard view. Defaults horizontal.
  public var direction: FretboardDirection  { didSet { delegate?.fretboard(self, didDirectionChange: direction) }}

  /// Notes on fretboard horizontally. Left to right frets increases, top to down strings increases.
  public private(set) var notes: FretboardNotes { didSet { delegate?.fretboard(self, didNotesChange: notes) }}

  /// Optional delegate that informs changes on fretboard.
  public weak var delegate: FretboardDelegate?

  /// Initilizes fretboard with default values.
  public init(
    tuning: FretboardTuning = .standard,
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
  private func getNotes() -> [[FretboardNote]] {
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

  /// Returns sorted octave range in fretboard.
  public var octaves: [Int] {
    return Set<Int>(notes.flatMap({ $0 }).map({ $0.note.octave })).sorted()
  }

  // MARK: Note Selection

  /// Marks selected the notes in fretboard.
  ///
  /// - Parameter note: To be selected note in fretboard.
  public func select(note: Note) {
    notes.forEach{ $0.forEach{ $0.isSelected = $0.note == note }}
  }

  /// Marks selected the notes of chord in fretboard.
  ///
  /// - Parameter chord: To be selected notes of chord in fretboard.
  public func select(chord: Chord) {
    unselectAll()
    chord.notes(octaves: octaves).forEach({ self.select(note: $0) })
  }

  /// Marks selected the notes of scale in fretboard.
  ///
  /// - Parameter scale: To be selected notes of scale in fretboard.
  public func select(scale: Scale) {
    unselectAll()
    scale.notes(octaves: octaves).forEach({ self.select(note: $0) })
  }

  /// Marks unselect the notes in fretboard if its already selected.
  ///
  /// - Parameter note: To be unselected note in fretboard.
  public func unselect(note: Note) {
    notes.forEach{ $0.forEach{ $0.isSelected = $0.note == note && $0.isSelected ? false : $0.isSelected }}
  }

  /// Marks unselect all notes in fretboard.
  public func unselectAll() {
    notes.forEach{ $0.forEach{ $0.isSelected = false }}
  }
}

// MARK: - FretboardView

internal class FretboardNoteView: FRView {
  var note: FretboardNote

  // MARK: Init

  public init(note: FretboardNote) {
    self.note = note
    super.init(frame: .zero)

    #if os(OSX)
      wantsLayer = true
    #endif
  }
  
  required public init?(coder: NSCoder) {
    note = FretboardNote(note: Note(midiNote: 0))
    super.init(coder: coder)
  }

  // MARK: Draw

  #if os(iOS) || os(tvOS)
    public override func draw(_ rect: CGRect) {
      super.draw(rect)
      draw()
    }
  #elseif os(OSX)
    public override func draw(_ dirtyRect: NSRect) {
      super.draw(dirtyRect)
      draw()
    }
  #endif

  private func draw() {
    #if os(OSX)
      guard let layer = layer else { return }
    #endif

    layer.borderWidth = 1
    layer.borderColor = FRColor.black.cgColor

    let textLayer = CATextLayer()
    textLayer.frame = layer.bounds
    textLayer.alignmentMode = kCAAlignmentCenter
    textLayer.string = NSAttributedString(
      string: "\(note.note)",
      attributes: [
        NSForegroundColorAttributeName: note.isSelected ? FRColor.red.cgColor : FRColor.blue.cgColor,
        NSFontAttributeName: FRFont.systemFont(ofSize: 15)
      ])
    layer.addSublayer(textLayer)
  }
}

@IBDesignable
public class FretboardView: FRView, FretboardDelegate {
  public var fretboard = Fretboard()

  @IBInspectable var isDrawNoteName: Bool = true { didSet { redraw() }}
  @IBInspectable var isDrawFretNumber: Bool = true { didSet { redraw() }}

  #if os(iOS) || os(tvOS)
    @IBInspectable var stringColor: UIColor = .gray { didSet { redraw() }}
    @IBInspectable var fretColor: UIColor = .gray { didSet { redraw() }}
    @IBInspectable var noteColor: UIColor = .gray { didSet { redraw() }}
  #elseif os(OSX)
    @IBInspectable var stringColor: NSColor = .gray { didSet { redraw() }}
    @IBInspectable var fretColor: NSColor = .gray { didSet { redraw() }}
    @IBInspectable var noteColor: NSColor = .gray { didSet { redraw() }}
  #endif

  private var noteViews: [[FretboardNoteView]] = []

  // MARK: Lifecycle

  #if os(iOS) || os(tvOS)
    public override func draw(_ rect: CGRect) {
      super.draw(rect)
      setupFretboard()
    }
  #elseif os(OSX)
    public override func draw(_ dirtyRect: NSRect) {
      super.draw(dirtyRect)
      setupFretboard()
    }
  #endif

  #if os(iOS) || os(tvOS)
    public override func layoutSubviews() {
      super.layoutSubviews()
      draw()
    }
  #elseif os(OSX)
    public override func layout() {
      super.layout()
      draw()
    }
  #endif

  // MARK: Setup 

  private func setupFretboard() {
    fretboard.delegate = self

    // Clear FretboardNoteViews
    noteViews.flatMap({ $0 }).forEach({ $0.removeFromSuperview() })
    noteViews = []

    // Create FretboardNoteViews
    fretboard.notes.forEach{ noteViews.append($0.map{ FretboardNoteView(note: $0) }) }
    noteViews.flatMap({ $0 }).forEach({ addSubview($0) })
  }

  // MARK: Draw

  private func draw() {
    let fretSize = CGSize(
      width: (fretboard.direction == .horizontal ? frame.size.width : frame.size.height) / CGFloat(fretboard.count),
      height: (fretboard.direction == .horizontal ? frame.size.height : frame.size.width) / CGFloat(fretboard.tuning.strings.count))

    for (stringIndex, string) in noteViews.enumerated() {
      for (fretIndex, fret) in string.enumerated() {
        // Position
        var position = CGPoint()
        switch fretboard.direction {
        case .horizontal:
          #if os(iOS) || os(tvOS)
            position.x = fretSize.width * CGFloat(fretIndex)
            position.y = fretSize.height * CGFloat(stringIndex)
          #elseif os(OSX)
            position.x = fretSize.width * CGFloat(fretIndex)
            position.y = frame.size.height - fretSize.height - (fretSize.height * CGFloat(stringIndex))
          #endif
        case .vertical:
          #if os(iOS) || os(tvOS)
            position.x = fretSize.width * CGFloat(stringIndex)
            position.y = fretSize.height * CGFloat(fretIndex)
          #elseif os(OSX)
            position.x = fretSize.width * CGFloat(stringIndex)
            position.y = frame.size.height - fretSize.height - (fretSize.height * CGFloat(fretIndex))
          #endif
        }

        fret.frame = CGRect(origin: position, size: fretSize)
      }
    }
  }

  private func redraw() {
    #if os(iOS) || os(tvOS)
      setNeedsLayout()
    #elseif os(OSX)
      needsLayout = true
    #endif
  }

  // MARK: FretboardDelegate

  public func fretboard(_ fretboard: Fretboard, didNotesChange: FretboardNotes) {
    setupFretboard()
  }

  public func fretboard(_ fretboard: Fretboard, didDirectionChange: FretboardDirection) {
    redraw()
  }
}
