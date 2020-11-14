import CoreGraphics
import Darwin

extension CGEvent {
  func negateIntegerValueFields(_ fields: CGEventField...) {
    var values: [CGEventField: Int64] = [:]
    for field in fields {
      values[field] = getIntegerValueField(field)
    }

    for field in fields {
      guard let value = values[field] else { continue }

      setIntegerValueField(field, value: -value)
    }
  }
}

var signalSources: [Int32: DispatchSourceSignal] = [:]

func reverseDeltas(_: CGEventTapProxy, _: CGEventType, event: CGEvent, _: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    let isContinuous = event.getIntegerValueField(.scrollWheelEventIsContinuous)
    if isContinuous == 1 { return Unmanaged.passUnretained(event) }

    event.negateIntegerValueFields(
      .scrollWheelEventPointDeltaAxis1,
      .scrollWheelEventDeltaAxis1,
      .scrollWheelEventFixedPtDeltaAxis1
    )

    return Unmanaged.passUnretained(event)
}

func configureSignal(signal _signal: Int32, handler: @escaping () -> Void) {
    signal(_signal, SIG_IGN)

    let signalSource = DispatchSource.makeSignalSource(signal: _signal, queue: .main)

    signalSource.setEventHandler(handler: handler)
    signalSource.activate()

    signalSources[_signal] = signalSource
}

guard #available(macOS 10.14, *) else {
    print("no need to run on macOS before 10.14")
    exit(EXIT_FAILURE)
}

guard let loop = CFRunLoopGetCurrent() else {
    print("can't get current loop")
    exit(EXIT_FAILURE)
}

guard let port = CGEvent.tapCreate(
    tap: .cgSessionEventTap,
    place: .tailAppendEventTap,
    options: .defaultTap,
    eventsOfInterest: (1 << CGEventType.scrollWheel.rawValue) as UInt64,
    callback: reverseDeltas,
    userInfo: nil
) else {
    print("can't create tap")
    exit(EXIT_FAILURE)
}

print("tap created")

guard let loopSource = CFMachPortCreateRunLoopSource(nil, port, 0) else {
    print("can't create run loop source")
    exit(EXIT_FAILURE)
}

CFRunLoopAddSource(loop, loopSource, .commonModes)
CGEvent.tapEnable(tap: port, enable: true)

configureSignal(signal: SIGINFO) {
    if CGEvent.tapIsEnabled(tap: port) {
        print("disabling tap")
        CGEvent.tapEnable(tap: port, enable: false)
    } else {
        print("enabling tap")
        CGEvent.tapEnable(tap: port, enable: true)
    }
}

configureSignal(signal: SIGINT) {
    print("stopping run loop")
    CFRunLoopStop(loop)
}

CFRunLoopRun()

print("finishing up")

exit(EXIT_SUCCESS)
