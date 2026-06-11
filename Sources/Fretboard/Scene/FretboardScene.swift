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

// MARK: - FretboardScene

/// A SpriteKit scene that renders a `Fretboard` model and handles polyphonic press interactions.
///
/// **Integration:**
/// ```swift
/// let scene = FretboardScene(fretboard: myFretboard)
/// scene.noteDelegate = self
/// skView.presentScene(scene)
/// ```
/// After mutating `myFretboard` directly, call `scene.reload()` to re-sync the visuals.
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

    /// Gutter nodes for string and fret labels.
    private var stringLabelNodes: [SKLabelNode] = []
    private var fretLabelNodes: [SKLabelNode] = []

    /// The flat ordered array of fret-cell nodes, mirrors `fretboard.notes` ordering.
    private var fretNodes: [FretNode] = []

    // MARK: - Touch / mouse tracking

    /// Maps a platform touch ID → the `FretboardNote` that was pressed by that touch.
    /// On macOS a single sentinel key ("mouse") is used.
    private var activeTouches: [ObjectIdentifier: FretboardNote] = [:]

    /// Start position of each tracked touch for drag-vs-tap disambiguation.
    private var touchStartPositions: [ObjectIdentifier: CGPoint] = [:]

    /// Touches that have already been converted to camera pans (they no longer fire noteOff on release).
    private var panningTouches: Set<ObjectIdentifier> = []

    /// The content origin when a camera pan started.
    private var panStartContentPosition: CGPoint = .zero

    /// Pixel distance a touch must travel before it is treated as a pan rather than a press.
    private let panThreshold: CGFloat = 10

    // MARK: - Camera

    private let fretboardCamera = SKCameraNode()
    private var isPanning = false

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

    /// Re-builds all nodes from the current `fretboard` and `configuration`.
    /// Call this after mutating `fretboard` properties in place.
    public func reload() {
        backgroundColor = configuration.backgroundColor.platformColor
        buildNodeTree()
        layoutContent()
    }

    // MARK: - Node tree

    private func buildNodeTree() {
        // Remove old nodes.
        fretNodes.forEach { $0.removeFromParent() }
        fretNodes = []
        stringLabelNodes.forEach { $0.removeFromParent() }
        stringLabelNodes = []
        fretLabelNodes.forEach { $0.removeFromParent() }
        fretLabelNodes = []

        // Fret cells
        for note in fretboard.notes {
            let node = FretNode(note: note)
            contentNode.addChild(node)
            fretNodes.append(node)
        }

        // String labels
        for (i, pitch) in fretboard.orderedStrings.enumerated() {
            let label = SKLabelNode(fontNamed: "Helvetica")
            label.text = pitch.noteName.description
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.name = "stringLabel-\(i)"
            contentNode.addChild(label)
            stringLabelNodes.append(label)
        }

        // Fret number labels
        for f in 0..<fretboard.count {
            let label = SKLabelNode(fontNamed: "Helvetica")
            if fretboard.startIndex == 0 && f == 0 {
                label.text = nil  // No number on the open string column
            } else {
                label.text = "\(fretboard.startIndex + f)"
            }
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.name = "fretLabel-\(f)"
            contentNode.addChild(label)
            fretLabelNodes.append(label)
        }
    }

    // MARK: - Layout

    private func layoutContent() {
        guard size.width > 0 && size.height > 0 else { return }

        let stringCount = fretboard.orderedStrings.count
        let fretCount = fretboard.count
        guard stringCount > 0, fretCount > 0 else { return }

        // ── Gutter sizes ──────────────────────────────────────────────────────────
        // Cross-axis gutter (for string labels), neck-axis gutter (for fret numbers).
        let showStringLabels = configuration.isDrawStringName
        let showFretLabels = configuration.isDrawFretNumber

        // Estimate gutter sizes from font.
        let labelFontSize: CGFloat = 12
        let stringGutterSize: CGFloat = showStringLabels ? 30 : 0
        let fretGutterSize: CGFloat = showFretLabels ? 20 : 0

        // ── Available space after gutters ─────────────────────────────────────────
        let direction = fretboard.direction
        let neckAxisLength: CGFloat
        let crossAxisLength: CGFloat

        switch direction {
        case .horizontal:
            // Neck = width, cross (strings) = height
            neckAxisLength = size.width - stringGutterSize
            crossAxisLength = size.height - fretGutterSize
        case .vertical:
            // Neck = height, cross (strings) = width
            neckAxisLength = size.height - stringGutterSize
            crossAxisLength = size.width - fretGutterSize
        }

        let cellNeck = configuration.fretSizing.fretLength(neckAxisLength: neckAxisLength, count: fretCount)
        let cellCross = crossAxisLength / CGFloat(stringCount)
        let totalNeckLength = cellNeck * CGFloat(fretCount)

        // ── Cell size in scene coords ─────────────────────────────────────────────
        let cellWidth: CGFloat
        let cellHeight: CGFloat
        switch direction {
        case .horizontal:
            cellWidth = cellNeck
            cellHeight = cellCross
        case .vertical:
            cellWidth = cellCross
            cellHeight = cellNeck
        }

        // ── Content origin (alignment when smaller than scene) ────────────────────
        let contentNeckLength = totalNeckLength
        let contentOffset: CGFloat   // Offset along the neck axis for alignment

        switch configuration.fretSizing {
        case .fit:
            contentOffset = 0
        default:
            let slack = neckAxisLength - contentNeckLength
            switch configuration.alignment {
            case .center:   contentOffset = max(slack / 2, 0)
            case .leading:  contentOffset = 0
            case .trailing: contentOffset = max(slack, 0)
            }
        }

        // ── Position fret cells ───────────────────────────────────────────────────
        // SpriteKit y=0 is bottom. We lay out with the "first string" at the cross-axis origin.
        // For horizontal: x = neckAxis, y = crossAxis (from bottom = highest string in orderedStrings).
        // For vertical: x = crossAxis, y = neckAxis (from bottom = highest fret index).

        for fretNode in fretNodes {
            let fi = fretNode.note.fretIndex
            let si = fretNode.note.stringIndex

            let neckPos = CGFloat(fi) * cellNeck + contentOffset
            let crossPos = CGFloat(si) * cellCross  // crossPos 0 = bottom = orderedStrings[0]

            switch direction {
            case .horizontal:
                fretNode.position = CGPoint(
                    x: stringGutterSize + neckPos,
                    y: fretGutterSize + crossPos
                )
            case .vertical:
                fretNode.position = CGPoint(
                    x: fretGutterSize + crossPos,
                    y: stringGutterSize + neckPos
                )
            }

            fretNode.cellSize = CGSize(width: cellWidth, height: cellHeight)
            fretNode.direction = direction
            fretNode.isOpenString = (fretboard.startIndex == 0 && fi == 0)
            fretNode.note = fretboard.notes[fretNodes.firstIndex(of: fretNode)!]
            fretNode.layout(configuration: configuration)
        }

        // ── String labels ─────────────────────────────────────────────────────────
        let labelFontSizeCalc = min(cellCross, stringGutterSize) * 0.6
        for (i, label) in stringLabelNodes.enumerated() {
            guard showStringLabels else { label.isHidden = true; continue }
            label.isHidden = false
            label.fontSize = max(labelFontSizeCalc, 8)
            label.fontColor = configuration.stringLabelColor.platformColor

            let crossPos = CGFloat(i) * cellCross + cellCross / 2

            switch direction {
            case .horizontal:
                label.position = CGPoint(x: stringGutterSize / 2, y: fretGutterSize + crossPos)
            case .vertical:
                label.position = CGPoint(x: fretGutterSize + crossPos, y: stringGutterSize / 2)
            }
        }

        // ── Fret labels ───────────────────────────────────────────────────────────
        let fretLabelFontSize = min(cellNeck, fretGutterSize) * 0.6
        for (f, label) in fretLabelNodes.enumerated() {
            guard showFretLabels else { label.isHidden = true; continue }
            label.isHidden = false
            label.fontSize = max(fretLabelFontSize, 8)
            label.fontColor = configuration.fretLabelColor.platformColor

            let neckPos = CGFloat(f) * cellNeck + cellNeck / 2 + contentOffset

            switch direction {
            case .horizontal:
                label.position = CGPoint(x: stringGutterSize + neckPos, y: fretGutterSize / 2)
            case .vertical:
                label.position = CGPoint(x: fretGutterSize / 2, y: stringGutterSize + neckPos)
            }
        }

        _ = labelFontSize  // suppress unused warning

        // ── Camera ────────────────────────────────────────────────────────────────
        updateCameraConstraints(totalNeckLength: totalNeckLength, neckAxisLength: neckAxisLength,
                                 stringGutterSize: stringGutterSize, fretGutterSize: fretGutterSize)
    }

    // MARK: - Camera / Scrolling

    private func updateCameraConstraints(totalNeckLength: CGFloat, neckAxisLength: CGFloat,
                                          stringGutterSize: CGFloat, fretGutterSize: CGFloat) {
        // Camera position is the center of what's visible. Default: show the beginning of the board.
        let halfW = size.width / 2
        let halfH = size.height / 2

        fretboardCamera.constraints = nil

        if totalNeckLength > neckAxisLength {
            // Content overflows → allow panning along the neck axis.
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
            // Content fits → center the camera.
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

            if let node = fretNodes.first(where: { nodeContainsPoint($0, point: pos) }) {
                activeTouches[key] = node.note
                noteDelegate?.fretboardScene(self, noteOn: node.note)
                node.animatePressDown()
                resumeIfPaused()
            }
        }
    }

    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let key = ObjectIdentifier(touch)
            let pos = touch.location(in: contentNode)

            if let start = touchStartPositions[key], !panningTouches.contains(key) {
                let dx = pos.x - start.x
                let dy = pos.y - start.y
                if sqrt(dx*dx + dy*dy) > panThreshold {
                    // Convert to pan — send noteOff for the associated note if any.
                    if let note = activeTouches.removeValue(forKey: key) {
                        noteDelegate?.fretboardScene(self, noteOff: note)
                        if let node = fretNodes.first(where: { $0.note.id == note.id }) {
                            node.animatePressUp()
                        }
                    }
                    panningTouches.insert(key)
                    panStartContentPosition = fretboardCamera.position
                    touchStartPositions[key] = pos  // Reset origin for delta panning
                }
            }

            if panningTouches.contains(key) {
                let start = touchStartPositions[key] ?? pos
                let delta = CGPoint(x: pos.x - start.x, y: pos.y - start.y)
                pan(by: delta)
                resumeIfPaused()
            }
        }
    }

    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        endTouches(touches)
    }

    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        endTouches(touches)
    }

    private func endTouches(_ touches: Set<UITouch>) {
        for touch in touches {
            let key = ObjectIdentifier(touch)
            if let note = activeTouches.removeValue(forKey: key) {
                noteDelegate?.fretboardScene(self, noteOff: note)
                if let node = fretNodes.first(where: { $0.note.id == note.id }) {
                    node.animatePressUp()
                }
            }
            panningTouches.remove(key)
            touchStartPositions.removeValue(forKey: key)
        }
        pauseIfIdle()
    }
