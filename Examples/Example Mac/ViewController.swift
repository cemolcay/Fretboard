//
//  ViewController.swift
//  Example Mac
//
//  Created by Cem Olcay on 09/04/2017.
//
//

import Cocoa
import Fretboard

class ViewController: NSViewController {
  var fretboard = Fretboard()

  override func viewDidLoad() {
    super.viewDidLoad()

    fretboard.count = 21
    let notes = fretboard.notes
    var strings = ""
    for string in notes {
      var row = ""
      for note in string {
        row += "\(note.note)\t"
      }
      strings += "\(row)\n"
    }
    print(strings)
  }
}
