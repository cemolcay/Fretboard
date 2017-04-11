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

    let chord = Chord(type: .maj, key: .b)
    let firstPosition = chord.notes(octaves: 2, 3, 4)
    print(firstPosition)
    fretboardView?.fretboard.select(notes: firstPosition)
//    fretboardView?.fretboard.select(scale: Scale(type: .major, key: .c))
  }
}
