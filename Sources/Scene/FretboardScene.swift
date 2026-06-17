//
//  FretboardScene.swift
//  Fretboard
//
//  Created by Cem Olcay on 11/06/2026.
//

import SpriteKit
import MusicTheory

// MARK: - FretboardSceneDelegate

/// Receives noteOn/noteOff events from the fretboard so the host app can drive a synth or sampler.
/// `noteOn` fires immediately when a finger (or click) touches a fret;
/// `noteOff` fires when that same touch is released or cancelled.
public protocol FretboardSceneDelegate: AnyObject {
    /// A fret was pressed. Connect to your MIDI output or `AVAudioEngine` sampler here.
    func fretboardScene(_ scene: FretboardScene, noteOn note: FretboardNote)
    /// The same fret was released. Send MIDI note-off or stop the sample here.
    func fretboardScene(_ scene: FretboardScene, noteOff note: FretboardNote)
    /// Called just before a touch-press highlight is rendered for `note`.
    /// Return a style (typically just `label:`) to override the highlight appearance.
    /// Return `nil` to use `configuration.highlightNoteStyle`. Default implementation returns `nil`.
    func fretboardScene(_ scene: FretboardScene, highlightStyleFor note: FretboardNote) -> FretboardNoteStyle?
}

public extension FretboardSceneDelegate {
    func fretboardScene(_ scene: FretboardScene, highlightStyleFor note: FretboardNote) -> FretboardNoteStyle? { nil }
}

// MARK: - FretboardGeometry

/// Computed layout geometry for the fretboard; produced by `FretboardScene.layoutContent()`.
///
/// Both dot placement and touch hit-testing use the same geometry, so they can never diverge.
private struct FretboardGeometry {
    let cellSize: CGSize
    let stringGutterSize: CGFloat
    let fretGutterSize: CGFloat
    let cellNeck: CGFloat
    let cellCross: CGFloat
    let contentOffset: CGFloat        // offset along neck axis for alignment
    let crossContentOffset: CGFloat   // offset along cross axis for alignment (e.g. Fit mode)
    let direction: FretboardDirection
    let fretCount: Int
    /// Whether the fret axis is rendered in reverse (nut at the high-coordinate end).
    /// Derived from `fretboard.isFretsFlipped` + `direction` by `layoutContent()`.
    let neckReversed: Bool

    var totalNeckLength: CGFloat { cellNeck * CGFloat(fretCount) }

    /// Maps a measure along the neck (0 = nut, totalNeckLength = last fret line) to a
    /// scene coordinate, applying any reversal and the alignment contentOffset.
    func neckCoordinate(measure: CGFloat) -> CGFloat {
        let m = neckReversed ? totalNeckLength - measure : measure
        return m + contentOffset
    }

    /// Scene-space origin of the cell at (stringIndex, fretIndex).
    func origin(string: Int, fret: Int) -> CGPoint {
        // Derive origin from the cell center so both `origin` and `center` stay consistent.
        let center = center(string: string, fret: fret)
        return CGPoint(x: center.x - cellSize.width / 2, y: center.y - cellSize.height / 2)
    }

    /// Scene-space center of the cell at (stringIndex, fretIndex).
    func center(string: Int, fret: Int) -> CGPoint {
        // Place the center of fret `fret` at the midpoint of its neck-axis slot.
        let neckMeasure = CGFloat(fret) * cellNeck + cellNeck / 2
        let neckPos = neckCoordinate(measure: neckMeasure)
        let crossPos = CGFloat(string) * cellCross + cellCross / 2 + crossContentOffset
        switch direction {
        case .horizontal:
            return CGPoint(x: stringGutterSize + neckPos, y: fretGutterSize + crossPos)
        case .vertical:
            return CGPoint(x: fretGutterSize + crossPos, y: stringGutterSize + neckPos)
        }
    }

    /// Returns the (stringIndex, fretIndex) for `point` in content-node space, or `nil` if outside.
    func cell(at point: CGPoint, stringCount: Int, fretCount: Int) -> (string: Int, fret: Int)? {
        let neckRaw: CGFloat  // raw scene coordinate along the neck axis (no reversal)
        let crossRaw: CGFloat // raw scene coordinate along the cross axis
        switch direction {
        case .horizontal:
            neckRaw = point.x - stringGutterSize
            crossRaw = point.y - fretGutterSize - crossContentOffset
        case .vertical:
            neckRaw = point.y - stringGutterSize
            crossRaw = point.x - fretGutterSize - crossContentOffset
        }

        // Convert the raw neck coordinate to a measure from the nut, accounting for reversal.
        let measure: CGFloat
        if neckReversed {
            measure = totalNeckLength - (neckRaw - contentOffset)
        } else {
            measure = neckRaw - contentOffset
        }

        let fret = Int(measure / cellNeck)
        let string = Int(crossRaw / cellCross)

        guard fret >= 0, fret < fretCount, string >= 0, string < stringCount else { return nil }
        return (string: string, fret: fret)
    }
}

