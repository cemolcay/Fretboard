//
//  FretNode.swift
//  Fretboard
//
//  Created by Cem Olcay on 11/06/2026.
//

import SpriteKit
import MusicTheory

/// A SpriteKit node representing one fret-cell in the fretboard grid.
///
/// Composed of three child nodes:
/// - `stringNode`: the horizontal (or vertical) string line.
/// - `fretNode`: the vertical (or horizontal) fret line at the right (or bottom) edge.
/// - `noteNode`: the note dot (circle or capo bar); hidden when not selected.
/// - `labelNode`: the note-name label inside the dot; hidden when not selected or text is off.
public final class FretNode: SKNode {

    // MARK: - Child nodes

    public let stringNode = SKShapeNode()
    public let fretNode = SKShapeNode()
    public let noteNode = SKShapeNode()
    public let labelNode = SKLabelNode(fontNamed: "Helvetica")

    // MARK: - State

    /// The fretboard note this cell represents.
    public var note: FretboardNote

    /// The fret-cell size in the scene (set by `FretboardScene.layoutContent()`).
    public var cellSize: CGSize = .zero

    /// Whether this is the open-string column (fret 0 when `startIndex == 0`).
    public var isOpenString: Bool = false

    /// Direction drives which axis the string and fret lines follow.
    public var direction: FretboardDirection = .horizontal

    // MARK: - Init

    public init(note: FretboardNote) {
        self.note = note
        super.init()
        addChild(stringNode)
        addChild(fretNode)
        addChild(noteNode)
        noteNode.addChild(labelNode)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is not supported") }

    // MARK: - Layout

    /// Rebuilds all child node geometry to match the current `cellSize`, `note`, `direction`,
    /// and `configuration`. Call after any of those properties change.
    public func layout(configuration cfg: FretboardConfiguration) {
        // ── String line ──────────────────────────────────────────────────────────
        if isOpenString {
            stringNode.path = nil
        } else {
            let sp = CGMutablePath()
            switch direction {
            case .horizontal:
                sp.move(to: CGPoint(x: 0, y: cellSize.height / 2))
                sp.addLine(to: CGPoint(x: cellSize.width, y: cellSize.height / 2))
            case .vertical:
                sp.move(to: CGPoint(x: cellSize.width / 2, y: 0))
                sp.addLine(to: CGPoint(x: cellSize.width / 2, y: cellSize.height))
            }
            stringNode.path = sp
        }
        stringNode.strokeColor = cfg.stringColor.platformColor
        stringNode.lineWidth = cfg.stringWidth

        // ── Fret line ────────────────────────────────────────────────────────────
        let fp = CGMutablePath()
        switch direction {
        case .horizontal:
            fp.move(to: CGPoint(x: cellSize.width, y: 0))
            fp.addLine(to: CGPoint(x: cellSize.width, y: cellSize.height))
        case .vertical:
            fp.move(to: CGPoint(x: 0, y: cellSize.height))
            fp.addLine(to: CGPoint(x: cellSize.width, y: cellSize.height))
        }
        fretNode.path = fp
        fretNode.strokeColor = cfg.fretColor.platformColor
        fretNode.lineWidth = isOpenString ? cfg.fretWidth * cfg.nutWidthMultiplier : cfg.fretWidth

        // ── Note dot / capo bar ──────────────────────────────────────────────────
        let minDim = min(cellSize.width, cellSize.height)
        let noteSize = max(minDim - cfg.noteOffset * 2, 0)
        let cx = cellSize.width / 2
        let cy = cellSize.height / 2

        noteNode.fillColor = cfg.noteColor.platformColor
        noteNode.strokeColor = .clear
        noteNode.lineWidth = 0

        switch note.noteType {
        case .none:
            noteNode.path = nil
            noteNode.isHidden = true

        case .default:
            noteNode.isHidden = false
            let r = noteSize / 2
            noteNode.path = CGPath(ellipseIn: CGRect(x: cx - r, y: cy - r, width: noteSize, height: noteSize), transform: nil)

        case .capo:
            noteNode.isHidden = false
            noteNode.path = capoBarPath(cx: cx, cy: cy, noteSize: noteSize, capStart: false, capEnd: false)

        case .capoStart:
            noteNode.isHidden = false
            noteNode.path = capoBarPath(cx: cx, cy: cy, noteSize: noteSize, capStart: true, capEnd: false)

        case .capoEnd:
            noteNode.isHidden = false
            noteNode.path = capoBarPath(cx: cx, cy: cy, noteSize: noteSize, capStart: false, capEnd: true)
        }

        // ── Label ────────────────────────────────────────────────────────────────
        if cfg.isDrawNoteName && note.isSelected && note.noteType != .none {
            labelNode.isHidden = false
            labelNode.text = note.pitch.noteName.description
            labelNode.fontSize = max(noteSize / 2, 8)
            labelNode.fontColor = cfg.noteTextColor.platformColor
            labelNode.verticalAlignmentMode = .center
            labelNode.horizontalAlignmentMode = .center
            labelNode.position = CGPoint(x: cx, y: cy)
        } else {
            labelNode.isHidden = true
        }
    }

    // MARK: - Capo path helpers

    private func capoBarPath(cx: CGFloat, cy: CGFloat, noteSize: CGFloat, capStart: Bool, capEnd: Bool) -> CGPath {
        let half = noteSize / 2
        let path = CGMutablePath()

        switch direction {
        case .horizontal:
            // Bar runs top-to-bottom. capStart = rounded cap at top, capEnd = at bottom.
            let barRect = CGRect(x: cx - half, y: capEnd ? cy : 0, width: noteSize, height: capStart ? cellSize.height / 2 : (capEnd ? cellSize.height / 2 : cellSize.height))
            path.addRect(barRect)
            if capStart {
                path.addEllipse(in: CGRect(x: cx - half, y: cy - half, width: noteSize, height: noteSize))
            }
            if capEnd {
                path.addEllipse(in: CGRect(x: cx - half, y: cy - half, width: noteSize, height: noteSize))
            }

        case .vertical:
            // Bar runs left-to-right.
            let barRect = CGRect(x: capEnd ? cx : 0, y: cy - half, width: capStart ? cellSize.width / 2 : (capEnd ? cellSize.width / 2 : cellSize.width), height: noteSize)
            path.addRect(barRect)
            if capStart {
                path.addEllipse(in: CGRect(x: cx - half, y: cy - half, width: noteSize, height: noteSize))
            }
            if capEnd {
                path.addEllipse(in: CGRect(x: cx - half, y: cy - half, width: noteSize, height: noteSize))
            }
        }

        return path
    }

    // MARK: - Press highlight

    /// Applies a press-down visual (slightly smaller + dimmed). Call on noteOn.
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

    /// Plays a pop-in animation when a note becomes selected programmatically.
    public func animateSelect() {
        noteNode.setScale(0.1)
        noteNode.run(.sequence([
            .scale(to: 1.1, duration: 0.12),
            .scale(to: 1.0, duration: 0.06),
        ]), withKey: "select")
    }

    /// Fades out the note dot when deselected.
    public func animateDeselect() {
        noteNode.run(.fadeOut(withDuration: 0.1), withKey: "select")
    }
}
