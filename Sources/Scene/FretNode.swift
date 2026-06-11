//
//  FretNode.swift
//  Fretboard
//
//  Created by Cem Olcay on 11/06/2026.
//

import SpriteKit
import MusicTheory

// MARK: - CapoRole

/// The visual role a note dot plays when capo-mode is enabled.
///
/// Assigned by `FretboardScene` based on adjacency of shown dots on the same fret.
/// When capo mode is off every dot uses `.single`.
public enum CapoRole {
    /// An isolated dot, or capo mode is off — draw as a filled circle.
    case single
    /// First in a consecutive run across strings at the same fret: circle + bar extending toward `.bar`/`.capEnd`.
    case capStart
    /// A middle segment in a capo run: a plain bar connecting both neighbours.
    case bar
    /// Last in a consecutive run: bar extending from `.capStart`/`.bar` + circle cap.
    case capEnd
}

// MARK: - FretNoteNode

/// An on-demand SpriteKit node representing one note dot on the fretboard.
///
/// Created by `FretboardScene` when a pitch is shown or highlighted, removed when it is
/// no longer needed. The neck grid (strings, frets, labels) is drawn separately by the scene.
///
/// **Visual states:**
/// - Normal: filled circle using `noteColor` / `noteTextColor` / border config.
/// - Highlighted: same geometry, different fill (`highlightNoteColor`) — used identically for
///   a user press and an incoming MIDI note.
/// - Capo: when `capoRole` is set by the scene, the dot is merged into a capsule bar.
public final class FretNoteNode: SKNode {

    // MARK: - Child nodes

    /// The dot shape (circle or capo capsule segment).
    public let noteNode = SKShapeNode()
    /// The note-name label inside the dot.
    public let labelNode = SKLabelNode(fontNamed: "Helvetica")

    // MARK: - State

    /// The fretboard note this dot represents.
    public var note: FretboardNote

    /// The fret-cell size in the scene — set by `FretboardScene` before calling `layout`.
    public var cellSize: CGSize = .zero

    /// The board direction — determines which axis the capo bar extends along.
    public var direction: FretboardDirection = .horizontal

    /// Whether this dot is in the highlighted state (user press or incoming MIDI).
    public var isHighlighted: Bool = false {
        didSet { applyColors(configuration: _lastConfiguration) }
    }

    /// The capo rendering role assigned by the scene. Re-set after any change to the shown set.
    public var capoRole: CapoRole = .single

    /// `true` when this dot was created solely to satisfy a `highlightNote` call for a pitch that
    /// had no existing shown dot. The scene removes it when `unhighlightNote` is called.
    public var isTransient: Bool = false

    // MARK: Private

    private var _lastConfiguration: FretboardConfiguration = FretboardConfiguration()

    // MARK: - Init