private enum FretboardZPosition {
    static let inlay: CGFloat = 0
    static let neck: CGFloat = 10
    static let labels: CGFloat = 20
    static let notes: CGFloat = 30
}

// MARK: - FretboardScene

/// A SpriteKit scene that renders a `Fretboard` model and handles polyphonic press interactions.
///
/// **Integration:**
/// ```swift
/// let scene = FretboardScene(fretboard: myFretboard)
/// scene.noteDelegate = self
/// skView.presentScene(scene)
/// ```
///
/// After mutating `fretboard` properties, call `scene.reload()` to re-sync the visuals.
///
/// **Showing every matching position for a pitch:**
/// ```swift
/// scene.showPitch(Pitch(noteName: .c, octave: 4))   // all C4s on the neck
/// scene.showPitches(cMajorPitches)
/// scene.hidePitch(...)
/// scene.clearNotes()
/// ```
///
/// **Showing a specific string+fret position (CAGED boxes, chord shapes):**
/// ```swift
/// scene.showNote(specificFretboardNote)          // one exact position
/// scene.showNotes(boxNotes)
/// scene.hideNote(specificFretboardNote)
/// ```
///
/// **Theory conveniences:**
/// ```swift
/// scene.showScale(cMajor)
/// scene.showChord(gMajor)
/// ```
///
/// **Per-note style — degree colors, interval labels, etc.:**
/// ```swift
/// for noteName in scale.noteNames {
///     for pitch in fretboard.octaves.map({ Pitch(noteName: noteName, octave: $0) }) {
///         if let degree = scale.degree(of: noteName) {
///             scene.showPitch(pitch, style: .init(color: degreeColor(degree), label: "\(degree)"))
///         }
///     }
/// }
/// // Scale changed → scene.removeAllNotes(); re-run loop.
/// ```
///
/// **Highlighting (live MIDI / user press):**
/// ```swift
/// scene.highlightPitch(incomingPitch)       // creates a transient dot if none exists
/// scene.unhighlightPitch(incomingPitch)
/// scene.highlightNote(specificPosition)
/// ```
///
/// **Fret inlay markers (app sets positions):**
/// ```swift
/// [3,5,7,9,15,17,19,21].forEach { scene.showFretInlay(at: $0) }
/// [12,24].forEach { scene.showFretInlay(at: $0, .double) }
/// ```
open class FretboardScene: SKScene {

    // MARK: - Public properties

    /// The fretboard model. Assigning a new value automatically calls `reload()`.
    public var fretboard: Fretboard {
        didSet { reload() }
    }

    /// Visual configuration. Assigning a new value automatically calls `reload()`.
    public var configuration: FretboardConfiguration {
        didSet { reload() }
    }

    /// Receives noteOn / noteOff callbacks for playback (distinct from `SKScene.delegate`).
    public weak var noteDelegate: FretboardSceneDelegate?

    // MARK: - Private state

    /// Root node for all fretboard content (slides under the camera for scrolling).
    private let contentNode = SKNode()

    /// Static neck geometry nodes (strings, frets lines, inlay markers).
    private var neckNodes: [SKShapeNode] = []

    /// Gutter label nodes.
    private var stringLabelNodes: [SKLabelNode] = []
    private var fretLabelNodes: [SKLabelNode] = []

    /// On-demand note-dot nodes, keyed by `FretboardNote.id`.
    private var dotNodes: [String: FretNoteNode] = [:]

    /// IDs of dots that exist because `showPitch`/`showNote` was called (the "shown" set).
    private var shownIDs: Set<String> = []

    /// Fret inlay markers requested by the app, keyed by absolute fret number.
    private var fretInlays: [Int: FretInlay] = [:]

    /// SpriteKit nodes for currently rendered fret inlay markers.
    private var inlayNodes: [SKNode] = []

    /// Current layout geometry — updated on every `layoutContent()` call.
    private var geometry: FretboardGeometry?

    /// Controls whether drag gestures scroll the neck (`true`) or glide across notes (`false`).
    /// Updated automatically on every layout — `true` when the neck overflows the scene, `false` when it fits.
    /// Set it explicitly to override: e.g. `isScrollingEnabled = false` to lock glide mode on a long neck.
    public var isScrollingEnabled: Bool = false

    // MARK: - Touch / mouse tracking

    /// Maps a platform touch ID → the `FretboardNote` that was pressed by that touch.
    private var activeTouches: [ObjectIdentifier: FretboardNote] = [:]

    /// Start position of each tracked touch for drag-vs-tap disambiguation.
    private var touchStartPositions: [ObjectIdentifier: CGPoint] = [:]

    /// Touches that have been converted to camera pans (no longer fire noteOff on release).
    private var panningTouches: Set<ObjectIdentifier> = []

    /// Pixel distance a touch must travel before it is treated as a pan rather than a press.
    private let panThreshold: CGFloat = 10

