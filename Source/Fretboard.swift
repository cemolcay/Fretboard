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
import CenterTextLayer

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

#if os(OSX)
  public extension NSBezierPath {
    public var cgPath: CGPath {
      let path = CGMutablePath()
      var points = [CGPoint](repeating: .zero, count: 3)

      for i in 0 ..< self.elementCount {
        let type = self.element(at: i, associatedPoints: &points)
        switch type {
        case .moveToBezierPathElement:
          path.move(to: points[0])
        case .lineToBezierPathElement:
          path.addLine(to: points[0])
        case .curveToBezierPathElement:
          path.addCurve(to: points[2], control1: points[0], control2: points[1])
        case .closePathBezierPathElement:
          path.closeSubpath()
        }
      }

      return path
    }

    public func addLine(to: CGPoint) {
      line(to: to)
    }
  }
#endif

// MARK: - Fretboard

public func ==(left: FretboardNote, right: FretboardNote) -> Bool {
  return left.note == right.note &&
    left.stringIndex == right.stringIndex &&
    left.fretIndex == right.fretIndex &&
    left.isSelected == right.isSelected
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
        Note(type: .e, octave: 4),
        Note(type: .b, octave: 3),
        Note(type: .g, octave: 3),
        Note(type: .d, octave: 3),
        Note(type: .a, octave: 2),
        Note(type: .e, octave: 2),
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
      notes = getNotes()
      delegate?.fretboard(self, didChange: notes)
    }
  }

  /// Fret count. Defaults 5.
  public var count: Int {
    didSet {
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
  private func getNotes() -> [FretboardNote] {
    var notes: [FretboardNote] = []
    for (stringIndex, string) in tuning.strings.enumerated() {
      for (fretIndex, fret) in (startIndex..<startIndex + count).enumerated() {
        notes.append(FretboardNote(
          note: string + fret,
          fretIndex: fretIndex,
          stringIndex: stringIndex))
      }
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

// MARK: - FretView

public enum FretNoteType {
  case `default`
  case capoStart
  case capo
  case capoEnd
  case none
}

@IBDesignable
public class FretView: FRView {

  /// `FretboardNote` on fretboard.
  public var note: FretboardNote

  /// Direction of fretboard.
  public var direction: FretboardDirection = .horizontal

  /// Note drawing style if it is pressed.
  public var noteType: FretNoteType = .none

  /// Note drawing offset from edges.
  public var noteOffset: CGFloat = 5

  /// If its 0th fret, than it is an open string, which is not a fret technically but represented as a FretView.
  public var isOpenString: Bool = false

  /// Draws the selected note on its text layer.
  public var isDrawSelectedNoteText: Bool = false

  /// When we are on chordMode, we check the if capo on the fret to detect chords.
  public var isCapoOn: Bool = false

  /// Shape layer that strings draws on.
  public var stringLayer = CAShapeLayer()

  /// Shape layer that frets draws on.
  public var fretLayer = CAShapeLayer()

  /// Shape layer that notes draws on.
  public var noteLayer = CAShapeLayer()

  /// Text layer that notes writes on.
  public var textLayer = CenterTextLayer()

  /// `textLayer` color that note text draws on.
  public var textColor = FRColor.white.cgColor

  // MARK: Init

  public init(note: FretboardNote) {
    self.note = note
    super.init(frame: .zero)
    setup()
  }
  
  required public init?(coder: NSCoder) {
    note = FretboardNote(note: Note(midiNote: 0), fretIndex: 0, stringIndex: 0)
    super.init(coder: coder)
    setup()
  }

  // MARK: Lifecycle

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

  private func setup() {
    #if os(OSX)
      wantsLayer = true
      guard let layer = layer else { return }
    #endif
    layer.addSublayer(stringLayer)
    layer.addSublayer(fretLayer)
    layer.addSublayer(noteLayer)
    layer.addSublayer(textLayer)
  }

  // MARK: Draw

  private func draw() {
    #if os(OSX)
      guard let layer = layer else { return }
    #endif
    CATransaction.setDisableActions(true)

    // FretLayer
    fretLayer.frame = layer.bounds
    let fretPath = FRBezierPath()

    switch direction {
    case .horizontal:
      fretPath.move(to: CGPoint(x: fretLayer.frame.maxX, y: fretLayer.frame.minY))
      fretPath.addLine(to: CGPoint(x: fretLayer.frame.maxX, y: fretLayer.frame.maxY))
    case .vertical:
      #if os(iOS) || os(tvOS)
        fretPath.move(to: CGPoint(x: fretLayer.frame.minX, y: fretLayer.frame.maxY))
        fretPath.addLine(to: CGPoint(x: fretLayer.frame.maxX, y: fretLayer.frame.maxY))
      #elseif os(OSX)
        fretPath.move(to: CGPoint(x: fretLayer.frame.minX, y: fretLayer.frame.minY))
        fretPath.addLine(to: CGPoint(x: fretLayer.frame.maxX, y: fretLayer.frame.minY))
      #endif
    }

    fretLayer.path = fretPath.cgPath

    // StringLayer
    stringLayer.frame = layer.bounds
    let stringPath = FRBezierPath()

    if !isOpenString { // Don't draw strings on fret 0 because it is open string.
      switch direction {
      case .horizontal:
        stringPath.move(to: CGPoint(x: stringLayer.frame.minX, y: stringLayer.frame.midY))
        stringPath.addLine(to: CGPoint(x: stringLayer.frame.maxX, y: stringLayer.frame.midY))
      case .vertical:
        stringPath.move(to: CGPoint(x: stringLayer.frame.midX, y: stringLayer.frame.minY))
        stringPath.addLine(to: CGPoint(x: stringLayer.frame.midX, y: stringLayer.frame.maxY))
      }
    }

    stringLayer.path = stringPath.cgPath

    // NoteLayer
    noteLayer.frame = layer.bounds

    let noteSize = max(min(noteLayer.frame.size.width, noteLayer.frame.size.height) - noteOffset, 0)
    var notePath = FRBezierPath()

    switch noteType {
    case .none:
      break

    case .capo:
      switch direction {
      case .horizontal:
        #if os(iOS) || os(tvOS)
          notePath = UIBezierPath(rect: CGRect(
            x: noteLayer.frame.midX - (noteSize / 2),
            y: noteLayer.frame.minY,
            width: noteSize,
            height: noteLayer.frame.size.height))
        #elseif os(OSX)
          notePath.appendRect(CGRect(
            x: noteLayer.frame.midX - (noteSize / 2),
            y: noteLayer.frame.minY,
            width: noteSize,
            height: noteLayer.frame.size.height))
        #endif
      case .vertical:
        #if os(iOS) || os(tvOS)
          notePath = UIBezierPath(rect: CGRect(
            x: noteLayer.frame.minX,
            y: noteLayer.frame.midY - (noteSize / 2),
            width: noteLayer.frame.size.width,
            height: noteSize))
        #elseif os(OSX)
          notePath.appendRect(CGRect(
            x: noteLayer.frame.minX,
            y: noteLayer.frame.midY - (noteSize / 2),
            width: noteLayer.frame.size.width,
            height: noteSize))
        #endif
      }

    case .capoStart:
      switch direction {
      case .horizontal:
        #if os(iOS) || os(tvOS)
          notePath = UIBezierPath(rect: CGRect(
            x: noteLayer.frame.midX - (noteSize / 2),
            y: noteLayer.frame.midY,
            width: noteSize,
            height: noteLayer.frame.size.height / 2))
          let cap = UIBezierPath(ovalIn: CGRect(
            x: noteLayer.frame.midX - (noteSize / 2),
            y: noteLayer.frame.midY - (noteSize / 2),
            width: noteSize,
            height: noteSize))
          notePath.append(cap)
        #elseif os(OSX)
          notePath.appendOval(in: CGRect(
            x: noteLayer.frame.midX - (noteSize / 2),
            y: noteLayer.frame.midY - (noteSize / 2),
            width: noteSize,
            height: noteSize))
          notePath.appendRect(CGRect(
            x: noteLayer.frame.midX - (noteSize / 2),
            y: noteLayer.frame.minY,
            width: noteSize,
            height: noteLayer.frame.size.height / 2))
        #endif
      case .vertical:
        #if os(iOS) || os(tvOS)
          notePath = UIBezierPath(rect: CGRect(
            x: noteLayer.frame.midX,
            y: noteLayer.frame.midY - (noteSize / 2),
            width: noteLayer.frame.size.width / 2,
            height: noteSize))
          let cap = UIBezierPath(ovalIn: CGRect(
            x: noteLayer.frame.midX - (noteSize / 2),
            y: noteLayer.frame.midY - (noteSize / 2),
            width: noteSize,
            height: noteSize))
          notePath.append(cap)
        #elseif os(OSX)
          notePath.appendOval(in: CGRect(
            x: noteLayer.frame.midX - (noteSize / 2),
            y: noteLayer.frame.midY - (noteSize / 2),
            width: noteSize,
            height: noteSize))
          notePath.appendRect(CGRect(
            x: noteLayer.frame.midX,
            y: noteLayer.frame.midY - (noteSize / 2),
            width: noteLayer.frame.size.width / 2,
            height: noteSize))
        #endif
      }

    case .capoEnd:
      switch direction {
      case .horizontal:
        #if os(iOS) || os(tvOS)
          notePath = UIBezierPath(rect: CGRect(
            x: noteLayer.frame.midX - (noteSize / 2),
            y: noteLayer.frame.minY,
            width: noteSize,
            height: noteLayer.frame.size.height / 2))
          let cap = UIBezierPath(ovalIn: CGRect(
            x: noteLayer.frame.midX - (noteSize / 2),
            y: noteLayer.frame.midY - (noteSize / 2),
            width: noteSize,
            height: noteSize))
          notePath.append(cap)
        #elseif os(OSX)
          notePath.appendOval(in: CGRect(
            x: noteLayer.frame.midX - (noteSize / 2),
            y: noteLayer.frame.midY - (noteSize / 2),
            width: noteSize,
            height: noteSize))
          notePath.appendRect(CGRect(
            x: noteLayer.frame.midX - (noteSize / 2),
            y: noteLayer.frame.midY,
            width: noteSize,
            height: noteLayer.frame.size.height / 2))
        #endif
      case .vertical:
        #if os(iOS) || os(tvOS)
          notePath = UIBezierPath(rect: CGRect(
            x: noteLayer.frame.minX,
            y: noteLayer.frame.midY - (noteSize / 2),
            width: noteLayer.frame.size.width / 2,
            height: noteSize))
          let cap = UIBezierPath(ovalIn: CGRect(
            x: noteLayer.frame.midX - (noteSize / 2),
            y: noteLayer.frame.midY - (noteSize / 2),
            width: noteSize,
            height: noteSize))
          notePath.append(cap)
        #elseif os(OSX)
          notePath.appendOval(in: CGRect(
            x: noteLayer.frame.midX - (noteSize / 2),
            y: noteLayer.frame.midY - (noteSize / 2),
            width: noteSize,
            height: noteSize))
          notePath.appendRect(CGRect(
            x: noteLayer.frame.minX,
            y: noteLayer.frame.midY - (noteSize / 2),
            width: noteLayer.frame.size.width / 2,
            height: noteSize))
        #endif
      }

    default:
      #if os(iOS) || os(tvOS)
        notePath = UIBezierPath(ovalIn: CGRect(
          x: noteLayer.frame.midX - (noteSize / 2),
          y: noteLayer.frame.midY - (noteSize / 2),
          width: noteSize,
          height: noteSize))
      #elseif os(OSX)
        notePath.appendOval(in: CGRect(
          x: noteLayer.frame.midX - (noteSize / 2),
          y: noteLayer.frame.midY - (noteSize / 2),
          width: noteSize,
          height: noteSize))
      #endif
    }

    noteLayer.path = notePath.cgPath

    // TextLayer
    let noteText = NSAttributedString(
      string: "\(note.note.type)",
      attributes: [
        NSForegroundColorAttributeName: textColor,
        NSFontAttributeName: FRFont.systemFont(ofSize: noteSize / 2)
      ])

    textLayer.alignmentMode = kCAAlignmentCenter
    textLayer.string = isDrawSelectedNoteText && note.isSelected ? noteText : nil
    textLayer.frame = layer.bounds
  }
}

// MARK: - FretboardView

@IBDesignable
public class FretboardView: FRView, FretboardDelegate {
  public var fretboard = Fretboard()

  @IBInspectable public var isDrawNoteName: Bool = true { didSet { redraw() }}
  @IBInspectable public var isDrawFretNumber: Bool = true { didSet { redraw() }}
  @IBInspectable public var isChordModeOn: Bool = false { didSet { redraw() }}
  @IBInspectable public var fretWidth: CGFloat = 5 { didSet { redraw() }}
  @IBInspectable public var stringWidth: CGFloat = 0.5 { didSet { redraw() }}

  #if os(iOS) || os(tvOS)
    @IBInspectable public var stringColor: UIColor = .black { didSet { redraw() }}
    @IBInspectable public var fretColor: UIColor = .darkGray { didSet { redraw() }}
    @IBInspectable public var noteColor: UIColor = .black { didSet { redraw() }}
    @IBInspectable public var noteTextColor: UIColor = .white { didSet { redraw() }}
  #elseif os(OSX)
    @IBInspectable public var stringColor: NSColor = .black { didSet { redraw() }}
    @IBInspectable public var fretColor: NSColor = .darkGray { didSet { redraw() }}
    @IBInspectable public var noteColor: NSColor = .black { didSet { redraw() }}
    @IBInspectable public var noteTextColor: NSColor = .white { didSet { redraw() }}
  #endif

  private var fretViews: [FretView] = []

  // MARK: Init

  #if os(iOS) || os(tvOS)
    public override init(frame: CGRect) {
      super.init(frame: frame)
      setup()
    }
  #elseif os(OSX)
    public override init(frame frameRect: NSRect) {
      super.init(frame: frameRect)
      setup()
    }
  #endif

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }

  // MARK: Lifecycle

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

  private func setup() {
    // Clear FretViews
    fretViews.flatMap({ $0 }).forEach({ $0.removeFromSuperview() })
    fretViews = []

    // Create FretViews
    fretboard.notes.forEach{ fretViews.append(FretView(note: $0)) }
    fretViews.flatMap({ $0 }).forEach({ addSubview($0) })

    // Set FretboardDelegate
    fretboard.delegate = self
  }

  // MARK: Draw

  private func draw() {
    let fretSize = CGSize(
      width: frame.size.width / CGFloat(fretboard.direction == .horizontal ? fretboard.count : fretboard.tuning.strings.count),
      height: frame.size.height / CGFloat(fretboard.direction == .horizontal ? fretboard.tuning.strings.count: fretboard.count))

    for (index, fret) in fretViews.enumerated() {
      let fretIndex = fret.note.fretIndex
      let stringIndex = fret.note.stringIndex

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

      // Note type
      let note = fretboard.notes[index]
      if note.isSelected {
        let selectedFrets = fretboard.notes
          .filter({ $0.fretIndex == fretIndex && $0.isSelected })
          .sorted(by: { $0.stringIndex < $1.stringIndex })

        if let selectedIndex = selectedFrets.index(where: { $0 == note }),
          selectedFrets.count > 2 {
          if let first = selectedFrets.first, fret.note == first  {
            let isCapo = selectedFrets[selectedIndex.advanced(by: 1)].stringIndex == note.stringIndex + 1 &&
              selectedFrets[selectedIndex.advanced(by: 2)].stringIndex == note.stringIndex + 2
            fret.noteType = isCapo ? .capoStart : .default
          } else if let last = selectedFrets.last, fret.note == last {
            let isCapo = selectedFrets[selectedIndex.advanced(by: -1)].stringIndex == note.stringIndex - 1 &&
              selectedFrets[selectedIndex.advanced(by: -2)].stringIndex == note.stringIndex - 2
            fret.noteType = isCapo ? .capoEnd : .default
          } else {
            let isCapo = selectedFrets[selectedIndex.advanced(by: 1)].stringIndex == note.stringIndex + 1 &&
              selectedFrets[selectedIndex.advanced(by: -1)].stringIndex == note.stringIndex - 1
            fret.noteType = isCapo ? .capo : .default
          }
        } else {
          fret.noteType = .default
        }

        // Do not draw higher notes on the same string
        if isChordModeOn {
          let selectedNotesOnString = fretboard.notes
            .filter({ $0.stringIndex == stringIndex && $0.isSelected })
            .sorted(by: { $0.fretIndex < $1.fretIndex })
          if selectedNotesOnString.count > 1,
            selectedNotesOnString
              .suffix(from: 2)
              .contains(where: { $0.fretIndex == fretIndex }) {
            fret.noteType = .none
          }
        }
      } else {
        fret.noteType = .none
      }

      fret.note = note
      fret.direction = fretboard.direction
      fret.isOpenString = fretboard.startIndex == 0 && fretIndex == 0
      fret.isDrawSelectedNoteText = isDrawNoteName
      fret.textColor = noteTextColor.cgColor
      fret.stringLayer.strokeColor = stringColor.cgColor
      fret.stringLayer.lineWidth = stringWidth
      fret.fretLayer.strokeColor = fretColor.cgColor
      fret.fretLayer.lineWidth = fretWidth
      fret.noteLayer.fillColor = noteColor.cgColor
      fret.frame = CGRect(origin: position, size: fretSize)
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

  public func fretboard(_ fretboard: Fretboard, didChange: [FretboardNote]) {
    setup()
  }

  public func fretboard(_ fretboard: Fretboard, didDirectionChange: FretboardDirection) {
    redraw()
  }

  public func fretboad(_ fretboard: Fretboard, didSelectedNotesChange: [FretboardNote]) {
    redraw()
  }

  // MARK: CHord Mode

  private func setupChordMode() {

  }
}
