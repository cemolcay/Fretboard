//
//  ViewController.swift
//  Example Mac
//
//  Created by Cem Olcay on 09/04/2017.
//
//

import Cocoa
import Fretboard
import MusicTheorySwift

class ViewController: NSViewController {
  @IBOutlet weak var fretboardView: FretboardView?

  override func viewDidLoad() {
    super.viewDidLoad()
    view.wantsLayer = true
    view.layer = CALayer()
    fretboardView?.fretboard.select(scale: Scale(type: .major, key: .c))
  }
}
