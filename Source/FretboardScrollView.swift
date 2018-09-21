//
//  FretboardScrollView.swift
//  FretBud
//
//  Created by Cem Olcay on 01/05/2017.
//
//

#if os(iOS) || os(tvOS)
  import UIKit
#elseif os(OSX)
  import AppKit
#endif

#if os(iOS) || os(tvOS)
  typealias FRScrollView = UIScrollView
#elseif os(OSX)
  typealias FRScrollView = NSScrollView
#endif

@IBDesignable
class FretboardScrollView: FRScrollView {
  @IBInspectable var fretboardView = FretboardView(frame: .zero) { didSet { updateLayout() }}
  @IBInspectable var aspectRatio: CGFloat = 0.225 { didSet { updateLayout() }}

  // MARK: Init

  #if os(iOS) || os(tvOS)
    override init(frame: CGRect) {
      super.init(frame: frame)
      commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
      commonInit()
    }
  #elseif os(OSX)
    override init(frame frameRect: NSRect) {
      super.init(frame: frameRect)
      commonInit()
    }

    required init?(coder: NSCoder) {
      super.init(coder: coder)
      commonInit()
    }
  #endif

  private func commonInit() {
    #if os(iOS) || os(tvOS)
      addSubview(fretboardView)
      #if os(tvOS)
      panGestureRecognizer.allowedTouchTypes = [NSNumber(integerLiteral: UITouch.TouchType.indirect.rawValue)]
      #endif
    #elseif os(OSX)
      documentView?.addSubview(fretboardView)
    #endif
  }

  // MARK: Lifecycle

  #if os(tvOS)
    override var canBecomeFocused: Bool {
      return true
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
      super.didUpdateFocus(in: context, with: coordinator)
      if context.nextFocusedView == self {
        layer.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.4).cgColor
        layer.cornerRadius = 10
        layer.masksToBounds = true
      } else if context.previouslyFocusedView == self {
        layer.backgroundColor = UIColor.clear.cgColor
      }
    }
  #endif

  // MARK: Layout

  #if os(iOS) || os(tvOS)
    override func layoutSubviews() {
      super.layoutSubviews()
      layoutFretboard()
    }
  #elseif os(OSX)
    override func layout() {
      super.layout()
      layoutFretboard()
    }
  #endif

  private func updateLayout() {
    #if os(iOS) || os(tvOS)
      setNeedsLayout()
    #elseif os(OSX)
      needsLayout = true
    #endif
  }

  private func layoutFretboard() {
    let fretCount = CGFloat(fretboardView.fretboard.count)
    #if os(iOS) || os(tvOS)
      let width = frame.size.width
      let height = frame.size.height
    #elseif os(OSX)
      let width = contentView.frame.size.width
      let height = contentView.frame.size.height
    #endif
    switch fretboardView.fretboard.direction {
    case .horizontal:
      let fretSize = frame.size.height * aspectRatio
      fretboardView.frame = CGRect(x: 0, y: 0, width: fretSize * fretCount, height: height)
    case .vertical:
      let fretSize = frame.size.width * aspectRatio
      fretboardView.frame = CGRect(x: 0, y: 0, width: width, height: fretSize * fretCount)
    }
    #if os(iOS) || os(tvOS)
      contentSize = fretboardView.frame.size
    #elseif os(OSX)
      documentView?.frame.size = fretboardView.frame.size
    #endif
  }
}
