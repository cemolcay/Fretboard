//
//  FretboardLayout.swift
//  Fretboard
//
//  Created by Cem Olcay on 11/06/2026.
//

import CoreGraphics

// MARK: - FretSizing

/// Determines how long each fret is along the neck axis.
public enum FretSizing: Codable, Hashable {
    /// A fixed point size per fret (e.g. `.fixed(200)` → 200 pt per fret regardless of scene size).
    case fixed(CGFloat)
    /// A fraction of the scene's neck-axis dimension per fret
    /// (e.g. `.multiplier(0.2)` → 20% of the scene per fret → 5 frets fill the scene exactly).
    case multiplier(CGFloat)
    /// Fill mode: all `count` frets fill the scene's neck axis exactly. No scrolling occurs.
    case fill
    /// Fit mode: fret length is derived from string spacing (cross-axis / stringCount) scaled by
    /// `fitAspectRatio`, capped at the fill length so the neck never scrolls. The result is
    /// centered in the scene. Produces realistic fretboard proportions on large screens regardless
    /// of fret count. The actual computation happens in `FretboardScene.layoutContent()` where
    /// the live cross-axis dimension is available; `fretLength(neckAxisLength:count:)` returns the
    /// fill-length fallback for any other caller.
    case fit

    /// The multiplier applied to string spacing when computing the per-fret length in `.fit` mode.
    /// Increase this value to make frets longer relative to string spacing.
    public static let fitAspectRatio: CGFloat = 1.5

    /// Computes the per-fret length in points given the available neck-axis length and fret count.
    /// Note: for `.fit`, the real per-fret length is computed inside `FretboardScene.layoutContent()`
    /// where the cross-axis dimension (string spacing) is available. This method returns the
    /// fill-length fallback so other callers remain safe.
    public func fretLength(neckAxisLength: CGFloat, count: Int) -> CGFloat {
        switch self {
        case .fixed(let pts):
            return pts
        case .multiplier(let m):
            return neckAxisLength * max(0, m)
        case .fill, .fit:
            guard count > 0 else { return neckAxisLength }
            return neckAxisLength / CGFloat(count)
        }
    }

    // MARK: Codable

    private enum CodingKeys: String, CodingKey { case type, value }
    // "fit" is kept as a legacy decode tag (it was the old name for `.fill`); new cases use
    // "fill" and "aspectFit" so persisted data from older versions migrates gracefully.
    private enum TypeTag: String, Codable { case fixed, multiplier, fill, aspectFit, fit }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .fixed(let v):
            try c.encode(TypeTag.fixed, forKey: .type)
            try c.encode(v, forKey: .value)
        case .multiplier(let v):
            try c.encode(TypeTag.multiplier, forKey: .type)
            try c.encode(v, forKey: .value)
        case .fill:
            try c.encode(TypeTag.fill, forKey: .type)
        case .fit:
            try c.encode(TypeTag.aspectFit, forKey: .type)
        }
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let tag = try c.decode(TypeTag.self, forKey: .type)
        switch tag {
        case .fixed:
            self = .fixed(try c.decode(CGFloat.self, forKey: .value))
        case .multiplier:
            self = .multiplier(try c.decode(CGFloat.self, forKey: .value))
        case .fill:
            self = .fill
        case .aspectFit:
            self = .fit
        case .fit:
            // Legacy: old persisted "fit" meant fill-the-scene, which is now `.fill`.
            self = .fill
        }
    }
}

// MARK: - FretboardAlignment

/// Where to anchor the fretboard content when it is smaller than the scene.
public enum FretboardAlignment: String, Codable, Hashable, CaseIterable {
    /// Center in the neck axis (default).
    case center
    /// Flush to the nut end (left edge for horizontal, top for vertical).
    case leading
    /// Flush to the far-fret end (right edge for horizontal, bottom for vertical).
    case trailing
}