#endif

    // MARK: - Input (macOS)

#if os(macOS)
    open override func mouseDown(with event: NSEvent) {
        let pos = event.location(in: contentNode)
        let key = ObjectIdentifier(event)
        touchStartPositions[key] = pos

        if let node = fretNodes.first(where: { nodeContainsPoint($0, point: pos) }) {
            activeTouches[key] = node.note
            noteDelegate?.fretboardScene(self, noteOn: node.note)
            node.animatePressDown()
            resumeIfPaused()
        }
    }

    open override func mouseDragged(with event: NSEvent) {
        let pos = event.location(in: contentNode)
        let key = ObjectIdentifier(event)

        if let start = touchStartPositions[key], !panningTouches.contains(key) {
            let dx = pos.x - start.x
            let dy = pos.y - start.y
            if sqrt(dx*dx + dy*dy) > panThreshold {
                if let note = activeTouches.removeValue(forKey: key) {
                    noteDelegate?.fretboardScene(self, noteOff: note)
                    if let node = fretNodes.first(where: { $0.note.id == note.id }) {
                        node.animatePressUp()
                    }
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

    open override func mouseUp(with event: NSEvent) {
        let key = ObjectIdentifier(event)
        if let note = activeTouches.removeValue(forKey: key) {
            noteDelegate?.fretboardScene(self, noteOff: note)
            if let node = fretNodes.first(where: { $0.note.id == note.id }) {
                node.animatePressUp()
            }
        }
        panningTouches.remove(key)
        touchStartPositions.removeValue(forKey: key)
        pauseIfIdle()
    }

    open override func scrollWheel(with event: NSEvent) {
        // NSEvent.scrollingDeltaX/Y are in points; positive = scroll right/down.
        let delta = CGPoint(x: event.scrollingDeltaX, y: -event.scrollingDeltaY)
        pan(by: delta)
        resumeIfPaused()
    }
#endif

    // MARK: - Pan helper

    private func pan(by delta: CGPoint) {
        switch fretboard.direction {
        case .horizontal:
            fretboardCamera.position.x -= delta.x
        case .vertical:
            fretboardCamera.position.y -= delta.y
        }
        // Camera constraints (set in updateCameraConstraints) clamp the result automatically.
    }

    // MARK: - Hit testing

    private func nodeContainsPoint(_ fretNode: FretNode, point: CGPoint) -> Bool {
        let local = contentNode.convert(point, to: fretNode)
        return CGRect(origin: .zero, size: fretNode.cellSize).contains(local)
    }

    // MARK: - Idle pause

    private func resumeIfPaused() {
        isPaused = false
    }

    private func pauseIfIdle() {
        guard activeTouches.isEmpty && panningTouches.isEmpty else { return }
        // Small delay so in-flight SKActions finish before we pause.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self, self.activeTouches.isEmpty && self.panningTouches.isEmpty else { return }
            self.isPaused = true
        }
    }
}
