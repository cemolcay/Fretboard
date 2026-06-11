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
        Fretboard(
            tuning: GuitarTuning.standard,
            startIndex: 0,
            count: 12,
            direction: .horizontal
        )
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
        cfg.fretSizing = .fit
        cfg.isDrawNoteName = true
        cfg.noteColor = FretboardColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1)
        cfg.highlightNoteColor = FretboardColor(red: 0.95, green: 0.35, blue: 0.1, alpha: 1)
        cfg.noteBorderWidth = 1.5
        cfg.noteBorderColor = FretboardColor(white: 0, alpha: 0.2)
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

        for (title, action) in [
            ("C Major Scale",    #selector(selectCMajor)),
            ("A Minor Scale",    #selector(selectAMinor)),
            ("G Major Chord",    #selector(selectGMajorChord)),
            ("Clear",            #selector(clearNotes)),
            ("Toggle Direction", #selector(toggleDirection)),
            ("Toggle Capo Mode", #selector(toggleCapo)),
            ("Drop D Tuning",    #selector(switchToDropD)),
        ] as [(String, Selector)] {
            let btn = UIButton(type: .system)
            btn.setTitle(title, for: .normal)
            btn.addTarget(self, action: action, for: .touchUpInside)
            stack.addArrangedSubview(btn)
        }
    }

    // MARK: Actions

    @objc private func selectCMajor() {
        scene.clearNotes()
        scene.show(scale: Scale(type: .major, root: .c))
    }

    @objc private func selectAMinor() {
        scene.clearNotes()
        scene.show(scale: Scale(type: .naturalMinor, root: .a))
    }

    @objc private func selectGMajorChord() {
        scene.clearNotes()
        scene.show(chord: Chord(type: .major, root: .g))
    }

    @objc private func clearNotes() {
        scene.clearNotes()
    }

    @objc private func toggleDirection() {
        fretboard.direction = fretboard.direction == .horizontal ? .vertical : .horizontal
        // didSet on fretboard.direction calls scene.reload() automatically.
    }

    @objc private func toggleCapo() {
        scene.configuration.isCapoModeOn.toggle()
    }

    @objc private func switchToDropD() {
        fretboard.tuning = GuitarTuning.dropD
        // didSet on fretboard.tuning calls scene.reload() automatically.
    }
}

// MARK: - FretboardSceneDelegate

extension FretboardViewController: FretboardSceneDelegate {

    func fretboardScene(_ scene: FretboardScene, noteOn note: FretboardNote) {
        // Connect to AVAudioEngine, CoreMIDI, or any synth here.
        // The scene already highlights the dot; wire playback here.
        // note.pitch.midiNoteNumber gives you the MIDI pitch (0–127).
        // note.pitch.frequency()    gives the equal-tempered frequency in Hz.
        print("noteOn  \(note.pitch) — MIDI \(note.pitch.midiNoteNumber)")
    }

    func fretboardScene(_ scene: FretboardScene, noteOff note: FretboardNote) {
        print("noteOff \(note.pitch) — MIDI \(note.pitch.midiNoteNumber)")
    }
}

// MARK: - Live MIDI example

extension FretboardViewController {

    /// Call from your CoreMIDI / MIDI receive handler when a note-on arrives.
    func receiveMIDINoteOn(pitch: Pitch) {
        scene.highlightNote(pitch)   // creates a transient dot if the note is off-scale
    }

    /// Call from your CoreMIDI / MIDI receive handler when a note-off arrives.
    func receiveMIDINoteOff(pitch: Pitch) {
        scene.unhighlightNote(pitch) // removes transient dots; dims shown dots
    }
}

// MARK: - Persistence example (save / restore a Fretboard)

extension FretboardViewController {

    func saveFretboard() throws -> Data {
        return try JSONEncoder().encode(fretboard)
    }

    func loadFretboard(from data: Data) throws {
        // Replace the scene's model with a decoded one.
        // Note: shown dots are owned by the scene — you may want to re-show your
        // scale/chord after this using show(scale:) or show(chord:).
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
