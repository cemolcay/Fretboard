//
//  FretboardView.swift
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
import CenterTextLayer

// MARK: - FretLabel

@IBDesignable
public class FretLabel: FRView {
  public var textLayer = CenterTextLayer()

  // MARK: Init

  #if os(iOS) || os(tvOS)
  public override init(frame: CGRect) {
    super.init(frame: frame)
    textLayer.alignmentMode = CATextLayerAlignmentMode.center
    textLayer.contentsScale = UIScreen.main.scale
    layer.addSublayer(textLayer)
  }
  #elseif os(OSX)
  public override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    wantsLayer = true
    textLayer.alignmentMode = CATextLayerAlignmentMode.center
    textLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 1
    layer?.addSublayer(textLayer)
  }
  #endif

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  // MARK: Lifecycle

  #if os(iOS) || os(tvOS)
  public override func layoutSubviews() {
    super.layoutSubviews()
    textLayer.frame = layer.bounds
  }
  #elseif os(OSX)
  public override func layout() {
    super.layout()
    guard let layer = layer else { return }
    textLayer.frame = layer.bounds
  }
  #endif
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
  public var isDrawSelectedNoteText: Bool = true

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
    note = FretboardNote(note: Pitch(midiNote: 0), fretIndex: 0, stringIndex: 0)
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

    #if os(iOS) || os(tvOS)
      textLayer.contentsScale = UIScreen.main.scale
    #elseif os(OSX)
      textLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 1
    #endif
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
      string: "\(note.note.key)",
      attributes: [
        NSAttributedString.Key.foregroundColor: textColor,
        NSAttributedString.Key.font: FRFont.systemFont(ofSize: noteSize / 2)
      ])

    textLayer.alignmentMode = CATextLayerAlignmentMode.center
    textLayer.string = isDrawSelectedNoteText && note.isSelected ? noteText : nil
    textLayer.frame = layer.bounds
  }
}

// MARK: - FretboardView

@IBDesignable
public class FretboardView: FRView, FretboardDelegate {
  public var fretboard = Fretboard()

  @IBInspectable public var fretStartIndex: Int = 0 { didSet { fretboard.startIndex = fretStartIndex }}
  @IBInspectable public var fretCount: Int = 5 { didSet { fretboard.count = fretCount }}
  @IBInspectable public var direction: String = "horizontal" { didSet { directionDidChange() }}
  @IBInspectable public var isDrawNoteName: Bool = true { didSet { redraw() }}
  @IBInspectable public var isDrawStringName: Bool = true { didSet { redraw() }}
  @IBInspectable public var isDrawFretNumber: Bool = true { didSet { redraw() }}
  @IBInspectable public var isDrawCapo: Bool = true { didSet { redraw() }}
  @IBInspectable public var isChordModeOn: Bool = false { didSet { redraw() }}
  @IBInspectable public var fretWidth: CGFloat = 5 { didSet { redraw() }}
  @IBInspectable public var stringWidth: CGFloat = 0.5 { didSet { redraw() }}

  #if os(iOS) || os(tvOS)
  @IBInspectable public var stringColor: UIColor = .black { didSet { redraw() }}
  @IBInspectable public var fretColor: UIColor = .darkGray { didSet { redraw() }}
  @IBInspectable public var noteColor: UIColor = .black { didSet { redraw() }}
  @IBInspectable public var noteTextColor: UIColor = .white { didSet { redraw() }}
  @IBInspectable public var stringLabelColor: UIColor = .black { didSet { redraw() }}
  @IBInspectable public var fretLabelColor: UIColor = .black { didSet { redraw() }}
  #elseif os(OSX)
  @IBInspectable public var stringColor: NSColor = .black { didSet { redraw() }}
  @IBInspectable public var fretColor: NSColor = .darkGray { didSet { redraw() }}
  @IBInspectable public var noteColor: NSColor = .black { didSet { redraw() }}
  @IBInspectable public var noteTextColor: NSColor = .white { didSet { redraw() }}
  @IBInspectable public var stringLabelColor: NSColor = .black { didSet { redraw() }}
  @IBInspectable public var fretLabelColor: NSColor = .black { didSet { redraw() }}
  #endif

