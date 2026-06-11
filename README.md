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
.package(url: "https://github.com/cemolcay/Fretboard.git", from: "2.0.0")
```

---

## Quick start

```swift
import SpriteKit
import Fretboard

// 1. Create a model (pure geometry — no selection state)
let fretboard = Fretboard(tuning: GuitarTuning.standard, startIndex: 0, count: 12)

// 2. Create the scene
let scene = FretboardScene(fretboard: fretboard)
scene.noteDelegate = self   // optional — for synth/sampler integration

// 3. Present in an SKView (UIKit / AppKit)
skView.presentScene(scene)
// — or — in SwiftUI:
// SpriteView(scene: scene)

// 4. Show notes (scale, chord, or any set of pitches)
scene.show(scale: Scale(type: .major, root: .c))

// 5. Highlight individual notes independently (e.g. live MIDI)
scene.highlightNote(Pitch(noteName: .e, octave: 4))   // creates a dot if not shown
scene.unhighlightNote(Pitch(noteName: .e, octave: 4))
```

---

## Design

The library separates **geometry** from **rendering state**:

- `Fretboard` (model) — pure data: tuning, fret range, direction. Knows nothing about selection or colors.
- `FretboardScene` (scene) — owns all visual state: which dots are shown, which are highlighted, capo-mode rendering.

This lets you combine multiple independent marking layers at once — for example, showing a scale while also reflecting live incoming MIDI notes on top of it.

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
| `notes` | `[FretboardNote]` | Read-only computed pitch grid. |
| `orderedStrings` | `[Pitch]` | Strings in display order (direction-aware). |
| `octaves` | `[Int]` | Unique octaves currently visible, sorted. |

Mutating any property (`tuning`, `startIndex`, `count`, `direction`) rebuilds the note grid and, if the model is wired to a scene, triggers `scene.reload()` automatically via the `fretboard` `didSet`.

**Pitch lookup:**

```swift
// Returns every grid position whose MIDI note number matches `pitch`.
let positions = fretboard.notes(matching: Pitch(noteName: .a, octave: 2))
```

**Persistence:**

```swift
let data = try JSONEncoder().encode(fretboard)   // persists tuning/startIndex/count/direction
let loaded = try JSONDecoder().decode(Fretboard.self, from: data)
scene.fretboard = loaded   // triggers scene.reload() automatically
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

### Showing notes

The scene draws note dots on demand. **A dot's existence = it is "shown."** There is no global selection state in the model.

```swift
// Show individual pitches (exact MIDI match — may appear on multiple strings)
scene.showNote(Pitch(noteName: .c, octave: 4))
scene.showNotes([c4, e4, g4])

// Remove shown dots
scene.hideNote(Pitch(noteName: .c, octave: 4))
scene.clearNotes()
```

**Scale / chord convenience** (expands across the visible octaves automatically):

```swift
scene.show(scale: Scale(type: .major, root: .c))
scene.show(chord: Chord(type: .dominant7, root: .g))
```

### Highlighting notes

Highlighting is independent of the shown set — used for user presses and live MIDI equally.

```swift
// Highlight a pitch. If no dot exists, a transient dot is created.
scene.highlightNote(Pitch(noteName: .e, octave: 4))

// Clear the highlight. Transient dots (created only for the highlight) are removed.
scene.unhighlightNote(Pitch(noteName: .e, octave: 4))
```

A highlighted dot reverts to normal appearance on `unhighlightNote` but is **not** removed if it was part of the shown set.

#### Scale + live MIDI at the same time

```swift
// Show a scale (dots appear for all matching positions)
scene.show(scale: Scale(type: .major, root: .c))

// In your MIDI receive handler — works independently of the scale
func midiNoteOn(pitch: Pitch) {
    scene.highlightNote(pitch)   // off-scale notes get a transient dot
}
func midiNoteOff(pitch: Pitch) {
    scene.unhighlightNote(pitch)
}
```

---

### `FretboardConfiguration` (Codable)

#### Neck

| Property | Default | Description |
|---|---|---|
| `stringColor` | `.black` | String line color. |
| `fretColor` | `.darkGray` | Fret line color. |
| `stringLabelColor` | `.black` | String-name label color. |
| `fretLabelColor` | `.black` | Fret-number label color. |
| `backgroundColor` | `.clear` | Scene background. |
| `stringWidth` | `0.5` | String line width (pt). |
| `fretWidth` | `2` | Fret line width (pt). |
| `nutWidthMultiplier` | `2` | Nut drawn at `fretWidth × nutWidthMultiplier`. |

#### Note dots — normal state

| Property | Default | Description |
|---|---|---|
| `noteColor` | `.black` | Dot fill color. |
| `noteTextColor` | `.white` | Note-name label color inside dots. |
| `noteBorderColor` | `.clear` | Dot border (stroke) color. |
| `noteBorderWidth` | `0` | Dot border width. `0` = no border (opt-in). |

#### Note dots — highlighted state

| Property | Default | Description |
|---|---|---|
| `highlightNoteColor` | orange | Fill color when highlighted. |
| `highlightNoteTextColor` | `.white` | Label color when highlighted. |
| `highlightNoteBorderColor` | `.clear` | Border color when highlighted. |
| `highlightNoteBorderWidth` | `0` | Border width when highlighted (falls back to `noteBorderWidth` if `0`). |

#### Layout & labels

| Property | Default | Description |
|---|---|---|
| `fretSizing` | `.fit` | How large each fret is along the neck axis. |
| `alignment` | `.center` | Where to anchor the board when smaller than the scene. |
| `noteOffset` | `5` | Inset shrinking the dot away from cell edges (pt). |
| `isDrawNoteName` | `true` | Show note-name labels on dots. |
| `isDrawStringName` | `true` | Show string-name labels at the nut. |
| `isDrawFretNumber` | `true` | Show fret-number labels. |

#### Capo visualization

| Property | Default | Description |
|---|---|---|
| `isCapoModeOn` | `false` | When `true`, adjacent shown dots on the same fret merge into a capsule bar resembling a capo. Purely visual — no data-layer state involved. |

```swift
scene.configuration.isCapoModeOn = true
```

### `FretSizing`

```swift
.fit                   // All frets fill the scene exactly (no scroll).
.fixed(CGFloat)        // Fixed points per fret.
.multiplier(CGFloat)   // Fraction of the scene's neck axis per fret.
```

When content overflows the scene pans automatically (drag/scroll — no host scroll view needed).

### `FretboardAlignment`

```swift
.center   // Centered in the neck axis (default).
.leading  // Flush to the nut end.
.trailing // Flush to the far-fret end.
```

---

## Playback (noteOn / noteOff)

Implement `FretboardSceneDelegate` and assign it to `scene.noteDelegate`.  
The delegate fires on **user interaction only** — programmatic `showNote` / `highlightNote` calls do not fire it.

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
- The touched fret is automatically highlighted on press and unhighlighted on release.
- Dragging past a threshold converts the touch to a camera pan and automatically sends `noteOff` — no stuck notes.

---

## FretBud

This library powers [FretBud](https://itunes.apple.com/us/app/fretbud-chord-scales-for-guitar-bass-and-more/id1234224249?mt=8), a chord & scale reference app for guitar, bass, and more.
