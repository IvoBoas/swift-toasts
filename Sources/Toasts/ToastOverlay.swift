import SwiftUI
#if canImport(UIKit)
	import UIKit
#endif

extension View {
	@ViewBuilder
	public func toastOverlay(
		_ toast: ToastMessage?,
		onAction: @escaping (ToastMessage.Action) -> Void
	) -> some View {
		#if canImport(UIKit)
			modifier(ToastWindowModifier(toast: toast, onAction: onAction))
		#else
			overlay { ToastLayer(toast: toast, onAction: onAction) }
		#endif
	}
}

private struct ToastLayer: View {
	let toast: ToastMessage?
	let onAction: (ToastMessage.Action) -> Void
	var onFrameChange: (CGRect) -> Void = { _ in }

	@State private var isScaled = false

	var body: some View {
		Color.clear
			.allowsHitTesting(false)
			.overlay(alignment: toast?.alignment.swiftUIAlignment ?? .top) {
				if let toast {
					ToastView(toast: toast, onAction: onAction)
						.padding(.horizontal, 16)
						.padding(.top, toast.alignment == .top ? 12 : .zero)
						.padding(.bottom, toast.alignment == .bottom ? 12 : .zero)
						.transition(toast.alignment.transition)
						.scaleEffect(isScaled ? 1 : 0.3)
						.onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { onFrameChange($0) }
						.onAppear {
							withAnimation(.spring(duration: 0.35).delay(0.15)) {
								isScaled = true
							}
						}
						.onDisappear {
							isScaled = false
							onFrameChange(.zero)
						}
				}
			}
	}
}

// MARK: Window
#if canImport(UIKit)
	private struct ToastWindowModifier: ViewModifier {
		let toast: ToastMessage?
		let onAction: (ToastMessage.Action) -> Void

		@Environment(\.toastTheme) private var theme
		@State private var presentation = ToastPresentation()

		func body(content: Content) -> some View {
			content
				.background {
					WindowSceneReader { presentation.install(in: $0) }
				}
				.onChange(of: toast, initial: true) { _, toast in
					presentation.onAction = onAction
					presentation.theme = theme
					withAnimation(.snappy) {
						presentation.toast = toast
					}
				}
		}
	}

	@MainActor
	@Observable
	private final class ToastPresentation {
		var toast: ToastMessage?
		@ObservationIgnored var theme: ToastTheme = .default
		@ObservationIgnored var onAction: (ToastMessage.Action) -> Void = { _ in }
		@ObservationIgnored var toastFrame: CGRect = .zero
		@ObservationIgnored private var window: ToastWindow?

		func install(in scene: UIWindowScene) {
			guard window?.windowScene !== scene else { return }

			let host = UIHostingController(rootView: ToastWindowRoot(presentation: self))
			host.view.backgroundColor = .clear

			let window = ToastWindow(windowScene: scene)
			window.presentation = self
			window.rootViewController = host
			window.windowLevel = .alert + 1
			window.backgroundColor = .clear
			window.isHidden = false
			self.window = window
		}
	}

	private struct ToastWindowRoot: View {
		let presentation: ToastPresentation

		var body: some View {
			ToastLayer(
				toast: presentation.toast,
				onAction: { presentation.onAction($0) },
				onFrameChange: { presentation.toastFrame = $0 }
			)
			.toastTheme(presentation.theme)
		}
	}

	private final class ToastWindow: UIWindow {
		weak var presentation: ToastPresentation?

		override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
			guard let frame = presentation?.toastFrame, frame.contains(point) else { return nil }
			return super.hitTest(point, with: event)
		}
	}

	private struct WindowSceneReader: UIViewRepresentable {
		let onScene: (UIWindowScene) -> Void

		func makeUIView(context: Context) -> ReaderView {
			ReaderView(onScene: onScene)
		}

		func updateUIView(_ view: ReaderView, context: Context) {
			view.onScene = onScene
		}

		final class ReaderView: UIView {
			var onScene: (UIWindowScene) -> Void

			init(onScene: @escaping (UIWindowScene) -> Void) {
				self.onScene = onScene
				super.init(frame: .zero)
				isUserInteractionEnabled = false
			}

			@available(*, unavailable)
			required init?(coder: NSCoder) {
				fatalError("init(coder:) has not been implemented")
			}

			override func didMoveToWindow() {
				super.didMoveToWindow()
				guard let scene = window?.windowScene else { return }
				onScene(scene)
			}
		}
	}
#endif

// MARK: Alignment
private extension ToastMessage.Alignment {
	var swiftUIAlignment: SwiftUI.Alignment {
		switch self {
		case .top: .top
		case .center: .center
		case .bottom: .bottom
		}
	}

	var transition: AnyTransition {
		switch self {
		case .top: .move(edge: .top).combined(with: .opacity)
		case .center: .opacity
		case .bottom: .move(edge: .bottom).combined(with: .opacity)
		}
	}
}
