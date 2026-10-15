import SwiftUI

extension View {
	public func toast(_ toast: Binding<ToastMessage?>) -> some View {
		modifier(ToastModifier(toast: toast))
	}
}

private struct ToastModifier: ViewModifier {
	@Binding var toast: ToastMessage?

	func body(content: Content) -> some View {
		content
			.overlay {
				ToastLayer(toast: toast, onAction: { _ in dismiss(toast?.id) })
					.animation(.snappy, value: toast)
			}
			.task(id: toast?.id) {
				guard let toast, let interval = toast.duration.interval else { return }
				do {
					try await Task.sleep(for: interval)
					dismiss(toast.id)
				} catch {}
			}
	}

	private func dismiss(_ id: UUID?) {
		guard let id, toast?.id == id else { return }
		toast = nil
	}
}
