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
            direction: .horizontal,
            isChordModeOn: false,
            isCapoOn: true
        )

        var cfg = FretboardConfiguration()
        cfg.fretSizing = .fit
        cfg.noteColor = FretboardColor(red: 0.15, green: 0.6, blue: 0.45, alpha: 1)
        cfg.backgroundColor = FretboardColor(white: 0.97)

        let s = FretboardScene(fretboard: fb, configuration: cfg)
        self.fretboard = fb
        self.scene = s
        s.noteDelegate = self
    }

    // MARK: FretboardSceneDelegate

    func fretboardScene(_ scene: FretboardScene, noteOn note: FretboardNote) {
        lastNoteOn = "\(note.pitch)  (MIDI \(note.pitch.midiNoteNumber))"
    }

    func fretboardScene(_ scene: FretboardScene, noteOff note: FretboardNote) {
        lastNoteOff = "\(note.pitch)  (MIDI \(note.pitch.midiNoteNumber))"
    }

    // MARK: Model mutations — always followed by scene.reload()

    func select(scale: Scale) {
        fretboard.deselectAll()
        fretboard.select(scale: scale)
        scene.reload()
    }

    func select(chord: Chord) {
        fretboard.deselectAll()
        fretboard.select(chord: chord)
        scene.reload()
    }

    func clearSelection() {
        fretboard.deselectAll()
        scene.reload()
    }

    func setTuning(_ tuning: Tuning) {
        fretboard.tuning = tuning
        scene.reload()
    }

    func setDirection(_ direction: FretboardDirection) {
        fretboard.direction = direction
        scene.reload()
    }

    func setFretSizing(_ sizing: FretSizing) {
        scene.configuration.fretSizing = sizing
        scene.reload()
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
                            button("C Major")   { wrapper.select(scale: Scale(type: .major,        root: .c)) }
                            button("A Minor")   { wrapper.select(scale: Scale(type: .naturalMinor, root: .a)) }
                            button("G Blues")   { wrapper.select(scale: Scale(type: .blues,        root: .g)) }
                            button("Clear")     { wrapper.clearSelection() }
                        }
                    }

                    Group {
                        Text("Chords").font(.headline)
                        HStack {
                            button("G maj")  { wrapper.select(chord: Chord(type: .major,      root: .g)) }
                            button("D min")  { wrapper.select(chord: Chord(type: .minor,      root: .d)) }
                            button("E dom7") { wrapper.select(chord: Chord(type: .dominant7,  root: .e)) }
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
                            button("Fit")      { wrapper.setFretSizing(.fit) }
                            button("80 pt")    { wrapper.setFretSizing(.fixed(80)) }
                            button("×0.12")    { wrapper.setFretSizing(.multiplier(0.12)) }
                        }
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