    // MARK: - Camera

    private let fretboardCamera = SKCameraNode()

    // MARK: - Init

    public init(fretboard: Fretboard, configuration: FretboardConfiguration = FretboardConfiguration()) {
        self.fretboard = fretboard
        self.configuration = configuration
        super.init(size: .zero)
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        self.fretboard = Fretboard()
        self.configuration = FretboardConfiguration()
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        scaleMode = .resizeFill
        backgroundColor = configuration.backgroundColor.platformColor
        addChild(contentNode)
        camera = fretboardCamera
        addChild(fretboardCamera)
    }

    // MARK: - Scene lifecycle

    open override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard size.width > 0 && size.height > 0 else { return }
        reload()
    }

    // MARK: - Reload

    /// Re-builds the neck grid from the current `fretboard` and `configuration`, then
    /// re-places all existing note dots at their new positions.
    /// Call this after mutating `fretboard` properties in place.
    public func reload() {
        backgroundColor = configuration.backgroundColor.platformColor
        buildNeckGrid()
        layoutContent()
        repositionDots()
        updateCapoRoles()
    }

    // MARK: - Neck grid

    private func buildNeckGrid() {
        neckNodes.forEach { $0.removeFromParent() }
        neckNodes = []
        stringLabelNodes.forEach { $0.removeFromParent() }
        stringLabelNodes = []
        fretLabelNodes.forEach { $0.removeFromParent() }
        fretLabelNodes = []
        // Nodes are created in layoutContent() once we have sizes.
    }

    // MARK: - Layout

    private func layoutContent() {
        guard size.width > 0 && size.height > 0 else { return }

        let stringCount = fretboard.orderedStrings.count
        let fretCount = fretboard.count
        guard stringCount > 0, fretCount > 0 else { return }

        let showStringLabels = configuration.isDrawStringName
        let showFretLabels = configuration.isDrawFretNumber
        let stringGutterSize: CGFloat = showStringLabels ? 30 : 0
        let fretGutterSize: CGFloat = showFretLabels ? 20 : 0
        let direction = fretboard.direction

        let neckAxisLength: CGFloat
        let crossAxisLength: CGFloat
        switch direction {
        case .horizontal:
            neckAxisLength = size.width - stringGutterSize
            crossAxisLength = size.height - fretGutterSize
        case .vertical:
            neckAxisLength = size.height - stringGutterSize
            crossAxisLength = size.width - fretGutterSize
        }

        let defaultCellCross = crossAxisLength / CGFloat(stringCount)

        // Compute per-fret sizes. `.fit` is handled here (not in FretSizing.fretLength) because
        // it needs the live cross-axis / string-spacing to derive proportional dimensions.
        // `.fit` maintains cellNeck = cellCross * fitAspectRatio, constrained so neither axis
        // overflows, and centers the board in both axes via contentOffset / crossContentOffset.
        let cellNeck: CGFloat
        let cellCross: CGFloat
        switch configuration.fretSizing {
        case .fit:
            let maxNeckFromCross = defaultCellCross * FretSizing.fitAspectRatio
            let maxNeckFromFill = fretCount > 0 ? neckAxisLength / CGFloat(fretCount) : neckAxisLength
            cellNeck = min(maxNeckFromCross, maxNeckFromFill)
            cellCross = cellNeck / FretSizing.fitAspectRatio
        default:
            cellNeck = configuration.fretSizing.fretLength(neckAxisLength: neckAxisLength, count: fretCount)
            cellCross = defaultCellCross
        }

        let totalNeckLength = cellNeck * CGFloat(fretCount)
        let totalCrossLength = cellCross * CGFloat(stringCount)

        let cellWidth: CGFloat
        let cellHeight: CGFloat
        switch direction {
        case .horizontal:
            cellWidth = cellNeck; cellHeight = cellCross
        case .vertical:
            cellWidth = cellCross; cellHeight = cellNeck
        }

        let contentOffset: CGFloat
        switch configuration.fretSizing {
        case .fill:
            // Fill always spans the full neck axis; no offset needed.
            contentOffset = 0
        default:
            let slack = neckAxisLength - totalNeckLength
            switch configuration.alignment {
            case .center:   contentOffset = max(slack / 2, 0)
            case .leading:  contentOffset = 0
            case .trailing: contentOffset = max(slack, 0)
            }
        }

        let crossContentOffset: CGFloat
        switch configuration.fretSizing {
        case .fit:
            crossContentOffset = max((crossAxisLength - totalCrossLength) / 2, 0)
        default:
            crossContentOffset = 0
        }

        // Vertical orientation: leading edge = top, so not-flipped means nut at top → reversed coords.
        // Horizontal orientation: leading edge = left, not-flipped means nut at left → not reversed.
        let neckReversed: Bool
        switch direction {
        case .horizontal: neckReversed = fretboard.isFretsFlipped
        case .vertical:   neckReversed = !fretboard.isFretsFlipped
        }

        geometry = FretboardGeometry(
            cellSize: CGSize(width: cellWidth, height: cellHeight),
            stringGutterSize: stringGutterSize,
            fretGutterSize: fretGutterSize,
            cellNeck: cellNeck,
            cellCross: cellCross,
            contentOffset: contentOffset,
            crossContentOffset: crossContentOffset,
            direction: direction,
            fretCount: fretCount,
            neckReversed: neckReversed
        )

        // ── String lines ──────────────────────────────────────────────────────────
        let geo = geometry!
        for si in 0..<stringCount {
            let crossPos = CGFloat(si) * cellCross + cellCross / 2 + crossContentOffset
            let neckStart = stringGutterSize + geo.neckCoordinate(measure: 0)
            let neckEnd   = stringGutterSize + geo.neckCoordinate(measure: totalNeckLength)
            let path = CGMutablePath()
            switch direction {
            case .horizontal:
                let y = fretGutterSize + crossPos
                path.move(to: CGPoint(x: min(neckStart, neckEnd), y: y))
                path.addLine(to: CGPoint(x: max(neckStart, neckEnd), y: y))
            case .vertical:
                let x = fretGutterSize + crossPos
                path.move(to: CGPoint(x: x, y: min(neckStart, neckEnd)))
                path.addLine(to: CGPoint(x: x, y: max(neckStart, neckEnd)))
            }
            let node = SKShapeNode(path: path)
            node.strokeColor = configuration.stringColor.platformColor
            node.lineWidth = configuration.stringWidth
            node.zPosition = FretboardZPosition.neck
            contentNode.addChild(node)
            neckNodes.append(node)
        }

        // ── Fret lines (including nut) ────────────────────────────────────────────
        for fi in 0...fretCount {
            // The nut is the line at measure 0 when not reversed, or at totalNeckLength when reversed.
            let isNut = fretboard.startIndex == 0 && fi == (neckReversed ? fretCount : 0)
            let lineWidth = isNut ? configuration.fretWidth * configuration.nutWidthMultiplier : configuration.fretWidth

            let neckPos = stringGutterSize + geo.neckCoordinate(measure: CGFloat(fi) * cellNeck)
            let path = CGMutablePath()

            switch direction {
            case .horizontal:
                path.move(to: CGPoint(x: neckPos, y: fretGutterSize + crossContentOffset))
                path.addLine(to: CGPoint(x: neckPos, y: fretGutterSize + crossContentOffset + totalCrossLength))
            case .vertical:
                path.move(to: CGPoint(x: fretGutterSize + crossContentOffset, y: neckPos))
                path.addLine(to: CGPoint(x: fretGutterSize + crossContentOffset + totalCrossLength, y: neckPos))
            }

            let node = SKShapeNode(path: path)
            node.strokeColor = configuration.fretColor.platformColor
            node.lineWidth = lineWidth
            node.zPosition = FretboardZPosition.neck
            contentNode.addChild(node)
            neckNodes.append(node)
        }

        // ── String labels ─────────────────────────────────────────────────────────
        let labelFontSize = min(cellCross, stringGutterSize) * 0.6
        for (i, pitch) in fretboard.orderedStrings.enumerated() {
            let label = SKLabelNode(fontNamed: "Helvetica")
            label.text = pitch.noteName.description
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.fontSize = max(labelFontSize, 8)
            label.fontColor = configuration.stringLabelColor.platformColor
            label.isHidden = !showStringLabels
            label.zPosition = FretboardZPosition.labels

            let crossPos = CGFloat(i) * cellCross + cellCross / 2
            switch direction {
            case .horizontal:
                label.position = CGPoint(x: contentOffset + stringGutterSize / 2, y: fretGutterSize + crossContentOffset + crossPos)
            case .vertical:
                label.position = CGPoint(x: fretGutterSize + crossContentOffset + crossPos, y: contentOffset + stringGutterSize / 2)
            }

            contentNode.addChild(label)
            stringLabelNodes.append(label)
        }

        // ── Fret number labels ────────────────────────────────────────────────────
        let fretLabelFontSize = min(cellNeck, fretGutterSize) * 0.6
        for f in 0..<fretCount {
            let label = SKLabelNode(fontNamed: "Helvetica")
            if fretboard.startIndex == 0 && f == 0 {
                label.text = nil
            } else {
                label.text = "\(fretboard.startIndex + f)"
            }
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.fontSize = max(fretLabelFontSize, 8)
            label.fontColor = configuration.fretLabelColor.platformColor
            label.isHidden = !showFretLabels
            label.zPosition = FretboardZPosition.labels

            let neckPos = stringGutterSize + geo.neckCoordinate(measure: CGFloat(f) * cellNeck + cellNeck / 2)
            switch direction {
            case .horizontal:
                label.position = CGPoint(x: neckPos, y: crossContentOffset + fretGutterSize / 2)
            case .vertical:
                label.position = CGPoint(x: crossContentOffset + fretGutterSize / 2, y: neckPos)
            }

            contentNode.addChild(label)
            fretLabelNodes.append(label)
        }

        // ── Fret inlay markers (app-requested) ───────────────────────────────────
        renderFretInlays()

        // ── Camera ────────────────────────────────────────────────────────────────
        updateCameraConstraints(totalNeckLength: totalNeckLength, neckAxisLength: neckAxisLength,
                                stringGutterSize: stringGutterSize, fretGutterSize: fretGutterSize)
    }

    // MARK: - Dot placement

    /// Re-positions all existing dots after a geometry change.
    private func repositionDots() {
        guard let geo = geometry else { return }
        for (_, dot) in dotNodes {
            dot.position = geo.center(string: dot.note.stringIndex, fret: dot.note.fretIndex)
            dot.cellSize = geo.cellSize
            dot.direction = fretboard.direction
            dot.layout(configuration: configuration)
        }
    }

    /// Creates and places a dot node for `note`. Does not update capo roles.
    ///
    /// Pass `shownStyle` and/or `highlightStyle` to store per-note overrides on the dot before
    /// the initial `layout` call, so the first render already uses the correct style.
    private func makeDot(for note: FretboardNote, transient: Bool,
                         shownStyle: FretboardNoteStyle? = nil,
                         highlightStyle: FretboardNoteStyle? = nil) -> FretNoteNode {
        let dot = FretNoteNode(note: note)
        dot.zPosition = FretboardZPosition.notes
        dot.isTransient = transient
        dot.shownStyle = shownStyle
        dot.highlightStyle = highlightStyle
        if let geo = geometry {
            dot.position = geo.center(string: note.stringIndex, fret: note.fretIndex)
            dot.cellSize = geo.cellSize
            dot.direction = fretboard.direction
        }
        dot.layout(configuration: configuration)
        contentNode.addChild(dot)
        dotNodes[note.id] = dot
        return dot
    }

    // MARK: - Capo role computation

    /// Recomputes capo roles for all dots whose IDs are in `shownIDs` and updates their appearance.
    private func updateCapoRoles() {
        guard configuration.isCapoModeOn else {
            // All dots become .single.
            for dot in dotNodes.values {
                if dot.capoRole != .single {
                    dot.capoRole = .single
                    dot.layout(configuration: configuration)
                }
            }
            return
        }

        // Group shown dots by fret index.
        let shownDots = dotNodes.filter { shownIDs.contains($0.key) }.values
        let byFret = Dictionary(grouping: shownDots, by: { $0.note.fretIndex })

        // Reset all shown dots to .single first.
        for dot in shownDots { dot.capoRole = .single }

        for (_, group) in byFret {
            let sorted = group.sorted { $0.note.stringIndex < $1.note.stringIndex }
            // Find consecutive runs (adjacent string indices with no gap).
            var runStart = 0
            while runStart < sorted.count {
                var runEnd = runStart
                while runEnd + 1 < sorted.count,
                      sorted[runEnd + 1].note.stringIndex == sorted[runEnd].note.stringIndex + 1 {
                    runEnd += 1
                }
                let runLength = runEnd - runStart + 1
                if runLength >= 2 {
                    sorted[runStart].capoRole = .capStart
                    for i in (runStart + 1)..<runEnd {
                        sorted[i].capoRole = .bar
                    }
                    sorted[runEnd].capoRole = .capEnd
                }
                runStart = runEnd + 1
            }
        }

        // Transient (highlight-only) dots are always .single regardless of capo mode.
        for dot in dotNodes.values where dot.isTransient {
            dot.capoRole = .single
        }

        // Re-layout all dots so the new roles take effect.
        for dot in dotNodes.values {
            dot.layout(configuration: configuration)
        }
    }

    // MARK: - Public Marking API — pitch (every matching position)

    /// Shows a dot at every board position whose MIDI note number matches `pitch`.
    ///
    /// An optional `style` overrides specific visual properties for these dots; `nil` fields in
    /// the style fall back to `configuration.noteStyle`, then to the built-in defaults.
    /// If a dot already exists (e.g. a transient highlight), it is promoted to the shown set.
    public func showPitch(_ pitch: Pitch, style: FretboardNoteStyle? = nil) {
        for note in fretboard.notes(matching: pitch) {
            if let existing = dotNodes[note.id] {
                existing.isTransient = false
                existing.shownStyle = style
                existing.layout(configuration: configuration)
                shownIDs.insert(note.id)
            } else {
                let dot = makeDot(for: note, transient: false, shownStyle: style)
                shownIDs.insert(note.id)
                dot.animateShow()
            }
        }
        updateCapoRoles()
    }

    /// Shows dots for each pitch in `pitches`. Convenience for showing a scale or chord.
    ///
    /// The same `style` is applied to every shown dot; pass `nil` for the configuration default.
    public func showPitches(_ pitches: [Pitch], style: FretboardNoteStyle? = nil) {
        for pitch in pitches { showPitch(pitch, style: style) }
    }

    /// Removes the shown dot(s) for `pitch`.
    ///
    /// Highlighted dots become transient and survive until `unhighlightPitch` clears them.
    public func hidePitch(_ pitch: Pitch) {
        for note in fretboard.notes(matching: pitch) {
            shownIDs.remove(note.id)
            guard let dot = dotNodes[note.id] else { continue }
            if dot.isHighlighted {
                dot.isTransient = true
            } else {
                removeDot(id: note.id)
            }
        }
        updateCapoRoles()
    }

    /// Highlights every position matching `pitch`. Creates transient dots where none exist.
    ///
    /// The optional `style` overrides the highlight appearance for these specific dots; `nil`
    /// uses `configuration.highlightNoteStyle`.
    public func highlightPitch(_ pitch: Pitch, style: FretboardNoteStyle? = nil) {
        for note in fretboard.notes(matching: pitch) {
            if let dot = dotNodes[note.id] {
                dot.highlightStyle = style
                dot.isHighlighted = true  // triggers layout via didSet
            } else {
                let dot = makeDot(for: note, transient: true, highlightStyle: style)
                dot.isHighlighted = true  // triggers layout via didSet
                dot.animateShow()
            }
        }
        // Transient dots are excluded from capo merge; no full recompute needed.
    }

    /// Clears the highlight on every position matching `pitch`. Removes transient dots.
    public func unhighlightPitch(_ pitch: Pitch) {
        for note in fretboard.notes(matching: pitch) {
            guard let dot = dotNodes[note.id] else { continue }
            dot.isHighlighted = false
            if dot.isTransient {
                removeDot(id: note.id)
            } else {
                dot.layout(configuration: configuration)
            }
        }
    }

    // MARK: - Public Marking API — note (one exact string + fret position)

    /// Shows a dot at the exact board position described by `note` (one specific string + fret).
    ///
    /// Unlike the pitch-based methods, this marks **one position** rather than every matching
    /// MIDI number. Use this for CAGED boxes, chord voicings, and fingering diagrams where the
    /// physical shape matters. `note` should come from `fretboard.notes` or `fretboard.notes(matching:)`.
    public func showNote(_ note: FretboardNote, style: FretboardNoteStyle? = nil) {
        if let existing = dotNodes[note.id] {
            existing.isTransient = false
            existing.shownStyle = style
            existing.layout(configuration: configuration)
            shownIDs.insert(note.id)
        } else {
            let dot = makeDot(for: note, transient: false, shownStyle: style)
            shownIDs.insert(note.id)
            dot.animateShow()
        }
        updateCapoRoles()
    }

    /// Shows a specific set of board positions. Convenience for chord shapes and scale boxes.
    public func showNotes(_ notes: [FretboardNote], style: FretboardNoteStyle? = nil) {
        for note in notes { showNote(note, style: style) }
    }

    /// Removes the shown dot at the specific position described by `note`.
    ///
    /// If the dot is currently highlighted, it becomes transient and survives until
    /// `unhighlightNote` clears it.
    public func hideNote(_ note: FretboardNote) {
        shownIDs.remove(note.id)
        guard let dot = dotNodes[note.id] else { return }
        if dot.isHighlighted {
            dot.isTransient = true
        } else {
            removeDot(id: note.id)
        }
        updateCapoRoles()
    }

    /// Highlights the dot at the exact position described by `note`.
    /// Creates a transient dot if none exists at that position.
    public func highlightNote(_ note: FretboardNote, style: FretboardNoteStyle? = nil) {
        if let dot = dotNodes[note.id] {
            dot.highlightStyle = style
            dot.isHighlighted = true  // triggers layout via didSet
        } else {
            let dot = makeDot(for: note, transient: true, highlightStyle: style)
            dot.isHighlighted = true  // triggers layout via didSet
            dot.animateShow()
        }
    }

    /// Clears the highlight on the dot at the exact position described by `note`.
    /// Removes the dot if it is transient.
    public func unhighlightNote(_ note: FretboardNote) {
        guard let dot = dotNodes[note.id] else { return }
        dot.isHighlighted = false
        if dot.isTransient {
            removeDot(id: note.id)
        } else {
            dot.layout(configuration: configuration)
        }
    }

    // MARK: - Clearing

    /// Removes all shown dots. Highlighted dots that are currently live survive as transient
    /// until `unhighlightPitch`/`unhighlightNote` clears them.
    public func clearNotes() {
        let ids = shownIDs
        shownIDs = []
        for id in ids {
            guard let dot = dotNodes[id] else { continue }
            if dot.isHighlighted {
                dot.isTransient = true
            } else {
                removeDot(id: id)
            }
        }
        updateCapoRoles()
    }

    /// Removes all note dots — shown, highlighted, and transient — resetting the display to a clean state.
    ///
    /// Unlike `clearNotes()`, this is an unconditional wipe. Use it when switching display mode,
    /// changing tuning, or any time you want a guaranteed blank neck before re-populating.
    public func removeAllNotes() {
        shownIDs = []
        for id in Array(dotNodes.keys) {
            removeDot(id: id)
        }
    }

    // MARK: - Fret Inlays

    /// Shows an inlay marker at the given **absolute** fret number using the default color from
    /// `configuration.fretMarkerColor`.
    ///
    /// Inlays survive `reload()` — the app calls this once after setup and the library re-renders
    /// them on every geometry change. Standard guitar layout:
    /// ```swift
    /// [3,5,7,9,15,17,19,21].forEach { scene.showFretInlay(at: $0) }
    /// [12,24].forEach { scene.showFretInlay(at: $0, .double) }
    /// ```
    public func showFretInlay(at fret: Int, _ style: FretInlay = .single) {
        fretInlays[fret] = style
        renderFretInlays()
    }

    /// Removes the inlay marker at the given absolute fret number.
    public func hideFretInlay(at fret: Int) {
        fretInlays.removeValue(forKey: fret)
        renderFretInlays()
    }

    /// Removes all inlay markers.
    public func clearFretInlays() {
        fretInlays = [:]
        renderFretInlays()
    }

    /// Re-renders all stored fret inlays from the current `fretInlays` dictionary.
    /// Called after any inlay mutation and at the end of `layoutContent()`.
    private func renderFretInlays() {
        inlayNodes.forEach { $0.removeFromParent() }
        inlayNodes = []

        guard let geo = geometry else { return }

        let stringCount = fretboard.orderedStrings.count
        let fretCount = fretboard.count
        let totalCrossLength = geo.cellCross * CGFloat(stringCount)
        let markerRadius = min(geo.cellNeck, geo.cellCross) * 0.18

        for (absoluteFret, style) in fretInlays {
            let f = absoluteFret - fretboard.startIndex
            guard f >= 0, f < fretCount else { continue }

            let neckCenter = geo.neckCoordinate(measure: CGFloat(f) * geo.cellNeck + geo.cellNeck / 2)

            func addMarker(crossOffset: CGFloat) {
                let node = SKShapeNode(circleOfRadius: markerRadius)
                node.fillColor = configuration.fretMarkerColor.platformColor
                node.strokeColor = .clear
                node.zPosition = FretboardZPosition.inlay
                switch fretboard.direction {
                case .horizontal:
                    node.position = CGPoint(
                        x: geo.stringGutterSize + neckCenter,
                        y: geo.fretGutterSize + geo.crossContentOffset + crossOffset
                    )
                case .vertical:
                    node.position = CGPoint(
                        x: geo.fretGutterSize + geo.crossContentOffset + crossOffset,
                        y: geo.stringGutterSize + neckCenter
                    )
                }
                contentNode.addChild(node)
                inlayNodes.append(node)
            }

            switch style {
            case .single:
                addMarker(crossOffset: totalCrossLength / 2)
            case .double:
                addMarker(crossOffset: totalCrossLength / 3)
                addMarker(crossOffset: 2 * totalCrossLength / 3)
            }
        }
    }

    // MARK: - Dot removal helper

    private func removeDot(id: String) {
        guard let dot = dotNodes.removeValue(forKey: id) else { return }
        dot.animateHide { [weak dot] in dot?.removeFromParent() }
    }

    // MARK: - Camera / Scrolling

    private func updateCameraConstraints(totalNeckLength: CGFloat, neckAxisLength: CGFloat,
                                          stringGutterSize: CGFloat, fretGutterSize: CGFloat) {
        let halfW = size.width / 2
        let halfH = size.height / 2

        fretboardCamera.constraints = nil
        isScrollingEnabled = totalNeckLength > neckAxisLength

        if isScrollingEnabled {
            let overflow = totalNeckLength - neckAxisLength
            switch fretboard.direction {
            case .horizontal:
                let minX = halfW
                let maxX = halfW + overflow
                fretboardCamera.constraints = [
                    .positionX(SKRange(lowerLimit: minX, upperLimit: maxX)),
                    .positionY(SKRange(constantValue: halfH)),
                ]
                if fretboardCamera.position == .zero {
                    // When neck is reversed, nut is at the high-coordinate end → start at maxX.
                    let startX = (geometry?.neckReversed ?? false) ? maxX : minX
                    fretboardCamera.position = CGPoint(x: startX, y: halfH)
                }
            case .vertical:
                let minY = halfH
                let maxY = halfH + overflow
                fretboardCamera.constraints = [
                    .positionX(SKRange(constantValue: halfW)),
                    .positionY(SKRange(lowerLimit: minY, upperLimit: maxY)),
                ]
                if fretboardCamera.position == .zero {
                    // When neck is reversed (vertical default), nut is at the top → start at maxY
                    // so the nut end is visible first.
                    let startY = (geometry?.neckReversed ?? false) ? maxY : minY
                    fretboardCamera.position = CGPoint(x: halfW, y: startY)
                }
            }
        } else {
            fretboardCamera.position = CGPoint(x: halfW, y: halfH)
        }
    }

    // MARK: - Input (iOS / tvOS / visionOS)

