# About
The Read app (Title WIP) is aiming to be a simple for beginners powerful for powerusers type of reader app. It's following the kiss philosophy by _only_ being a reader app and doing that well.
# Timeline
- CBZ format, get that working
- write a `protocol Book` and `protocol BookView: View` for generic book formats, so it's easier to add later
- Extend CBZ to support CBR in an external dependency?
- Release to TestFlight
- Get ePub working
- Get PDF to work
- Look into highlighting and note taking, this can potentially break **KISS**
- TestFlight feedback
- Work on ebook manager app, inspired by Calibre Companion, hopefully supporting calibre
- Work on Calibre API compliant ebook server, with extra nicities for our own app
# Build the project
Clone this repo
Open the workspace and _not_ the project file. This project relies on SwiftPM, as it give me some control, I don't feel I have in either carthage or pods.
Build and run as usual.

There are at times issue signing builds, I've fixed this by building dependencies individually.
# Add framework
As this project relies on SwiftPM, you have to add packages in `ReadDeps/Package.swift` [link to a better guide later].
In a terminal emulator of your choice `cd` into `ReadDeps` and run `swift package update`, this should fetch all the new dependencies and you can now link them from xcode. Don't be afraid to rebuild the xcode project, as this is how SwiftPM works.

Regenarate Xcode project (this has to be done with Xcode closed) by running `swift package generate-xcode`. You then have to go to the targets frameworks and add the new framework, note: remember to check if previous frameworks has been removed, and readd them if that is the case.
