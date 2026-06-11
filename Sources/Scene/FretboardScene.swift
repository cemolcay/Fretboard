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
    let contentOffset: CGFloat   // offset along neck axis for alignment
    let direction: FretboardDirection

    /// Scene-space origin of the cell at (stringIndex, fretIndex).
    func origin(string: Int, fret: Int) -> CGPoint {
        let neckPos = CGFloat(fret) * cellNeck + contentOffset
        let crossPos = CGFloat(string) * cellCross
        switch direction {
        case .horizontal:
            return CGPoint(x: stringGutterSize + neckPos, y: fretGutterSize + crossPos)
        case .vertical:
            return CGPoint(x: fretGutterSize + crossPos, y: stringGutterSize + neckPos)
        }
    }

    /// Returns the (stringIndex, fretIndex) for `point` in content-node space, or `nil` if outside.
    func cell(at point: CGPoint, stringCount: Int, fretCount: Int) -> (string: Int, fret: Int)? {
        let nx: CGFloat
        let ny: CGFloat
        switch direction {
        case .horizontal:
            nx = point.x - stringGutterSize - contentOffset
            ny = point.y - fretGutterSize
        case .vertical:
            nx = point.x - fretGutterSize
            ny = point.y - stringGutterSize - contentOffset
        }

        let fret: Int
        let string: Int
        switch direction {
        case .horizontal:
            fret = Int(nx / cellNeck)
            string = Int(ny / cellCross)
        case .vertical:
            fret = Int(ny / cellNeck)
            string = Int(nx / cellCross)
        }

        guard fret >= 0, fret < fretCount, string >= 0, string < stringCount else { return nil }
        return (string: string, fret: fret)
    }
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
/// **Showing notes (scale/chord/arbitrary set):**
/// ```swift
/// scene.showNotes(cMajorPitches)          // creates dots at all matching positions
/// scene.hideNote(Pitch(noteName: .c, octave: 4))
/// scene.clearNotes()                       // removes all shown dots
/// ```
///
/// **Highlighting (live MIDI, user press — same API):**
/// ```swift
/// scene.highlightNote(incomingPitch)       // creates a transient dot if none exists
/// scene.unhighlightNote(incomingPitch)     // removes transient dots when done
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

    /// Static neck geometry nodes (strings, frets lines).
    private var neckNodes: [SKShapeNode] = []

    /// Gutter label nodes.
    private var stringLabelNodes: [SKLabelNode] = []
    private var fretLabelNodes: [SKLabelNode] = []

    /// On-demand note-dot nodes, keyed by `FretboardNote.id`.
    private var dotNodes: [String: FretNoteNode] = [:]

    /// IDs of dots that exist because `showNote` was called (the "shown" set).
    private var shownIDs: Set<String> = []

    /// Current layout geometry — updated on every `layoutContent()` call.
    private var geometry: FretboardGeometry?

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

        let cellNeck = configuration.fretSizing.fretLength(neckAxisLength: neckAxisLength, count: fretCount)
        let cellCross = crossAxisLength / CGFloat(stringCount)
        let totalNeckLength = cellNeck * CGFloat(fretCount)

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
        case .fit:
            contentOffset = 0
        default:
            let slack = neckAxisLength - totalNeckLength
            switch configuration.alignment {
            case .center:   contentOffset = max(slack / 2, 0)
            case .leading:  contentOffset = 0
            case .trailing: contentOffset = max(slack, 0)
            }
        }

        geometry = FretboardGeometry(
            cellSize: CGSize(width: cellWidth, height: cellHeight),
            stringGutterSize: stringGutterSize,
            fretGutterSize: fretGutterSize,
            cellNeck: cellNeck,
            cellCross: cellCross,
            contentOffset: contentOffset,
            direction: direction
        )

        // ── String lines ──────────────────────────────────────────────────────────
        for si in 0..<stringCount {
            let origin = geometry!.origin(string: si, fret: 0)
            let endOrigin = geometry!.origin(string: si, fret: fretCount - 1)
            let path = CGMutablePath()
            switch direction {
            case .horizontal:
                let y = origin.y + cellHeight / 2
                path.move(to: CGPoint(x: stringGutterSize + contentOffset, y: y))
                path.addLine(to: CGPoint(x: endOrigin.x + cellWidth, y: y))
            case .vertical:
                let x = origin.x + cellWidth / 2
                path.move(to: CGPoint(x: x, y: stringGutterSize + contentOffset))
                path.addLine(to: CGPoint(x: x, y: endOrigin.y + cellHeight))
            }
            let node = SKShapeNode(path: path)
            node.strokeColor = configuration.stringColor.platformColor
            node.lineWidth = configuration.stringWidth
            contentNode.addChild(node)
            neckNodes.append(node)
        }

        // ── Fret lines (including nut) ────────────────────────────────────────────
        for fi in 0...fretCount {
            let isNut = fretboard.startIndex == 0 && fi == 0
            let lineWidth = isNut ? configuration.fretWidth * configuration.nutWidthMultiplier : configuration.fretWidth

            let neckPos = CGFloat(fi) * cellNeck + contentOffset
            let path = CGMutablePath()

            switch direction {
            case .horizontal:
                let x = stringGutterSize + neckPos
                path.move(to: CGPoint(x: x, y: fretGutterSize))
                path.addLine(to: CGPoint(x: x, y: fretGutterSize + crossAxisLength))
            case .vertical:
                let y = stringGutterSize + neckPos
                path.move(to: CGPoint(x: fretGutterSize, y: y))
                path.addLine(to: CGPoint(x: fretGutterSize + crossAxisLength, y: y))
            }

            let node = SKShapeNode(path: path)
            node.strokeColor = configuration.fretColor.platformColor
            node.lineWidth = lineWidth
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

            let crossPos = CGFloat(i) * cellCross + cellCross / 2
            switch direction {
            case .horizontal:
                label.position = CGPoint(x: stringGutterSize / 2, y: fretGutterSize + crossPos)
            case .vertical:
                label.position = CGPoint(x: fretGutterSize + crossPos, y: stringGutterSize / 2)
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

            let neckPos = CGFloat(f) * cellNeck + cellNeck / 2 + contentOffset
            switch direction {
            case .horizontal:
                label.position = CGPoint(x: stringGutterSize + neckPos, y: fretGutterSize / 2)
            case .vertical:
                label.position = CGPoint(x: fretGutterSize / 2, y: stringGutterSize + neckPos)
            }

            contentNode.addChild(label)
            fretLabelNodes.append(label)
        }

        // ── Camera ────────────────────────────────────────────────────────────────
        updateCameraConstraints(totalNeckLength: totalNeckLength, neckAxisLength: neckAxisLength,
                                stringGutterSize: stringGutterSize, fretGutterSize: fretGutterSize)
    }

    // MARK: - Dot placement

    /// Re-positions all existing dots after a geometry change.
    private func repositionDots() {
        guard let geo = geometry else { return }
        for (_, dot) in dotNodes {
            dot.position = geo.origin(string: dot.note.stringIndex, fret: dot.note.fretIndex)
            dot.cellSize = geo.cellSize
            dot.direction = fretboard.direction
            dot.layout(configuration: configuration)
        }
    }

    /// Creates and places a dot node for `note`. Does not update capo roles.
    private func makeDot(for note: FretboardNote, transient: Bool) -> FretNoteNode {
        let dot = FretNoteNode(note: note)
        dot.isTransient = transient
        if let geo = geometry {
            dot.position = geo.origin(string: note.stringIndex, fret: note.fretIndex)
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

    // MARK: - Public Marking API

    /// Creates a note dot at every board position whose MIDI note number matches `pitch`.
    ///
    /// If a dot already exists at a position (e.g. a transient highlight), it is promoted to
    /// the shown set (cleared of `isTransient`) rather than duplicated.
    public func showNote(_ pitch: Pitch) {
        for note in fretboard.notes(matching: pitch) {
            if let existing = dotNodes[note.id] {
                existing.isTransient = false
                shownIDs.insert(note.id)
            } else {
                let dot = makeDot(for: note, transient: false)
                shownIDs.insert(note.id)
                dot.animateShow()
            }
        }
        updateCapoRoles()
    }

    /// Creates note dots for each pitch in `pitches`. Convenience for showing a scale or chord.
    public func showNotes(_ pitches: [Pitch]) {
        for pitch in pitches { showNote(pitch) }
    }

    /// Removes the shown dot(s) for `pitch`.
    ///
    /// If a dot is currently highlighted, it becomes transient and survives until `unhighlightNote` clears it.
    public func hideNote(_ pitch: Pitch) {
        for note in fretboard.notes(matching: pitch) {
            shownIDs.remove(note.id)
            guard let dot = dotNodes[note.id] else { continue }
            if dot.isHighlighted {
                // Keep alive as transient until unhighlighted.
                dot.isTransient = true
            } else {
                removeDot(id: note.id)
            }
        }
        updateCapoRoles()
    }

    /// Removes all shown dots. Highlighted dots that are transient survive until unhighlighted.
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

    /// Highlights the dot(s) for `pitch`. If no dot exists at a position, a transient one is created.
    public func highlightNote(_ pitch: Pitch) {
        for note in fretboard.notes(matching: pitch) {
            if let dot = dotNodes[note.id] {
                dot.isHighlighted = true
            } else {
                let dot = makeDot(for: note, transient: true)
                dot.isHighlighted = true
                dot.layout(configuration: configuration)
                dot.animateShow()
            }
        }
        // Transient dots are excluded from capo merge; no full recompute needed, just re-layout.
    }

    /// Clears the highlight on dot(s) for `pitch`. Removes the dot if it is transient.
    public func unhighlightNote(_ pitch: Pitch) {
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

        if totalNeckLength > neckAxisLength {
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
                    fretboardCamera.position = CGPoint(x: minX, y: halfH)
                }
            case .vertical:
                let minY = halfH
                let maxY = halfH + overflow
                fretboardCamera.constraints = [
                    .positionX(SKRange(constantValue: halfW)),
                    .positionY(SKRange(lowerLimit: minY, upperLimit: maxY)),
                ]
                if fretboardCamera.position == .zero {
                    fretboardCamera.position = CGPoint(x: halfW, y: minY)
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
        resumeIfPaused()
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
        highlightNote(note.pitch)
        dotNodes[note.id]?.animatePressDown()
        resumeIfPaused()
    }

    private func handlePossiblePan(at pos: CGPoint, key: ObjectIdentifier) {
        if let start = touchStartPositions[key], !panningTouches.contains(key) {
            let dx = pos.x - start.x
            let dy = pos.y - start.y
            if sqrt(dx*dx + dy*dy) > panThreshold {
                // Convert to pan — send noteOff and clear highlight for the associated note.
                if let note = activeTouches.removeValue(forKey: key) {
                    noteDelegate?.fretboardScene(self, noteOff: note)
                    dotNodes[note.id]?.animatePressUp()
                    unhighlightNote(note.pitch)
                }
                panningTouches.insert(key)
                touchStartPositions[key] = pos
            }
        }

        if panningTouches.contains(key) {
            let start = touchStartPositions[key] ?? pos
            let delta = CGPoint(x: pos.x - start.x, y: pos.y - start.y)
            pan(by: delta)
            resumeIfPaused()
        }
    }

    private func endTouch(key: ObjectIdentifier) {
        if let note = activeTouches.removeValue(forKey: key) {
            noteDelegate?.fretboardScene(self, noteOff: note)
            dotNodes[note.id]?.animatePressUp()
            unhighlightNote(note.pitch)
        }
        panningTouches.remove(key)
        touchStartPositions.removeValue(forKey: key)
        pauseIfIdle()
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

    // MARK: - Idle pause

    private func resumeIfPaused() {
        isPaused = false
    }

    private func pauseIfIdle() {
        guard activeTouches.isEmpty && panningTouches.isEmpty else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self, self.activeTouches.isEmpty && self.panningTouches.isEmpty else { return }
            self.isPaused = true
        }
    }
}
