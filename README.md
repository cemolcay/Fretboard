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
scene.showScale(Scale(type: .major, root: .c))

// 5. Highlight individual notes (e.g. live MIDI)
scene.highlightPitch(Pitch(noteName: .e, octave: 4))   // creates a dot if not shown
scene.unhighlightPitch(Pitch(noteName: .e, octave: 4))
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

---

### Showing notes

The marking API is split by targeting:

#### Pitch — every matching position

Shows a dot at **every** board position whose MIDI number matches the pitch.
Use this for scales, chords, and any display where all octave positions should light up.

```swift
scene.showPitch(Pitch(noteName: .c, octave: 4))          // all C4s on the neck
scene.showPitches([c4, e4, g4])

scene.hidePitch(Pitch(noteName: .c, octave: 4))
scene.clearNotes()     // removes shown set; live highlights survive as transient
scene.removeAllNotes() // unconditional wipe
```

**Theory conveniences** (expand across all visible octaves automatically):

```swift
scene.showScale(Scale(type: .major, root: .c))
scene.showChord(Chord(type: .dominant7, root: .g))
```

#### Note — one exact string + fret position

Shows a dot at **one specific** string+fret. Use this for CAGED boxes, chord voicings, and
any display where the physical fingering matters — not just which pitch sounds.

`FretboardNote` values come from `fretboard.notes` or `fretboard.notes(matching:)`.

```swift
scene.showNote(specificFretboardNote)
scene.showNotes(boxNotes)   // a set of specific positions

scene.hideNote(specificFretboardNote)
```

**Chord shape example:**

```swift
// Show only the notes of one specific G major open chord voicing:
let voicingIDs = ["5-2", "4-2", "3-0", "2-0", "1-0", "0-3"]  // "stringIndex-fretIndex"
let voicingNotes = fretboard.notes.filter { voicingIDs.contains($0.id) }
scene.showNotes(voicingNotes)
```

---

### Highlighting notes

Highlighting is independent of the shown set — used for user presses and live MIDI equally.

```swift
// Pitch-based (highlights every matching position)
scene.highlightPitch(Pitch(noteName: .e, octave: 4))   // creates transient dot if not shown
scene.unhighlightPitch(Pitch(noteName: .e, octave: 4)) // removes transient dots; dims shown ones

// Position-based (highlights exactly one string+fret)
scene.highlightNote(specificFretboardNote)
scene.unhighlightNote(specificFretboardNote)
```

A highlighted dot reverts to normal appearance on `unhighlight…` but is **not** removed if it was part of the shown set.

**Scale + live MIDI at the same time:**

```swift
scene.showScale(Scale(type: .major, root: .c))

func midiNoteOn(pitch: Pitch) {
    scene.highlightPitch(pitch)   // off-scale notes get a transient dot
}
func midiNoteOff(pitch: Pitch) {
    scene.unhighlightPitch(pitch)
}
```

---

### Per-note styling — `FretboardNoteStyle`

Every show/highlight call accepts an optional `FretboardNoteStyle`. The style overrides
specific visual properties for those dots; `nil` fields inherit from the configuration
default, which in turn inherits from the library's built-in defaults.

**Resolution order:**  
`per-note override → config.noteStyle / highlightNoteStyle → FretboardNoteStyle.defaultNote / .defaultHighlight`

```swift
public struct FretboardNoteStyle: Codable, Hashable {
    public var color: FretboardColor?       // dot fill
    public var textColor: FretboardColor?
    public var borderColor: FretboardColor?
    public var borderWidth: CGFloat?
    public var label: String?               // nil = note name, "" = hide, "♭3" = custom text
}
```

**Label semantics:**
- `nil` → use the note name (e.g. "C", "F#")
- `""` (empty) → hide the label for this dot, even if `isDrawNoteName` is on
- any other string → render that string (degree numbers, interval names, finger numbers…)

**Degree coloring example:**

```swift
let degreeColors: [Int: FretboardColor] = [
    1: FretboardColor(red: 1,   green: 0.3, blue: 0.3, alpha: 1),  // root = red
    3: FretboardColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 1),  // third = green
    5: FretboardColor(red: 0.3, green: 0.5, blue: 1.0, alpha: 1),  // fifth = blue
]

for noteName in scale.noteNames {
    for octave in fretboard.octaves {
        let pitch = Pitch(noteName: noteName, octave: octave)
        if let degree = scale.degree(of: noteName) {
            scene.showPitch(pitch, style: FretboardNoteStyle(
                color: degreeColors[degree],
                label: "\(degree)"
            ))
        }
    }
}
// Scale changed → scene.removeAllNotes(); re-run loop.
```

**AUv3 MIDI in-vs-out-of-scale coloring:**

```swift
let inScale  = FretboardNoteStyle(color: FretboardColor(red: 0.2, green: 0.85, blue: 0.4, alpha: 1))
let outScale = FretboardNoteStyle(color: FretboardColor(red: 0.9, green: 0.2,  blue: 0.2, alpha: 1))

func midiNoteOn(pitch: Pitch) {
    let isInScale = currentScale.noteNames.contains(pitch.noteName)
    scene.highlightPitch(pitch, style: isInScale ? inScale : outScale)
}
```

