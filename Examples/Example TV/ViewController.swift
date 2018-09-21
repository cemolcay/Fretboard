//
//  ViewController.swift
//  Example TV
//
//  Created by Cem Olcay on 09/04/2017.
//
//

import UIKit
import Fretboard
import MusicTheorySwift

class ViewController: UIViewController {
  @IBOutlet weak var verticalFretboard: FretboardView?
  @IBOutlet weak var horizontalFretboard: FretboardView?

  override func viewDidLoad() {
    super.viewDidLoad()

    let chord = Chord(type: ChordType(third: .major), key: Key(type: .a))

    verticalFretboard?.fretboard.direction = .vertical
    verticalFretboard?.fretboard.select(chord: chord)

    horizontalFretboard?.fretboard.direction = .horizontal
    horizontalFretboard?.fretboard.select(chord: chord)
  }
}
