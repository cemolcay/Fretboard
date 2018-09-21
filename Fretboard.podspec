#
#  Be sure to run `pod spec lint Fretboard.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  s.name         = "Fretboard"
  s.version      = "0.0.2"
  s.summary      = "Customisable guitar fretboard view for iOS, tvOS and macOS with CoreGraphics"

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  s.description  = <<-DESC
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

* Swift 4.0+
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

```
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

Fretboard has a neat tuning property which is a `FretboardTuning` protocol, lets you define strings and their reprented notes on fretboard.
It has a bunch of premade tunings in `GuitarTuning`, `BassTuning` and `UkeleleTuning` enums.
Also, you can define custom tunings with `CustomTuning` struct with custom string count as well.

```
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

```
freboardView?.fretboard.direction = .horizontal
freboardView?.fretboard.direction = .vertical
```

### Frets

You could render any range of fretboard with `startIndex` and `count` properties on fretboard.
`startIndex` is the start fret and 0 is open string, defaults 0.
`count` is the fret count and defaults 5.

### Customisation

You could change the line widths and colors of frets and strings.
You could change the colors of fret numbers, string names, notes from code or storyboard.
Rendering note names on pressed notes and optional.
Also rendering fret numbers and strings names are optional too.
See the properties of `FretboardView`.
DESC

  s.homepage     = "https://github.com/cemolcay/Fretboard"
  # s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"


  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Licensing your code is important. See http://choosealicense.com for more info.
  #  CocoaPods will detect a license file if there is a named LICENSE*
  #  Popular ones are 'MIT', 'BSD' and 'Apache License, Version 2.0'.
  #

  s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }


  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the authors of the library, with email addresses. Email addresses
  #  of the authors are extracted from the SCM log. E.g. $ git log. CocoaPods also
  #  accepts just a name if you'd rather not provide an email address.
  #
  #  Specify a social_media_url where others can refer to, for example a twitter
  #  profile URL.
  #

  s.author             = { "cemolcay" => "ccemolcay@gmail.com" }
  # Or just: s.author    = "cemolcay"
  # s.authors            = { "cemolcay" => "ccemolcay@gmail.com" }
  s.social_media_url   = "http://twitter.com/cemolcay"

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If this Pod runs only on iOS or OS X, then specify the platform and
  #  the deployment target. You can optionally include the target after the platform.
  #

  # s.platform     = :ios
  # s.platform     = :ios, "5.0"

  #  When using multiple platforms
  s.ios.deployment_target = "9.0"
  s.osx.deployment_target = "10.9"
  # s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target = "9.0"


  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the location from where the source should be retrieved.
  #  Supports git, hg, bzr, svn and HTTP.
  #

  s.source       = { :git => "https://github.com/cemolcay/Fretboard.git", :tag => "#{s.version}" }
  # s.source       =  { :path => "." }

  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  CocoaPods is smart about how it includes source code. For source files
  #  giving a folder will include any swift, h, m, mm, c & cpp files.
  #  For header files it will include any header in the folder.
  #  Not including the public_header_files will make all headers public.
  #

  s.source_files  = "Source/*.swift"

  # s.public_header_files = "Classes/**/*.h"


  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  A list of resources included with the Pod. These are copied into the
  #  target bundle with a build phase script. Anything else will be cleaned.
  #  You can preserve files from being cleaned, please don't preserve
  #  non-essential files like tests, examples and documentation.
  #

  # s.resource  = "icon.png"
  # s.resources = "Resources/*.png"

  # s.preserve_paths = "FilesToSave", "MoreFilesToSave"


  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Link your library with frameworks, or libraries. Libraries do not include
  #  the lib prefix of their name.
  #

  # s.framework  = "SomeFramework"
  # s.frameworks = "SomeFramework", "AnotherFramework"

  # s.library   = "iconv"
  # s.libraries = "iconv", "xml2"


  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If your library depends on compiler flags you can set them in the xcconfig hash
  #  where they will only apply to your library. If you depend on other Podspecs
  #  you can include multiple dependencies to ensure it works.

  s.requires_arc = true

  # s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  s.dependency "MusicTheorySwift"
  s.dependency "CenterTextLayer"

end
