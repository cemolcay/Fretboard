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

// MARK: - FretInlay

/// The visual style of a fret-inlay (position) marker, requested via `FretboardScene.showFretInlay(at:_:)`.
///
/// The *library* renders the geometry; the *app* decides which frets get an inlay and which style.
/// Standard guitar convention — single at 3·5·7·9·15·17·19·21, double at 12·24 — is expressed in
/// app code, not in the library:
/// ```swift
/// [3,5,7,9,15,17,19,21].forEach { scene.showFretInlay(at: $0) }
/// [12,24].forEach { scene.showFretInlay(at: $0, .double) }
/// ```
public enum FretInlay: Codable, Hashable {
    /// A single dot centered between the strings at this fret.
    case single
    /// Two dots at 1/3 and 2/3 across the string spread (octave-marker convention).
    case double
}

// MARK: - FretboardNoteStyle

/// Per-note visual overrides that can be passed to any `FretboardScene` show/highlight call.
///
/// Each field is optional. `nil` means "fall back to the corresponding `FretboardConfiguration.noteStyle`
/// (or `highlightNoteStyle`) value, then to the built-in library default."
/// Resolution order for every rendered dot:
/// **per-note override → `config.noteStyle`/`highlightNoteStyle` → `.defaultNote`/`.defaultHighlight`**
///
/// **Label semantics:**
/// - `nil` → use `note.pitch.noteName.description` (the default behaviour).
/// - Non-nil, non-empty string → render that string (e.g. `"♭3"`, `"P5"`, `"2"` for finger number).
/// - `""` (empty string) → hide the label for this specific note, regardless of `config.isDrawNoteName`.
///
/// **Usage — degree coloring when showing a scale:**
/// ```swift
/// for noteName in scale.noteNames {
///     for octave in fretboard.octaves {
///         let pitch = Pitch(noteName: noteName, octave: octave)
///         if let degree = scale.degree(of: noteName) {
///             scene.showPitch(pitch, style: .init(color: degreeColor(degree), label: "\(degree)"))
///         }
///     }
/// }
/// // Scale changed → scene.removeAllNotes(); re-run loop.
/// ```
public struct FretboardNoteStyle: Codable, Hashable {
    /// Dot fill color. `nil` → inherits.
    public var color: FretboardColor?
    /// Label text color. `nil` → inherits.
    public var textColor: FretboardColor?
    /// Border (stroke) color. `nil` → inherits.
    public var borderColor: FretboardColor?
    /// Border width. `nil` → inherits.
    public var borderWidth: CGFloat?
    /// Label text override. `nil` → note name. `""` → hide label for this note.
    public var label: String?

    public init(
        color: FretboardColor? = nil,
        textColor: FretboardColor? = nil,
        borderColor: FretboardColor? = nil,
        borderWidth: CGFloat? = nil,
        label: String? = nil
    ) {
        self.color = color
        self.textColor = textColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.label = label
    }

    /// Returns a new style where every `nil` field is filled from `base`.
    ///
    /// Used internally by `FretNoteNode.layout` to chain:
    /// per-note override → config default → built-in default.
    public func merged(over base: FretboardNoteStyle) -> FretboardNoteStyle {
        FretboardNoteStyle(
            color: color ?? base.color,
            textColor: textColor ?? base.textColor,
            borderColor: borderColor ?? base.borderColor,
            borderWidth: borderWidth ?? base.borderWidth,
            label: label ?? base.label
        )
    }

    /// Library built-in defaults for a normal (non-highlighted) note dot.
    /// `label` is intentionally `nil` — it signals "use the note name."
    public static let defaultNote = FretboardNoteStyle(
        color: .black,
        textColor: .white,
        borderColor: .clear,
        borderWidth: 0
    )

    /// Library built-in defaults for a highlighted note dot.
    public static let defaultHighlight = FretboardNoteStyle(
        color: FretboardColor(red: 0.95, green: 0.45, blue: 0.15, alpha: 1),
        textColor: .white,
        borderColor: .clear,
        borderWidth: 0
    )
}

// MARK: - FretNoteNode

/// An on-demand SpriteKit node representing one note dot on the fretboard.
///
/// Created by `FretboardScene` when a pitch is shown or highlighted, removed when it is
/// no longer needed. The neck grid (strings, frets, inlay markers) is drawn separately by the scene.
///
/// **Visual states:**
/// - Normal: style resolved from `shownStyle` → `config.noteStyle` → `.defaultNote`.
/// - Highlighted: style resolved from `highlightStyle` → `config.highlightNoteStyle` → `.defaultHighlight`.
/// - Capo: when `capoRole` is set by the scene, the dot is merged into a capsule bar.
///
/// **Per-note style overrides:**
/// Set `shownStyle` and/or `highlightStyle` before calling `layout(configuration:)`.
/// Both are stored on the dot so they survive `reload()` calls.
public final class FretNoteNode: SKNode {

    // MARK: - Child nodes

