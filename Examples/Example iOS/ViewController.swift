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
    let firstPosition = chord.notes(octaves: fretboardView?.fretboard.octaves ?? [2, 3, 4])
    fretboardView?.fretboard.direction = .vertical
    fretboardView?.fretboard.select(notes: firstPosition)
  }
}

