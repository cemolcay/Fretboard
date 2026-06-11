//
//  FretboardConfiguration.swift
//  Fretboard
//
//  Created by Cem Olcay on 11/06/2026.
//

import CoreGraphics
#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - FretboardColor

/// A platform-independent RGBA color that is `Codable` and bridges to `UIColor`/`NSColor`.
public struct FretboardColor: Codable, Hashable {
    public var red: CGFloat
    public var green: CGFloat
    public var blue: CGFloat
    public var alpha: CGFloat

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1) {
        self.red = red; self.green = green; self.blue = blue; self.alpha = alpha
    }

    /// Convenience for greyscale.
    public init(white: CGFloat, alpha: CGFloat = 1) {
        self.init(red: white, green: white, blue: white, alpha: alpha)
    }

    public static let black = FretboardColor(white: 0)
    public static let white = FretboardColor(white: 1)
    public static let darkGray = FretboardColor(white: 0.33)
    public static let lightGray = FretboardColor(white: 0.67)
    public static let clear = FretboardColor(white: 0, alpha: 0)

    // MARK: Platform bridge

#if os(iOS) || os(tvOS) || os(visionOS)
    public var platformColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    public init(_ color: UIColor) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.init(red: r, green: g, blue: b, alpha: a)
    }
#elseif os(macOS)
    public var platformColor: NSColor {
        NSColor(srgbRed: red, green: green, blue: blue, alpha: alpha)
    }
    public init(_ color: NSColor) {
        let c = color.usingColorSpace(.sRGB) ?? color
        self.init(red: c.redComponent, green: c.greenComponent, blue: c.blueComponent, alpha: c.alphaComponent)
    }
#endif
}

// MARK: - FretboardConfiguration

/// Visual configuration for `FretboardScene`. All values are `Codable` for persistence.
public struct FretboardConfiguration: Codable, Hashable {

    // MARK: - Neck colors

    /// Color of the string lines.
    public var stringColor: FretboardColor = .black
    /// Color of the fret lines.
    public var fretColor: FretboardColor = .darkGray
    /// Color of string-name labels (e.g. E, A, D…).
    public var stringLabelColor: FretboardColor = .black
    /// Color of fret-number labels.
    public var fretLabelColor: FretboardColor = .black
    /// Background color of the scene.
    public var backgroundColor: FretboardColor = .clear

    // MARK: - Note dot — normal state

    /// Fill color of note dots in their normal (non-highlighted) state.
    public var noteColor: FretboardColor = .black
    /// Text color of note-name labels on dots in their normal state.
    public var noteTextColor: FretboardColor = .white
    /// Border (stroke) color of note dots in their normal state. Opt-in via `noteBorderWidth`.
    public var noteBorderColor: FretboardColor = .clear
    /// Border width for note dots in their normal state. Defaults to `0` (no border).
    public var noteBorderWidth: CGFloat = 0

    // MARK: - Note dot — highlighted state

    /// Fill color of note dots when highlighted (user press or incoming MIDI).
    public var highlightNoteColor: FretboardColor = FretboardColor(red: 0.95, green: 0.45, blue: 0.15, alpha: 1)
    /// Text color of note-name labels on highlighted dots.
    public var highlightNoteTextColor: FretboardColor = .white
    /// Border (stroke) color of note dots when highlighted.
    public var highlightNoteBorderColor: FretboardColor = .clear
    /// Border width for note dots when highlighted. Falls back to `noteBorderWidth` if `0`.
    public var highlightNoteBorderWidth: CGFloat = 0

    // MARK: - Line widths

    /// Width of each string line in points.
    public var stringWidth: CGFloat = 0.5
    /// Width of each fret line in points.
    public var fretWidth: CGFloat = 2
    /// The nut (fret 0 / open-string edge) is drawn at `fretWidth * nutWidthMultiplier`.
    public var nutWidthMultiplier: CGFloat = 2

    // MARK: - Padding

    /// Offset that shrinks the note dot away from the fret cell edges.
    public var noteOffset: CGFloat = 5

    // MARK: - Label toggles

    /// Whether to draw the note-name label inside note dots.
    public var isDrawNoteName: Bool = true
    /// Whether to draw string-name labels (E, A, D…) at the nut end.
    public var isDrawStringName: Bool = true
    /// Whether to draw fret-number labels.
    public var isDrawFretNumber: Bool = true

    // MARK: - Sizing / layout

    /// How large each fret is along the neck axis. Defaults to `.fit`.
    public var fretSizing: FretSizing = .fit
    /// Where to anchor the board when it is smaller than the scene. Defaults to `.center`.
    public var alignment: FretboardAlignment = .center

    // MARK: - Capo visualization

    /// When `true`, adjacent shown dots on the same fret are rendered as a single capsule
    /// (capo bar) rather than individual circles. Computed and applied at the scene level;
    /// no data-layer state is involved.
    public var isCapoModeOn: Bool = false

    public init() {}
}
