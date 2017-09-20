Fretboard
===

Customisable guitar fretboard view for iOS, tvOS and macOS with CoreGraphics.

Demo
----

### Mac

![alt tag](https://github.com/cemolcay/Fretboard/blob/master/Examples/mac_horizontal.png?raw=true)

![alt tag](https://github.com/cemolcay/Fretboard/blob/master/Examples/mac_vertical.png?raw=true)
    
### iOS

![alt tag](https://github.com/cemolcay/Fretboard/blob/master/Examples/ios.png?raw=true)

### Apple TV

![alt tag](https://github.com/cemolcay/Fretboard/blob/master/Examples/tv.png?raw=true)

### Storyboard

![alt tag](https://github.com/cemolcay/Fretboard/blob/master/Examples/ib.png?raw=true)

Requierments
----

* Swift 3.0+
* iOS 8.0+
* tvOS 9.0+
* macOS 10.9+

Install
----

```
use_frameworks!
pod 'Fretboard'
```

Usage
----

Create a `FretboardView`, subclass of `UIView` with code or from storyboard.  

### Note selection

Fretboard uses [`MusicTheory`](https://github.com/cemolcay/MusicTheory) library to render scales, chords or notes.  
You need to select/unselect notes, chords or scales on `fretboard` property of your `FretboardView` instance.  

``` swift
let chord = Chord(type: .maj, key: .a)
fretboardView?.fretboard.select(chord: chord)

let scale = Scale(type: .major, key: .e)
fretboardView?.fretboard.select(scale: scale)

let note = Note(type: .a, octave: 2)
fretboardView?.fretboard.select(note: note)

fretboardView?.fretboard.unselect(note: note)
fretboardView?.fretboard.unselectAll()
```

You could also set `isChordModeOn` property to true, if you want the render only lowest pitch on a string.  
I recommend 3, 4 or 5 frets to use that feature.

### Tuning

Fretboard has a neat tuning property which is a `FretboardTuning` protocol, lets you define strings and their represented notes on fretboard.  
It has a bunch of premade tunings in `GuitarTuning`, `BassTuning` and `UkeleleTuning` enums.  
Also, you can define custom tunings with `CustomTuning` struct with custom string count as well.

``` swift
let tuning = CustomTuning(
  strings: [
    Note(type: .g, octave: 2),
    Note(type: .d, octave: 2),
    Note(type: .a, octave: 1),
    Note(type: .e, octave: 1)
  ], 
  description: "My Custom Tuning")
fretboardView?.fretboard.tuning = tuning
```

### Direction

You could render fretboard either horizontal or vertical with `direction` property on fretboard of type `FretboardDirection`.

``` swift
freboardView?.fretboard.direction = .horizontal
freboardView?.fretboard.direction = .vertical
```

### Frets 

You could render any range of fretboard with `startIndex` and `count` properties on fretboard.  
`startIndex` is the starting fret and 0 is open string, defaults 0.  
`count` is the fret count and defaults 5.

### Customisation

You could change the line widths and colors of frets and strings.  
You could change the colors of fret numbers, string names, notes from code or storyboard.  
Rendering note names on pressed notes and optional.  
Also rendering fret numbers and strings names are optional too.  
See the properties of `FretboardView`.

FretBud
----

This library is used in my iOS/tvOS app [FretBud](https://itunes.apple.com/us/app/fretbud-chord-scales-for-guitar-bass-and-more/id1234224249?mt=8), check it out!  
  
[![alt tag](https://linkmaker.itunes.apple.com/assets/shared/badges/en-us/appstore-lrg.svg)](https://itunes.apple.com/us/app/fretbud-chord-scales-for-guitar-bass-and-more/id1234224249?mt=8)
