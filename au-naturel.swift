import CoreGraphics
import Darwin

let port = CGEvent.tapCreate(
  tap: .cgSessionEventTap,
  place: .tailAppendEventTap,
  options: .defaultTap,
  eventsOfInterest: (1 << CGEventType.scrollWheel.rawValue) as UInt64,
  callback: { _, _, event, _ in
    let isContinuous = event.getIntegerValueField(.scrollWheelEventIsContinuous)
    if isContinuous == 1 { return Unmanaged.passUnretained(event) }

    let pointDelta = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)
    let delta = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
    let fixedPtDelta = event.getIntegerValueField(.scrollWheelEventFixedPtDeltaAxis1)

    event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: -pointDelta)
    event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: -delta)
    event.setIntegerValueField(.scrollWheelEventFixedPtDeltaAxis1, value: -fixedPtDelta)

    return Unmanaged.passUnretained(event)
  },
  userInfo: nil
)

guard let port = port else {
  print("can't create tap")
  exit(1)
}

print("tap created")

guard let loopSource = CFMachPortCreateRunLoopSource(nil, port, 0) else {
  print("can't create run loop source")
  exit(1)
}

guard let loop = CFRunLoopGetCurrent() else {
  print("can't get current loop")
  exit(1)
}

CFRunLoopAddSource(loop, loopSource, .commonModes)
CGEvent.tapEnable(tap: port, enable: true)

signal(SIGINFO, SIG_IGN)
let infoSource = DispatchSource.makeSignalSource(signal: SIGINFO, queue: .main)
infoSource.setEventHandler {
  if CGEvent.tapIsEnabled(tap: port) {
    print("disabling tap")
    CGEvent.tapEnable(tap: port, enable: false)
  } else {
    print("enabling tap")
    CGEvent.tapEnable(tap: port, enable: true)
  }
}
infoSource.activate()

signal(SIGINT, SIG_IGN)
let intSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
intSource.setEventHandler {
  print("stopping run loop")
  CFRunLoopStop(loop)
}
intSource.activate()

CFRunLoopRun()

print("finishing up")
