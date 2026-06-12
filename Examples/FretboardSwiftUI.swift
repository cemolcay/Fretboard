//
//  FretboardSwiftUI.swift
//  Fretboard — SwiftUI integration example
//
//  Wrap FretboardScene in a SpriteView and connect it to SwiftUI state.
//  This file is not compiled as part of the package; it is a usage reference.
//

import SwiftUI
import SpriteKit
import MusicTheory
import Fretboard

// MARK: - FretboardSceneWrapper

/// A lightweight SwiftUI-observable wrapper that owns the model and the scene,
/// keeping them in sync without any @Observable machinery.
final class FretboardSceneWrapper: ObservableObject, FretboardSceneDelegate {

    let fretboard: Fretboard
    let scene: FretboardScene

    @Published var lastNoteOn: String = "—"
    @Published var lastNoteOff: String = "—"

    init() {
        let fb = Fretboard(
            tuning: GuitarTuning.standard,
            startIndex: 0,
            count: 12,
            direction: .horizontal
        )

        var cfg = FretboardConfiguration()
        cfg.fretSizing = .fit
        cfg.noteStyle = FretboardNoteStyle(
            color: FretboardColor(red: 0.15, green: 0.6, blue: 0.45, alpha: 1),
            borderColor: FretboardColor(white: 0, alpha: 0.2),
            borderWidth: 1.5
        )
        cfg.highlightNoteStyle = FretboardNoteStyle(
            color: FretboardColor(red: 0.95, green: 0.35, blue: 0.1, alpha: 1)
        )
        cfg.backgroundColor = FretboardColor(white: 0.97)

        let s = FretboardScene(fretboard: fb, configuration: cfg)
        self.fretboard = fb
        self.scene = s
        s.noteDelegate = self
    }

    // MARK: FretboardSceneDelegate

    func fretboardScene(_ scene: FretboardScene, noteOn note: FretboardNote) {
        lastNoteOn = "\(note.pitch)  (MIDI \(note.pitch.midiNoteNumber))"
        // The scene already highlights the touched dot; wire your synth / MIDI output here.
    }

    func fretboardScene(_ scene: FretboardScene, noteOff note: FretboardNote) {
        lastNoteOff = "\(note.pitch)  (MIDI \(note.pitch.midiNoteNumber))"
    }

    // MARK: Scale / chord — scene owns which dots are shown

    func show(scale: Scale) {
        scene.clearNotes()
        scene.showScale(scale)
    }

    func show(chord: Chord) {
        scene.clearNotes()
        scene.showChord(chord)
    }

    func clearSelection() {
        scene.clearNotes()
    }

    // MARK: Live MIDI example
    // Call highlightPitch/unhighlightPitch from your MIDI receiver — no reload needed.

    func midiNoteOn(_ pitch: Pitch) {
        scene.highlightPitch(pitch)   // creates a transient dot if the note is off-scale
    }

    func midiNoteOff(_ pitch: Pitch) {
        scene.unhighlightPitch(pitch) // removes transient dots; dims shown dots
    }

    // MARK: Instrument / layout

    func setTuning(_ tuning: Tuning) {
        fretboard.tuning = tuning    // didSet triggers scene.reload() automatically
    }

    func setDirection(_ direction: FretboardDirection) {
        fretboard.direction = direction
    }

    func setFretSizing(_ sizing: FretSizing) {
        scene.configuration.fretSizing = sizing
    }

    func toggleCapo() {
        scene.configuration.isCapoModeOn.toggle()
    }
}

// MARK: - FretboardView (SwiftUI)

struct FretboardView: View {

    @StateObject private var wrapper = FretboardSceneWrapper()

    var body: some View {
        VStack(spacing: 0) {
            // ── Scene ─────────────────────────────────────────────────────────
            SpriteView(scene: wrapper.scene)
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .cornerRadius(12)
                .padding(.horizontal)

            // ── Controls ──────────────────────────────────────────────────────
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    Group {
                        Text("Scales").font(.headline)
                        HStack {
                            button("C Major")   { wrapper.show(scale: Scale(type: .major,        root: .c)) }
                            button("A Minor")   { wrapper.show(scale: Scale(type: .naturalMinor, root: .a)) }
                            button("G Blues")   { wrapper.show(scale: Scale(type: .blues,        root: .g)) }
                            button("Clear")     { wrapper.clearSelection() }
                        }
                    }

                    Group {
                        Text("Chords").font(.headline)
                        HStack {
                            button("G maj")  { wrapper.show(chord: Chord(type: .major,      root: .g)) }
                            button("D min")  { wrapper.show(chord: Chord(type: .minor,      root: .d)) }
                            button("E dom7") { wrapper.show(chord: Chord(type: .dominant7,  root: .e)) }
                        }
                    }

                    Group {
                        Text("Live MIDI simulation").font(.headline)
                        Text("(In a real app these would fire from your MIDI receive handler)")
                            .font(.caption).foregroundColor(.secondary)
                        HStack {
                            button("NoteOn C4")  { wrapper.midiNoteOn(Pitch(noteName: .c,  octave: 4)) }
                            button("NoteOn F#3") { wrapper.midiNoteOn(Pitch(noteName: .gb, octave: 3)) }
                            button("Off all") {
                                wrapper.midiNoteOff(Pitch(noteName: .c,  octave: 4))
                                wrapper.midiNoteOff(Pitch(noteName: .gb, octave: 3))
                            }
                        }
                    }

                    Group {
                        Text("Tuning").font(.headline)
                        HStack {
                            button("Standard") { wrapper.setTuning(GuitarTuning.standard) }
                            button("Drop D")   { wrapper.setTuning(GuitarTuning.dropD) }
                            button("Open G")   { wrapper.setTuning(GuitarTuning.openG) }
                            button("Bass")     { wrapper.setTuning(BassTuning.standard4String) }
                        }
                    }

                    Group {
                        Text("Direction").font(.headline)
                        HStack {
                            button("Horizontal") { wrapper.setDirection(.horizontal) }
                            button("Vertical")   { wrapper.setDirection(.vertical) }
                        }
                    }

                    Group {
                        Text("Fret sizing").font(.headline)
                        HStack {
                            button("Fit")   { wrapper.setFretSizing(.fit) }
                            button("80 pt") { wrapper.setFretSizing(.fixed(80)) }
                            button("×0.12") { wrapper.setFretSizing(.multiplier(0.12)) }
                        }
                    }

                    Group {
                        Text("Capo mode").font(.headline)
                        button("Toggle capo") { wrapper.toggleCapo() }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Last noteOn:  \(wrapper.lastNoteOn)").font(.caption).foregroundColor(.secondary)
                        Text("Last noteOff: \(wrapper.lastNoteOff)").font(.caption).foregroundColor(.secondary)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Fretboard")
    }

    @ViewBuilder
    private func button(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.bordered)
            .controlSize(.small)
    }
}

// MARK: - Persistence example

extension FretboardSceneWrapper {

    func encodeCurrentState() throws -> Data {
        try JSONEncoder().encode(fretboard)
    }

    func restoreState(from data: Data) throws {
        // Decode into a new Fretboard and hot-swap it into the scene.
        // Note: shown dots are owned by the scene — you may want to re-show your scale/chord
        // after this using showScale(_:) or showChord(_:).
        let restored = try JSONDecoder().decode(Fretboard.self, from: data)
        scene.fretboard = restored   // triggers scene.reload() automatically
        objectWillChange.send()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FretboardView()
    }
}