    /// The dot shape (circle or capo capsule segment).
    public let noteNode = SKShapeNode()
    /// The note-name (or override) label inside the dot.
    public let labelNode = SKLabelNode(fontNamed: "Helvetica")

    // MARK: - State

    /// The fretboard note this dot represents.
    public var note: FretboardNote

    /// The fret-cell size in the scene — set by `FretboardScene` before calling `layout`.
    public var cellSize: CGSize = .zero

    /// The board direction — determines which axis the capo bar extends along.
    public var direction: FretboardDirection = .horizontal

    /// Whether this dot is in the highlighted state (user press or incoming MIDI).
    ///
    /// Setting this automatically re-applies `layout` so the correct state style is used.
    public var isHighlighted: Bool = false {
        didSet {
            guard oldValue != isHighlighted else { return }
            layout(configuration: _lastConfiguration)
        }
    }

    /// The capo rendering role assigned by the scene. Re-set after any change to the shown set.
    public var capoRole: CapoRole = .single

    /// `true` when this dot was created solely to satisfy a `highlightPitch`/`highlightNote` call for a
    /// position that had no existing shown dot. The scene removes it when the highlight is cleared.
    public var isTransient: Bool = false

    /// Per-note style override for the normal (non-highlighted) state.
    ///
    /// Non-nil fields override the corresponding `FretboardConfiguration.noteStyle` values.
    /// Set before or alongside calling `layout(configuration:)` — the override is stored on the dot
    /// and applied on every subsequent re-layout (e.g. after a `reload()`).
    public var shownStyle: FretboardNoteStyle?

    /// Per-note style override for the highlighted state.
    ///
    /// Non-nil fields override the corresponding `FretboardConfiguration.highlightNoteStyle` values.
    public var highlightStyle: FretboardNoteStyle?

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
    /// `direction`, `configuration`, and per-note style overrides (`shownStyle` / `highlightStyle`).
    ///
    /// Called by `FretboardScene` after geometry changes or state changes.
    public func layout(configuration cfg: FretboardConfiguration) {
        _lastConfiguration = cfg

        // Three-tier style resolution:
        //   per-note override → config default → built-in default.
        let perNote = isHighlighted ? highlightStyle : shownStyle
        let configDefault = isHighlighted ? cfg.highlightNoteStyle : cfg.noteStyle
        let builtIn: FretboardNoteStyle = isHighlighted ? .defaultHighlight : .defaultNote
        let base = configDefault.merged(over: builtIn)
        let style = perNote?.merged(over: base) ?? base

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

        // ── Colors ───────────────────────────────────────────────────────────────
        let bw = style.borderWidth ?? 0
        noteNode.fillColor = (style.color ?? .black).platformColor
        noteNode.strokeColor = bw > 0 ? (style.borderColor ?? .clear).platformColor : .clear
        noteNode.lineWidth = bw
        labelNode.fontColor = (style.textColor ?? .white).platformColor

        // ── Label ────────────────────────────────────────────────────────────────
        if cfg.isDrawNoteName {
            if let overrideLabel = style.label {
                // Empty string = hide this note's label even though isDrawNoteName is on.
                if overrideLabel.isEmpty {
                    labelNode.isHidden = true
                    labelNode.text = nil
                } else {
                    layoutLabel(overrideLabel, noteSize: noteSize, center: CGPoint(x: cx, y: cy))
                }
            } else {
                layoutLabel(note.pitch.noteName.description, noteSize: noteSize, center: CGPoint(x: cx, y: cy))
            }
        } else {
            // isDrawNoteName is off globally — still allow a non-empty style label to show through.
            if let overrideLabel = style.label, !overrideLabel.isEmpty {
                layoutLabel(overrideLabel, noteSize: noteSize, center: CGPoint(x: cx, y: cy))
            } else {
                labelNode.isHidden = true
            }
        }
    }

    private func layoutLabel(_ text: String, noteSize: CGFloat, center: CGPoint) {
        labelNode.isHidden = false
        labelNode.text = text
        labelNode.verticalAlignmentMode = .center
        labelNode.horizontalAlignmentMode = .center
        labelNode.position = center

        let maxFontSize = max(noteSize / 2, 8)
        let minFontSize: CGFloat = 1
        let availableSize = max(noteSize * 0.72, 1)

        labelNode.fontSize = maxFontSize
        let frame = labelNode.calculateAccumulatedFrame()
        let widthScale = frame.width > 0 ? availableSize / frame.width : 1
        let heightScale = frame.height > 0 ? availableSize / frame.height : 1
        let fittedSize = max(min(maxFontSize * min(widthScale, heightScale, 1), maxFontSize), minFontSize)
        labelNode.fontSize = fittedSize

        while labelNode.fontSize > minFontSize {
            let fittedFrame = labelNode.calculateAccumulatedFrame()
            guard fittedFrame.width > availableSize || fittedFrame.height > availableSize else { break }
            labelNode.fontSize = max(labelNode.fontSize - 0.5, minFontSize)
        }
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