  private var fretViews: [FretView] = []
  private var fretLabels: [FretLabel] = []
  private var stringLabels: [FretLabel] = []

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
    drawNotes()
  }
  #elseif os(OSX)
  public override func layout() {
    super.layout()
    draw()
    drawNotes()
  }
  #endif

  // MARK: Setup

  private func setup() {
    // Create fret views
    fretViews.forEach({ $0.removeFromSuperview() })
    fretViews = []

    fretboard.notes.forEach{ fretViews.append(FretView(note: $0)) }
    fretViews.forEach({ addSubview($0) })

    // Create fret numbers
    fretLabels.forEach({ $0.removeFromSuperview() })
    fretLabels = []
    (0..<fretboard.count).forEach({ _ in fretLabels.append(FretLabel(frame: .zero)) })
    fretLabels.forEach({ addSubview($0) })

    // Create string names
    stringLabels.forEach({ $0.removeFromSuperview() })
    stringLabels = []
    fretboard.tuning.strings.forEach({ _ in stringLabels.append(FretLabel(frame: .zero)) })
    stringLabels.forEach({ addSubview($0) })

    // Set FretboardDelegate
    fretboard.delegate = self
  }

  private func directionDidChange() {
    switch direction {
    case "vertical", "Vertical":
      fretboard.direction = .vertical
    default:
      fretboard.direction = .horizontal
    }
  }

  // MARK: Draw

  private func draw() {
    let gridWidth = frame.size.width / (CGFloat(fretboard.direction == .horizontal ? fretboard.count : fretboard.tuning.strings.count) + 0.5)
    let gridHeight = frame.size.height / (CGFloat(fretboard.direction == .horizontal ? fretboard.tuning.strings.count: fretboard.count) + 0.5)

    // String label size
    var stringLabelSize = CGSize()
    if isDrawStringName {
      let horizontalSize = CGSize(
        width: gridWidth / 2,
        height: gridHeight)

      let verticalSize = CGSize(
        width: gridWidth,
        height: gridHeight / 2)

      stringLabelSize = fretboard.direction == .horizontal ? horizontalSize : verticalSize
    }

    // Fret label size
    var fretLabelSize = CGSize()
    if isDrawFretNumber {
      let horizontalSize = CGSize(
        width: (frame.size.width - stringLabelSize.width) / CGFloat(fretboard.direction == .horizontal ? fretboard.count : fretboard.tuning.strings.count),
        height: gridHeight / 2)

      let verticalSize = CGSize(
        width: gridWidth / 2,
        height: (frame.size.height - stringLabelSize.height) / CGFloat(fretboard.direction == .horizontal ? fretboard.tuning.strings.count : fretboard.count))

      fretLabelSize = fretboard.direction == .horizontal ? horizontalSize : verticalSize
    }

    // Fret view size
    let horizontalSize = CGSize(
      width: (frame.size.width - stringLabelSize.width) / CGFloat(fretboard.count),
      height: (frame.size.height - fretLabelSize.height) / CGFloat(fretboard.tuning.strings.count))

    let verticalSize = CGSize(
      width: (frame.size.width - fretLabelSize.width) / CGFloat(fretboard.tuning.strings.count),
      height: (frame.size.height - stringLabelSize.height) / CGFloat(fretboard.count))

    var fretSize = fretboard.direction == .horizontal ? horizontalSize : verticalSize

    // Layout string labels
    for (index, label) in stringLabels.enumerated() {
      var position = CGPoint()
      switch fretboard.direction {
      case .horizontal:
        #if os(iOS) || os(tvOS)
          position.y = stringLabelSize.height * CGFloat(index)
        #elseif os(OSX)
          position.y = frame.size.height - stringLabelSize.height - (stringLabelSize.height * CGFloat(index))
        #endif
      case .vertical:
        position.x = stringLabelSize.width * CGFloat(index) + fretLabelSize.width
      }

      label.textLayer.string = NSAttributedString(
        string: "\(fretboard.strings[index].key)",
        attributes: [
          NSAttributedString.Key.foregroundColor: stringLabelColor,
          NSAttributedString.Key.font: FRFont.systemFont(ofSize: (min(stringLabelSize.width, stringLabelSize.height) * 2) / 3)
        ])
      label.frame = CGRect(origin: position, size: stringLabelSize)
    }

    // Layout fret labels
    for (index, label) in fretLabels.enumerated() {
      var position = CGPoint()
      switch fretboard.direction {
      case .horizontal:
        position.x = (fretLabelSize.width * CGFloat(index)) + stringLabelSize.width
        #if os(iOS) || os(tvOS)
          position.y = frame.size.height - fretLabelSize.height
        #endif
      case .vertical:
        #if os(iOS) || os(tvOS)
          position.y = fretLabelSize.height * CGFloat(index) + stringLabelSize.height
        #elseif os(OSX)
          position.y = frame.size.height - fretLabelSize.height - (fretLabelSize.height * CGFloat(index)) - stringLabelSize.height
        #endif
      }

      if fretboard.startIndex == 0, index == 0 {
        label.textLayer.string = nil
      } else {
        label.textLayer.string = NSAttributedString(
          string: "\(fretboard.startIndex + index)",
          attributes: [
            NSAttributedString.Key.foregroundColor: fretLabelColor,
            NSAttributedString.Key.font: FRFont.systemFont(ofSize: (min(fretLabelSize.width, fretLabelSize.height) * 2) / 3)
          ])
      }
      label.frame = CGRect(origin: position, size: fretLabelSize)
    }

    // Layout fret views
    for (index, fret) in fretViews.enumerated() {
      let fretIndex = fret.note.fretIndex
      let stringIndex = fret.note.stringIndex

      // Position
      var position = CGPoint()
      switch fretboard.direction {
      case .horizontal:
        #if os(iOS) || os(tvOS)
          position.x = fretSize.width * CGFloat(fretIndex) + stringLabelSize.width
          position.y = fretSize.height * CGFloat(stringIndex)
        #elseif os(OSX)
          position.x = fretSize.width * CGFloat(fretIndex) + stringLabelSize.width
          position.y = frame.size.height - fretSize.height - (fretSize.height * CGFloat(stringIndex))
        #endif
      case .vertical:
        #if os(iOS) || os(tvOS)
          position.x = fretSize.width * CGFloat(stringIndex) + fretLabelSize.width
          position.y = fretSize.height * CGFloat(fretIndex) + stringLabelSize.height
        #elseif os(OSX)
          position.x = fretSize.width * CGFloat(stringIndex) + fretLabelSize.width
          position.y = frame.size.height - fretSize.height - (fretSize.height * CGFloat(fretIndex)) - stringLabelSize.height
        #endif
      }

      // Fret options
      fret.note = fretboard.notes[index]
      fret.direction = fretboard.direction
      fret.isOpenString = fretboard.startIndex == 0 && fretIndex == 0
      fret.isDrawSelectedNoteText = isDrawNoteName
      fret.textColor = noteTextColor.cgColor
      fret.stringLayer.strokeColor = stringColor.cgColor
      fret.stringLayer.lineWidth = stringWidth
      fret.fretLayer.strokeColor = fretColor.cgColor
      fret.fretLayer.lineWidth = fretWidth * (fretboard.startIndex == 0 && fretIndex == 0 ? 2 : 1)
      fret.noteLayer.fillColor = noteColor.cgColor
      fret.frame = CGRect(origin: position, size: fretSize)
    }
  }

  private func drawNotes() {
    for (index, fret) in fretViews.enumerated() {
      let fretIndex = fret.note.fretIndex
      let stringIndex = fret.note.stringIndex

      let note = fretboard.notes[index]
      fret.note = note

      if note.isSelected, isDrawCapo {
        // Set note types
        let notesOnFret = fretboard.notes.filter({ $0.fretIndex == fretIndex }).sorted(by: { $0.stringIndex < $1.stringIndex })
        if (notesOnFret[safe: stringIndex-1] == nil || notesOnFret[safe: stringIndex-1]?.isSelected == false),
          notesOnFret[safe: stringIndex+1]?.isSelected == true,
          notesOnFret[safe: stringIndex+2]?.isSelected == true {
          fret.noteType = .capoStart
        } else if (notesOnFret[safe: stringIndex+1] == nil || notesOnFret[safe: stringIndex+1]?.isSelected == false),
          notesOnFret[safe: stringIndex-1]?.isSelected == true,
          notesOnFret[safe: stringIndex-2]?.isSelected == true {
          fret.noteType = .capoEnd
        } else if notesOnFret[safe: stringIndex-1]?.isSelected == true,
          notesOnFret[safe: stringIndex+1]?.isSelected == true {
          fret.noteType = .capo
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
              .suffix(from: 1)
              .contains(where: { $0.fretIndex == fretIndex }) {
            fret.noteType = .none
          }
        }
      } else if note.isSelected, !isDrawCapo {
        fret.noteType = .default
      } else {
        fret.noteType = .none
      }

      #if os(iOS) || os(tvOS)
        fret.setNeedsLayout()
      #elseif os(OSX)
        fret.needsLayout = true
      #endif
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
    drawNotes()
  }
  
  public func fretboard(_ fretboard: Fretboard, didDirectionChange: FretboardDirection) {
    redraw()
  }
  
  public func fretboad(_ fretboard: Fretboard, didSelectedNotesChange: [FretboardNote]) {
    drawNotes()
  }
}

