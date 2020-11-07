# Au-Naturel

Simple command line application using [tapCreate(tap:place:options:eventsOfInterest:callback:userInfo:)](https://developer.apple.com/documentation/coregraphics/cgevent/1454426-tapcreate) to negate the values for events of the `CGEventType.scrollWheel` type that are not continuous.

Effectively this reverses the annoying coupling of mouse and trackpad `Scroll direction: Natural` settings starting with macOS Mojave, allowing the trackpad to have natural scrolling and the mouse nominal scrolling.

## Building

`swiftc -target x86_64-apple-darwin18 au-naturel.swift`
