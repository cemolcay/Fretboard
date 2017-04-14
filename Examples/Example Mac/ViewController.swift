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

    let chord = Chord(type: .maj, key: .e)
    let firstPosition = chord.notes(octaves: fretboardView?.fretboard.octaves ?? [2, 3, 4])
    fretboardView?.fretboard.direction = .vertical
    fretboardView?.fretboard.startIndex = 0
    fretboardView?.isChordModeOn = true
    fretboardView?.fretboard.select(notes: firstPosition)
  }
}