#if os(iOS) || os(tvOS) || os(visionOS)
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let key = ObjectIdentifier(touch)
            let pos = touch.location(in: contentNode)
            touchStartPositions[key] = pos
            handlePressDown(at: pos, key: key)
        }
    }

    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let key = ObjectIdentifier(touch)
            let pos = touch.location(in: contentNode)
            handlePossiblePan(at: pos, key: key)
        }
    }

    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches { endTouch(key: ObjectIdentifier(touch)) }
    }

    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches { endTouch(key: ObjectIdentifier(touch)) }
    }
#endif

    // MARK: - Input (macOS)

#if os(macOS)
    open override func mouseDown(with event: NSEvent) {
        let key = ObjectIdentifier(event)
        let pos = event.location(in: contentNode)
        touchStartPositions[key] = pos
        handlePressDown(at: pos, key: key)
    }

    open override func mouseDragged(with event: NSEvent) {
        let key = ObjectIdentifier(event)
        let pos = event.location(in: contentNode)
        handlePossiblePan(at: pos, key: key)
    }

    open override func mouseUp(with event: NSEvent) {
        endTouch(key: ObjectIdentifier(event))
    }

    open override func scrollWheel(with event: NSEvent) {
        let delta = CGPoint(x: event.scrollingDeltaX, y: -event.scrollingDeltaY)
        pan(by: delta)
    }