---

### Fret inlay markers

The app decides which frets get inlays and which style; the library renders them.
Inlays survive `scene.reload()` — call these once after setup.

```swift
public enum FretInlay { case single, double }

// Standard guitar layout:
[3, 5, 7, 9, 15, 17, 19, 21].forEach { scene.showFretInlay(at: $0) }
[12, 24].forEach { scene.showFretInlay(at: $0, .double) }

// Manage individually:
scene.hideFretInlay(at: 12)
scene.clearFretInlays()
```

The dot color comes from `configuration.fretMarkerColor` (default: `.lightGray`).

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

#### Note dot styles

| Property | Default | Description |
|---|---|---|
| `noteStyle` | `.defaultNote` | Style for all dots in their normal state. All fields optional — `nil` falls back to built-in. |
| `highlightNoteStyle` | `.defaultHighlight` | Style for all dots when highlighted. |
| `fretMarkerColor` | `.lightGray` | Fill color for fret inlay markers. |

**Built-in defaults:**

| | `defaultNote` | `defaultHighlight` |
|---|---|---|
| `color` | `.black` | orange |
| `textColor` | `.white` | `.white` |
| `borderColor` | `.clear` | `.clear` |
| `borderWidth` | `0` | `0` |

Setting properties on `noteStyle` or `highlightNoteStyle` overrides just those fields:

```swift
var cfg = FretboardConfiguration()
// Custom normal dot: dark blue fill, white text, subtle border
cfg.noteStyle = FretboardNoteStyle(
    color: FretboardColor(red: 0.15, green: 0.3, blue: 0.8, alpha: 1),
    textColor: .white,
    borderColor: FretboardColor(white: 0, alpha: 0.2),
    borderWidth: 1.5
)
// Custom highlight: vivid orange (textColor/border inherit from default)
cfg.highlightNoteStyle = FretboardNoteStyle(
    color: FretboardColor(red: 0.95, green: 0.35, blue: 0.1, alpha: 1)
)
```

Individual show/highlight calls can further override specific dots:

```swift
scene.showPitch(rootPitch, style: FretboardNoteStyle(color: .init(red: 1, green: 0.3, blue: 0.3, alpha: 1), label: "1"))
// All other pitches use config.noteStyle defaults.
```

#### Layout & labels

| Property | Default | Description |
|---|---|---|
| `fretSizing` | `.fit` | How large each fret is along the neck axis. |
| `alignment` | `.center` | Where to anchor the board when smaller than the scene. |
| `noteOffset` | `5` | Inset shrinking the dot away from cell edges (pt). |
| `isDrawNoteName` | `true` | Show note-name labels on dots globally. Per-note `label` overrides this. |
| `isDrawStringName` | `true` | Show string-name labels at the nut. |
| `isDrawFretNumber` | `true` | Show fret-number labels. |

#### Capo visualization

| Property | Default | Description |
|---|---|---|
| `isCapoModeOn` | `false` | When `true`, adjacent shown dots on the same fret merge into a capsule bar. Purely visual. |

```swift
scene.configuration.isCapoModeOn = true
```

### `FretSizing`

```swift
.fit                   // All frets fill the scene exactly (no scroll).
.fixed(CGFloat)        // Fixed points per fret.
.multiplier(CGFloat)   // Fraction of the scene's neck axis per fret.
```

When content overflows, the scene enters scroll mode automatically (drag to pan — no host scroll view needed). When it fits, glide mode activates. See **Scroll vs. glide mode** in the Playback section.

### `FretboardAlignment`

```swift
.center   // Centered in the neck axis (default).
.leading  // Flush to the nut end.
.trailing // Flush to the far-fret end.
```

---

## Playback (noteOn / noteOff)

Implement `FretboardSceneDelegate` and assign it to `scene.noteDelegate`.  
The delegate fires on **user interaction only** — programmatic `showPitch` / `highlightPitch` calls do not fire it.

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
- **Polyphonic** — each finger is tracked independently, so chords and multi-touch glide both work.
- The touched fret is automatically highlighted on press and unhighlighted on release.

**Scroll vs. glide mode** — determined automatically by whether the neck content fits in the scene:

| Mode | When | Drag behaviour |
|---|---|---|
| **Glide** | Neck fits the scene (no overflow) | Dragging slides across notes — `noteOff` fires as the finger leaves a fret, `noteOn` fires as it enters the next. |
| **Scroll** | Neck overflows the scene | Dragging pans the neck after a short threshold; `noteOff` fires on conversion so notes never get stuck. |

Override at any time via `isScrollingEnabled`:

```swift
// Lock a long neck into glide mode (e.g. via a lock button)
scene.isScrollingEnabled = false

// Restore automatic behaviour
scene.isScrollingEnabled = true   // or call scene.reload() to re-detect from geometry
```

---

## FretBud

This library powers [FretBud](https://itunes.apple.com/us/app/fretbud-chord-scales-for-guitar-bass-and-more/id1234224249?mt=8), a chord & scale reference app for guitar, bass, and more.