    public init(note: FretboardNote) {
        self.note = note
        super.init()
        addChild(noteNode)
        noteNode.addChild(labelNode)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is not supported") }

    // MARK: - Layout

    /// Rebuilds all child-node geometry to match the current `cellSize`, `capoRole`, `isHighlighted`,
    /// `direction`, and `configuration`. Call after any of those properties change.
    public func layout(configuration cfg: FretboardConfiguration) {
        _lastConfiguration = cfg

        let minDim = min(cellSize.width, cellSize.height)
        let noteSize = max(minDim - cfg.noteOffset * 2, 0)
        let cx = cellSize.width / 2
        let cy = cellSize.height / 2

        // ── Shape ────────────────────────────────────────────────────────────────
        switch capoRole {
        case .single:
            let r = noteSize / 2
            noteNode.path = CGPath(ellipseIn: CGRect(x: cx - r, y: cy - r, width: noteSize, height: noteSize), transform: nil)

        case .capStart:
            noteNode.path = capoBarPath(cx: cx, cy: cy, noteSize: noteSize, capStart: true, capEnd: false)

        case .bar:
            noteNode.path = capoBarPath(cx: cx, cy: cy, noteSize: noteSize, capStart: false, capEnd: false)

        case .capEnd:
            noteNode.path = capoBarPath(cx: cx, cy: cy, noteSize: noteSize, capStart: false, capEnd: true)
        }

        applyColors(configuration: cfg)

        // ── Label ────────────────────────────────────────────────────────────────
        if cfg.isDrawNoteName {
            labelNode.isHidden = false
            labelNode.text = note.pitch.noteName.description
            labelNode.fontSize = max(noteSize / 2, 8)
            labelNode.verticalAlignmentMode = .center
            labelNode.horizontalAlignmentMode = .center
            labelNode.position = CGPoint(x: cx, y: cy)
        } else {
            labelNode.isHidden = true
        }
        updateLabelColor(configuration: cfg)
    }

    // MARK: - Color helpers

    private func applyColors(configuration cfg: FretboardConfiguration) {
        if isHighlighted {
            noteNode.fillColor = cfg.highlightNoteColor.platformColor
            let bw = cfg.highlightNoteBorderWidth > 0 ? cfg.highlightNoteBorderWidth : cfg.noteBorderWidth
            noteNode.strokeColor = bw > 0 ? cfg.highlightNoteBorderColor.platformColor : .clear
            noteNode.lineWidth = bw
        } else {
            noteNode.fillColor = cfg.noteColor.platformColor
            noteNode.strokeColor = cfg.noteBorderWidth > 0 ? cfg.noteBorderColor.platformColor : .clear
            noteNode.lineWidth = cfg.noteBorderWidth
        }
        updateLabelColor(configuration: cfg)
    }

    private func updateLabelColor(configuration cfg: FretboardConfiguration) {
        labelNode.fontColor = isHighlighted
            ? cfg.highlightNoteTextColor.platformColor
            : cfg.noteTextColor.platformColor
    }

    // MARK: - Capo bar path

    private func capoBarPath(cx: CGFloat, cy: CGFloat, noteSize: CGFloat, capStart: Bool, capEnd: Bool) -> CGPath {
        let half = noteSize / 2
        let path = CGMutablePath()

        switch direction {
        case .horizontal:
            // Bar runs top-to-bottom (across strings). capStart = cap at top, capEnd = cap at bottom.
            let barY: CGFloat = capEnd ? cy : 0
            let barH: CGFloat = capStart || capEnd ? cellSize.height / 2 : cellSize.height
            path.addRect(CGRect(x: cx - half, y: barY, width: noteSize, height: barH))
            if capStart {
                path.addEllipse(in: CGRect(x: cx - half, y: cy - half, width: noteSize, height: noteSize))
            }
            if capEnd {
                path.addEllipse(in: CGRect(x: cx - half, y: cy - half, width: noteSize, height: noteSize))
            }

        case .vertical:
            // Bar runs left-to-right (across strings). capStart = cap at left, capEnd = cap at right.
            let barX: CGFloat = capEnd ? cx : 0
            let barW: CGFloat = capStart || capEnd ? cellSize.width / 2 : cellSize.width
            path.addRect(CGRect(x: barX, y: cy - half, width: barW, height: noteSize))
            if capStart {
                path.addEllipse(in: CGRect(x: cx - half, y: cy - half, width: noteSize, height: noteSize))
            }
            if capEnd {
                path.addEllipse(in: CGRect(x: cx - half, y: cy - half, width: noteSize, height: noteSize))
            }
        }

        return path
    }

    // MARK: - Press animations

    /// Applies a press-down visual (slightly smaller + brightened). Call on noteOn.
    public func animatePressDown() {
        let scale = SKAction.scale(to: 0.85, duration: 0.08)
        let dim = SKAction.colorize(with: .white, colorBlendFactor: 0.3, duration: 0.08)
        noteNode.run(.group([scale, dim]), withKey: "press")
    }

    /// Restores the normal visual. Call on noteOff.
    public func animatePressUp() {
        let scale = SKAction.scale(to: 1.0, duration: 0.1)
        let undim = SKAction.colorize(with: .clear, colorBlendFactor: 0.0, duration: 0.1)
        noteNode.run(.group([scale, undim]), withKey: "press")
    }

    /// Plays a pop-in animation when a note dot is first shown.
    public func animateShow() {
        noteNode.setScale(0.1)
        noteNode.run(.sequence([
            .scale(to: 1.1, duration: 0.12),
            .scale(to: 1.0, duration: 0.06),
        ]), withKey: "show")
    }

    /// Fades out the note dot before it is removed from the scene.
    public func animateHide(completion: @escaping () -> Void) {
        noteNode.run(.sequence([
            .fadeOut(withDuration: 0.1),
            .run(completion),
        ]), withKey: "hide")
    }
}
