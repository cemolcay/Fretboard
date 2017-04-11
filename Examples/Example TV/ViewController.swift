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

    let chord = Chord(type: .maj, key: .a)
    let firstPosition = chord.notes(octaves: [2, 3, 4])

    verticalFretboard?.fretboard.direction = .vertical
    verticalFretboard?.fretboard.select(notes: firstPosition)

    horizontalFretboard?.fretboard.direction = .horizontal
    horizontalFretboard?.fretboard.select(notes: firstPosition)
  }
}
