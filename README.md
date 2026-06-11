# Fretboard

A SpriteKit-based fretboard library for iOS, iPadOS, macOS, tvOS, and visionOS.  
Built on [MusicTheory](https://github.com/cemolcay/MusicTheory) v2.0.

---

## Requirements

- Swift 5.9+
- iOS 13+ / macOS 10.15+ / tvOS 13+ / visionOS 1+

---

## Install (Swift Package Manager)

```swift
// Package.swift
.package(url: "https://github.com/cemolcay/Fretboard.git", from: "1.0.0")
```

---

## Quick start

```swift
import SpriteKit
import Fretboard

// 1. Create a model
let fretboard = Fretboard(tuning: GuitarTuning.standard, startIndex: 0, count: 5)

// 2. Create the scene
let scene = FretboardScene(fretboard: fretboard)
scene.noteDelegate = self          // optional — for synth/sampler integration

// 3. Present in an SKView (UIKit / AppKit)
skView.presentScene(scene)
// — or — in SwiftUI:
// SpriteView(scene: scene)
```

After changing the model, call `scene.reload()`:

```swift
fretboard.tuning = GuitarTuning.dropD
fretboard.count = 12
scene.reload()
```

---

## Model

### `Fretboard`

`Codable final class` — the consuming app owns it, reads it, writes it.

| Property | Type | Description |
|---|---|---|
| `tuning` | `Tuning` | Open-string pitches. Default: standard guitar. |
| `startIndex` | `Int` | First fret shown. 0 = open strings. |
| `count` | `Int` | Number of frets shown. |
| `direction` | `FretboardDirection` | `.horizontal` or `.vertical`. |
| `isChordModeOn` | `Bool` | Only the lowest selected fret per string is rendered. |
| `isCapoOn` | `Bool` | Adjacent selected notes on the same fret form a capo bar. |
| `notes` | `[FretboardNote]` | Read-only computed grid. |

**Note selection** (pitch-class matching — enharmonic spellings light up correctly):

```swift
fretboard.select(scale: Scale(type: .major, root: .c))
fretboard.select(chord: Chord(type: .dominant7, root: .g))
fretboard.select(pitch: Pitch(noteName: .a, octave: 4))
fretboard.deselectAll()
```

**Persistence:**

```swift
let data = try JSONEncoder().encode(fretboard)
let loaded = try JSONDecoder().decode(Fretboard.self, from: data)
```

---

### `Tuning`

`Codable struct { var name: String; var strings: [Pitch] }` — uniform for built-ins and custom:

```swift
// Built-in
fretboard.tuning = GuitarTuning.standard       // E2 A2 D3 G3 B3 E4
fretboard.tuning = BassTuning.standard4String   // E1 A1 D2 G2
fretboard.tuning = UkuleleTuning.standard       // G4 C4 E4 A4

// All built-in guitar tunings
let allGuitar: [Tuning] = GuitarTuning.all

// Custom (persists exactly like built-ins)
let custom = Tuning(name: "Open G Slide", strings: [
    Pitch(noteName: .d, octave: 2),
    Pitch(noteName: .g, octave: 2),
    Pitch(noteName: .d, octave: 3),
    Pitch(noteName: .g, octave: 3),
    Pitch(noteName: .b, octave: 3),
    Pitch(noteName: .d, octave: 4),
])
fretboard.tuning = custom
```

---

## Scene

### `FretboardScene`

```swift
let scene = FretboardScene(
    fretboard: fretboard,
    configuration: FretboardConfiguration()   // optional
)
```

### `FretboardConfiguration` (Codable)

| Property | Default | Description |
|---|---|---|
| `fretSizing` | `.fit` | How large each fret is along the neck axis. |
| `alignment` | `.center` | Where to anchor the board when smaller than the scene. |
| `isDrawNoteName` | `true` | Show note-name labels on selected dots. |
| `isDrawStringName` | `true` | Show string-name labels at the nut. |
| `isDrawFretNumber` | `true` | Show fret-number labels. |
| `stringColor` | `.black` | String line color. |
| `fretColor` | `.darkGray` | Fret line color. |
| `noteColor` | `.black` | Selected note dot fill. |
| `noteTextColor` | `.white` | Label color inside dots. |
| `stringWidth` | `0.5` | String line width (pt). |
| `fretWidth` | `2` | Fret line width (pt). |

### `FretSizing`

```swift
.fit                   // All frets fill the scene exactly (no scroll).
.fixed(CGFloat)        // Fixed points per fret.
.multiplier(CGFloat)   // Fraction of the scene's neck axis per fret.
```

When content overflows, the scene pans automatically (drag/scroll — no host scroll view needed).

### `FretboardAlignment`

```swift
.center   // Centered in the neck axis (default).
.leading  // Flush to the nut end.
.trailing // Flush to the far-fret end.
```

---

## Playback (noteOn / noteOff)

Implement `FretboardSceneDelegate` and assign it to `scene.noteDelegate`:

```swift
class MyViewController: UIViewController, FretboardSceneDelegate {
    func fretboardScene(_ scene: FretboardScene, noteOn note: FretboardNote) {
        midiOut.send(noteOn: note.pitch.midiNoteNumber, velocity: 100, channel: 0)
    }
    func fretboardScene(_ scene: FretboardScene, noteOff note: FretboardNote) {
        midiOut.send(noteOff: note.pitch.midiNoteNumber, channel: 0)
    }
}
```

- **noteOn** fires immediately on touch-down for minimum latency.
- **noteOff** fires on touch-up or cancel.
- **Polyphonic** on iOS/visionOS (each finger tracked independently).
- Dragging past a threshold converts the touch to a camera pan and automatically sends `noteOff` — no stuck notes.

---

## FretBud

This library powers [FretBud](https://itunes.apple.com/us/app/fretbud-chord-scales-for-guitar-bass-and-more/id1234224249?mt=8), a chord & scale reference app for guitar, bass, and more.