#endif

    // MARK: - Press helpers

    private func handlePressDown(at pos: CGPoint, key: ObjectIdentifier) {
        guard let geo = geometry,
              let (si, fi) = geo.cell(at: pos, stringCount: fretboard.orderedStrings.count, fretCount: fretboard.count),
              let note = fretboard.notes.first(where: { $0.stringIndex == si && $0.fretIndex == fi })
        else { return }

        activeTouches[key] = note
        noteDelegate?.fretboardScene(self, noteOn: note)
        highlightPitch(note.pitch, style: noteDelegate?.fretboardScene(self, highlightStyleFor: note))
        dotNodes[note.id]?.animatePressDown()
    }

    private func handlePossiblePan(at pos: CGPoint, key: ObjectIdentifier) {
        // ── Glide mode: fretboard fits on screen, no scrolling needed ────────────
        if !isScrollingEnabled {
            guard let geo = geometry else { return }
            let cell = geo.cell(at: pos, stringCount: fretboard.orderedStrings.count, fretCount: fretboard.count)
            let newNote = cell.flatMap { si, fi in
                fretboard.notes.first { $0.stringIndex == si && $0.fretIndex == fi }
            }

            let currentNote = activeTouches[key]
            guard currentNote?.id != newNote?.id else { return }

            if let old = currentNote {
                noteDelegate?.fretboardScene(self, noteOff: old)
                dotNodes[old.id]?.animatePressUp()
                unhighlightPitch(old.pitch)
            }

            if let note = newNote {
                activeTouches[key] = note
                noteDelegate?.fretboardScene(self, noteOn: note)
                highlightPitch(note.pitch, style: noteDelegate?.fretboardScene(self, highlightStyleFor: note))
                dotNodes[note.id]?.animatePressDown()
            } else {
                activeTouches.removeValue(forKey: key)
            }
            return
        }

        // ── Scroll mode: fretboard overflows, drag pans the neck ─────────────────
        if let start = touchStartPositions[key], !panningTouches.contains(key) {
            let dx = pos.x - start.x
            let dy = pos.y - start.y
            if sqrt(dx*dx + dy*dy) > panThreshold {
                if let note = activeTouches.removeValue(forKey: key) {
                    noteDelegate?.fretboardScene(self, noteOff: note)
                    dotNodes[note.id]?.animatePressUp()
                    unhighlightPitch(note.pitch)
                }
                panningTouches.insert(key)
                touchStartPositions[key] = pos
            }
        }

        if panningTouches.contains(key) {
            let start = touchStartPositions[key] ?? pos
            let delta = CGPoint(x: pos.x - start.x, y: pos.y - start.y)
            pan(by: delta)
        }
    }

    private func endTouch(key: ObjectIdentifier) {
        if let note = activeTouches.removeValue(forKey: key) {
            noteDelegate?.fretboardScene(self, noteOff: note)
            dotNodes[note.id]?.animatePressUp()
            unhighlightPitch(note.pitch)
        }
        panningTouches.remove(key)
        touchStartPositions.removeValue(forKey: key)
    }

    // MARK: - Pan helper

    private func pan(by delta: CGPoint) {
        switch fretboard.direction {
        case .horizontal:
            fretboardCamera.position.x -= delta.x
        case .vertical:
            fretboardCamera.position.y -= delta.y
        }
    }

}
