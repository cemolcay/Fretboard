//
//  Extensions.swift
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

extension Collection where Indices.Iterator.Element == Index {
  /// Returns the element at the specified index iff it is within bounds, otherwise nil.
  subscript (safe index: Index) -> Generator.Element? {
    return indices.contains(index) ? self[index] : nil
  }
}
