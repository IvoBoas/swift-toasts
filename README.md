# Toasts

Lightweight, themeable toasts for SwiftUI, with a [swift-dependencies](https://github.com/pointfreeco/swift-dependencies) service to trigger them from anywhere.

- **Trigger from anywhere.** Call `toastService.show(...)` from a view model, a reducer, or a background task. No view state to thread through.
- **Or keep it local.** Bind `.toast($toast)` to a view's `@State` and it shows and dismisses the toast for you.
- **Shows above everything.** On iOS the toast lives in its own window, so it stays visible over sheets, full-screen covers and alerts. Only the toast itself takes touches.
- **Themeable.** Pick the colors and shadow once with `.toastTheme(...)`. A neutral light/dark default is included.
- **Four styles.** `success`, `info`, `warning` and `error`, each with a default SF Symbol you can override.
- **Dismissible.** Tap or swipe up to dismiss, plus an optional action button.

## Requirements

- iOS 17+ / macOS 14+
- Swift 6 toolchain (Xcode 16 or later)

## Installation

Add the package in Xcode with **File → Add Package Dependencies…** and the URL:

```
https://github.com/IvoBoas/swift-toasts
```

Or in `Package.swift`:

```swift
dependencies: [
	.package(url: "https://github.com/IvoBoas/swift-toasts", from: "0.1.0"),
],
targets: [
	.target(
		name: "MyApp",
		dependencies: [
			.product(name: "Toasts", package: "swift-toasts"),
		]
	),
]
```

## Usage

### 1. Present toasts at the root

The package shows a toast and leaves deciding *when* to hide it to you. Your root view keeps the current toast, listens to the service, and clears it after the toast's `duration`:

```swift
import Dependencies
import SwiftUI
import Toasts

struct RootView: View {
	@Dependency(\.toastService) private var toastService
	@State private var toast: ToastMessage?

	var body: some View {
		ContentView()
			.toastOverlay(toast) { _ in toast = nil }
			.task {
				for await next in await toastService.observe() {
					toast = next
				}
			}
			.task(id: toast?.id) {
				guard let interval = toast?.duration.interval else { return }
				do {
					try await Task.sleep(for: interval)
					toast = nil
				} catch {}
			}
	}
}
```

### 2. Show a toast from anywhere

```swift
@Dependency(\.toastService) var toastService

await toastService.show(.success("Saved"))
await toastService.show(.error("Couldn't save expense", action: .dismiss))
await toastService.show(.warning("You're offline", systemImage: "wifi.slash"))
await toastService.show(.info("Synced", alignment: .bottom, duration: .short))
```

| Option | Values | Default |
|---|---|---|
| `systemImage` | Any SF Symbol name | Depends on the style |
| `action` | `.dismiss` | `nil` |
| `alignment` | `.top`, `.center`, `.bottom` | `.top` |
| `duration` | `.short` (2s), `.normal` (4s), `.long` (6s), `.untilInteraction` | `.normal`; `.long` for `error` and `warning` |

It's handy to keep your app's messages in one place:

```swift
extension ToastMessage {
	static let saveFailed: Self = .error("Couldn't save your changes")
	static func copied(_ thing: String) -> Self { .success("\(thing) copied", systemImage: "doc.on.doc") }
}

await toastService.show(.saveFailed)
```

### Showing a toast on a single view

When a toast only belongs to one screen, skip the service and bind the `.toast` modifier to some `@State`. Set the state to show a toast; the modifier clears it after the toast's `duration`, or when it's tapped, swiped away or its action is pressed:

```swift
struct ExpenseView: View {
	@State private var toast: ToastMessage?

	var body: some View {
		Form {
			Button("Save") {
				toast = .success("Expense saved")
			}
		}
		.toast($toast)
	}
}
```

Unlike `toastOverlay`, the toast is drawn in an overlay on the view it's attached to, so it's laid out within that view's bounds and is covered by sheets and alerts presented on top of it. Setting a new toast while one is showing replaces it and restarts the timer.

### Using it with The Composable Architecture

`ToastService` is a regular dependency, so a root reducer can own the toast state and the dismissal timer, and every feature can show toasts through effects:

```swift
@Reducer
struct AppFeature {
	@ObservableState
	struct State {
		var toast: ToastMessage?
	}

	enum Action {
		case onAppear
		case received(ToastMessage)
		case dismiss(id: UUID)
	}

	enum CancelID { case observer, dismissal }

	@Dependency(\.toastService) var toastService
	@Dependency(\.continuousClock) var clock

	var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case .onAppear:
				return .run { send in
					for await toast in await toastService.observe() {
						await send(.received(toast))
					}
				}
				.cancellable(id: CancelID.observer, cancelInFlight: true)

			case let .received(toast):
				state.toast = toast
				guard let interval = toast.duration.interval else {
					return .cancel(id: CancelID.dismissal)
				}
				return .run { send in
					try await clock.sleep(for: interval)
					await send(.dismiss(id: toast.id))
				}
				.cancellable(id: CancelID.dismissal, cancelInFlight: true)

			case let .dismiss(id):
				guard state.toast?.id == id else { return .none }
				state.toast = nil
				return .cancel(id: CancelID.dismissal)
			}
		}
	}
}
```

```swift
// In any feature
return .run { _ in await toastService.show(.saveFailed) }
```

```swift
// In the root view
.toastOverlay(store.toast) { _ in
	guard let id = store.toast?.id else { return }
	store.send(.dismiss(id: id))
}
```

## Theming

Set a theme anywhere above `toastOverlay` or `.toast($toast)`. `standard` colors are used for `success` and `info`, and `alert` colors for `error` and `warning`:

```swift
extension ToastTheme {
	static let brand = ToastTheme(
		standard: Colors(
			background: Color("ToastBackground"),
			foreground: Color("ToastForeground"),
			icon: .accentColor,
			actionBackground: Color("ToastForeground").opacity(0.12),
			actionForeground: .accentColor
		),
		alert: Colors(
			background: .red,
			foreground: .white,
			icon: .white,
			actionBackground: .white,
			actionForeground: .red
		),
		shadow: .black.opacity(0.1)
	)
}

RootView()
	.toastOverlay(toast) { _ in toast = nil }
	.toastTheme(.brand)
```

Asset catalog colors adapt to light and dark mode automatically.

`ToastView` is public too, so you can place a toast inline, for example in a preview or an empty state:

```swift
ToastView(toast: .success("Username copied"), onAction: { _ in })
```

## Testing

`ToastService` is made of closures, so tests can replace it:

```swift
let shown = LockIsolated<[ToastMessage]>([])

try await withDependencies {
	$0.toastService = ToastService(
		show: { toast in shown.withValue { $0.append(toast) } },
		observe: { AsyncStream { $0.finish() } }
	)
} operation: {
	try await model.save()
}

#expect(shown.value == [.saveFailed])
```

With TCA's `TestStore`, override it in the `withDependencies` closure the same way.

Without an override, tests use the live service and swift-dependencies reports an error, so a toast your tests forgot about is caught.
