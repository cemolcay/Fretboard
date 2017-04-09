//
//  Fretboard.swift
//  Fretboard
//
//  Created by Cem Olcay on 09/04/2017.
//
//

#if os(iOS) || os(tvOS)
  import UIKit
#elseif os(OSX)
  import AppKit
#endif
import MusicTheorySwift

#if os(iOS) || os(tvOS)
  typealias FRView = UIView
  typealias FRColor = UIColor
  typealias FRFont = UIFont
  typealias FRBezierPath = UIBezierPath
#elseif os(OSX)
  typealias FRView = NSView
  typealias FRColor = NSColor
  typealias FRFont = NSFont
  typealias FRBezierPath = NSBezierPath
#endif
