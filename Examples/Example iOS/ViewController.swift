//
//  ViewController.swift
//  Example iOS
//
//  Created by Cem Olcay on 09/04/2017.
//
//

import UIKit
import Fretboard
import MusicTheorySwift

class ViewController: UIViewController {
  @IBOutlet weak var fretboardView: FretboardView?

  override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
    fretboardView?.fretboard.direction = fromInterfaceOrientation.isLandscape ? .vertical : .horizontal
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let chord = Chord(type: .maj, key: .a)
    fretboardView?.fretboard.select(chord: chord)
  }
}

