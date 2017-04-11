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

/// Informs changes on fretboard.
public protocol FretboardDelegate: class {

  /// Informs `FretboardNotes` changes on fretboard when its `tuning`, `startIndex` or `count` changes.
  ///
  /// - Parameters:
  ///   - fretboard: Changed fretboard.
  ///   - didNotesChange: New changed notes.
  func fretboard(_ fretboard: Fretboard, didNotesChange: [FretboardNote])

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
      delegate?.fretboard(self, didNotesChange: notes)
    }
  }

  /// Starting fret number. Fret 0 is open string. Defaults 0.
  public var startIndex: Int {
    didSet {
      notes = getNotes()
      delegate?.fretboard(self, didNotesChange: notes)
    }
  }

  /// Fret count. Defaults 5.
  public var count: Int {
    didSet {
      notes = getNotes()
      delegate?.fretboard(self, didNotesChange: notes)
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

@IBDesignable
public class FretView: FRView {

  /// `FretboardNote` on fretboard.
  public var note: FretboardNote

  /// Direction of fretboard.
  public var direction: FretboardDirection = .horizontal

  /// Shape layer that strings draws on.
  public var stringLayer = CAShapeLayer()

  /// Shape layer that frets draws on.
  public var fretLayer = CAShapeLayer()

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

    fretPath.close()
    fretLayer.path = fretPath.cgPath

    // StringLayer
    stringLayer.frame = layer.bounds
    let stringPath = FRBezierPath()

    if note.fretIndex != 0 { // Don't draw strings on fret 0 because it is open string.
      switch direction {
      case .horizontal:
        stringPath.move(to: CGPoint(x: stringLayer.frame.minX, y: stringLayer.frame.midY))
        stringPath.addLine(to: CGPoint(x: stringLayer.frame.maxX, y: stringLayer.frame.midY))
      case .vertical:
        stringPath.move(to: CGPoint(x: stringLayer.frame.midX, y: stringLayer.frame.minY))
        stringPath.addLine(to: CGPoint(x: stringLayer.frame.midX, y: stringLayer.frame.maxY))
      }
    }

    stringPath.close()
    stringLayer.path = stringPath.cgPath
  }
}

// MARK: - FretboardView

@IBDesignable
public class FretboardView: FRView, FretboardDelegate {
  public var fretboard = Fretboard()

  @IBInspectable var isDrawNoteName: Bool = true { didSet { redraw() }}
  @IBInspectable var isDrawFretNumber: Bool = true { didSet { redraw() }}
  @IBInspectable var fretWidth: CGFloat = 4 { didSet { redraw() }}
  @IBInspectable var stringWidth: CGFloat = 2 { didSet { redraw() }}

  #if os(iOS) || os(tvOS)
    @IBInspectable var stringColor: UIColor = .gray { didSet { redraw() }}
    @IBInspectable var fretColor: UIColor = .gray { didSet { redraw() }}
    @IBInspectable var noteColor: UIColor = .gray { didSet { redraw() }}
  #elseif os(OSX)
    @IBInspectable var stringColor: NSColor = .gray { didSet { redraw() }}
    @IBInspectable var fretColor: NSColor = .gray { didSet { redraw() }}
    @IBInspectable var noteColor: NSColor = .gray { didSet { redraw() }}
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

    for fret in fretViews {
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

      fret.direction = fretboard.direction
      fret.stringLayer.strokeColor = stringColor.cgColor
      fret.stringLayer.lineWidth = stringWidth
      fret.fretLayer.strokeColor = fretColor.cgColor
      fret.fretLayer.lineWidth = fretWidth
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

  public func fretboard(_ fretboard: Fretboard, didNotesChange: [FretboardNote]) {
    setup()
  }

  public func fretboard(_ fretboard: Fretboard, didDirectionChange: FretboardDirection) {
    redraw()
  }

  public func fretboad(_ fretboard: Fretboard, didSelectedNotesChange: [FretboardNote]) {
    redraw()
  }
}
