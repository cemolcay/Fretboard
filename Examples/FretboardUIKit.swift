//
//  FretboardUIKit.swift
//  Fretboard — UIKit integration example
//
//  Drop FretboardScene into a UIViewController via SKView (iOS / tvOS / visionOS).
//  This file is not compiled as part of the package; it is a usage reference.
//

import UIKit
import SpriteKit
import MusicTheory
import Fretboard

// MARK: - FretboardViewController

class FretboardViewController: UIViewController {

    // MARK: Outlets

    private let skView = SKView()
    private var scene: FretboardScene!

    // MARK: Model

    private let fretboard: Fretboard = {
        let fb = Fretboard(
            tuning: GuitarTuning.standard,
            startIndex: 0,
            count: 12,
            direction: .horizontal,
            isChordModeOn: false,
            isCapoOn: true
        )
        return fb
    }()

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupSKView()
        setupScene()
        setupControls()
    }

    // MARK: SKView setup

    private func setupSKView() {
        skView.translatesAutoresizingMaskIntoConstraints = false
        skView.ignoresSiblingOrder = true
        skView.allowsTransparency = true
        view.addSubview(skView)
        NSLayoutConstraint.activate([
            skView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            skView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            skView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            skView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.4),
        ])
    }

    private func setupScene() {
        var cfg = FretboardConfiguration()
        cfg.fretSizing = .fit              // All 12 frets fill the scene width
        cfg.isDrawNoteName = true
        cfg.noteColor = FretboardColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1)
        cfg.stringColor = .darkGray
        cfg.backgroundColor = FretboardColor(white: 0.96)

        scene = FretboardScene(fretboard: fretboard, configuration: cfg)
        scene.noteDelegate = self

        skView.presentScene(scene)
    }

    // MARK: Controls

    private func setupControls() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: skView.bottomAnchor, constant: 20),
        ])

        // Scale selection
        for (title, action) in [
            ("C Major",         #selector(selectCMajor)),
            ("A Minor",         #selector(selectAMinor)),
            ("G Major Chord",   #selector(selectGMajorChord)),
            ("Clear",           #selector(clearSelection)),
            ("Toggle Direction",#selector(toggleDirection)),
        ] as [(String, Selector)] {
            let btn = UIButton(type: .system)
            btn.setTitle(title, for: .normal)
            btn.addTarget(self, action: action, for: .touchUpInside)
            stack.addArrangedSubview(btn)
        }

        // Tuning picker
        let tuningBtn = UIButton(type: .system)
        tuningBtn.setTitle("Drop D", for: .normal)
        tuningBtn.addTarget(self, action: #selector(switchToDropD), for: .touchUpInside)
        stack.addArrangedSubview(tuningBtn)
    }

    // MARK: Actions

    @objc private func selectCMajor() {
        fretboard.deselectAll()
        fretboard.select(scale: Scale(type: .major, root: .c))
        scene.reload()
    }

    @objc private func selectAMinor() {
        fretboard.deselectAll()
        fretboard.select(scale: Scale(type: .naturalMinor, root: .a))
        scene.reload()
    }

    @objc private func selectGMajorChord() {
        fretboard.deselectAll()
        fretboard.select(chord: Chord(type: .major, root: .g))
        scene.reload()
    }

    @objc private func clearSelection() {
        fretboard.deselectAll()
        scene.reload()
    }

    @objc private func toggleDirection() {
        fretboard.direction = fretboard.direction == .horizontal ? .vertical : .horizontal
        scene.reload()
    }

    @objc private func switchToDropD() {
        fretboard.tuning = GuitarTuning.dropD
        scene.reload()
    }
}

// MARK: - FretboardSceneDelegate

extension FretboardViewController: FretboardSceneDelegate {

    func fretboardScene(_ scene: FretboardScene, noteOn note: FretboardNote) {
        // Connect to AVAudioEngine, CoreMIDI, or any synth here.
        // note.pitch.midiNoteNumber gives you the MIDI pitch (0–127).
        // note.pitch.frequency()    gives the equal-tempered frequency in Hz.
        print("noteOn  \(note.pitch) — MIDI \(note.pitch.midiNoteNumber)")
    }

    func fretboardScene(_ scene: FretboardScene, noteOff note: FretboardNote) {
        print("noteOff \(note.pitch) — MIDI \(note.pitch.midiNoteNumber)")
    }
}

// MARK: - Persistence example (save / restore a Fretboard)

extension FretboardViewController {

    func saveFretboard() throws -> Data {
        return try JSONEncoder().encode(fretboard)
    }

    func loadFretboard(from data: Data) throws {
        // Replace the scene's model with a decoded one.
        let loaded = try JSONDecoder().decode(Fretboard.self, from: data)
        scene.fretboard = loaded   // triggers scene.reload() automatically
    }

    func saveCustomTuning() throws -> Data {
        let custom = Tuning(name: "My Open G", strings: [
            Pitch(noteName: .d, octave: 2),
            Pitch(noteName: .g, octave: 2),
            Pitch(noteName: .d, octave: 3),
            Pitch(noteName: .g, octave: 3),
            Pitch(noteName: .b, octave: 3),
            Pitch(noteName: .d, octave: 4),
        ])
        return try JSONEncoder().encode(custom)
    }
}
