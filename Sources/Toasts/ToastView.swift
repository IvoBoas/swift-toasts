import SwiftUI

public struct ToastView: View {
	@Environment(\.toastTheme) private var theme

	let toast: ToastMessage
	let onAction: (ToastMessage.Action) -> Void

	public init(toast: ToastMessage, onAction: @escaping (ToastMessage.Action) -> Void) {
		self.toast = toast
		self.onAction = onAction
	}

	public var body: some View {
		let colors = theme.colors(for: toast.style)
		let shape = RoundedRectangle(cornerRadius: .cornerRadius, style: .continuous)

		HStack(alignment: .center, spacing: .spacingS) {
			Image(systemName: toast.systemImage ?? toast.style.systemImage)
				.font(.subheadline.weight(.semibold))
				.foregroundStyle(colors.icon)
				.frame(width: .iconSize, height: .iconSize)

			Text(toast.title)
				.font(.subheadline.weight(.medium))
				.foregroundStyle(colors.foreground)
				.lineLimit(2)
				.fixedSize(horizontal: false, vertical: true)

			if let action = toast.action {
				Button(action.title) { onAction(action) }
					.buttonStyle(.plain)
					.font(.footnote.weight(.semibold))
					.foregroundStyle(colors.actionForeground)
					.padding(.horizontal, .spacingM)
					.padding(.vertical, .spacingS)
					.background(colors.actionBackground, in: .capsule)
					.padding(.leading, .spacingXS)
			}
		}
		.padding(.leading, .spacingL)
		.padding(.trailing, toast.action == nil ? .spacingL : .actionInset)
		.padding(.vertical, toast.action == nil ? .spacingM : .actionInset)
		.frame(minHeight: .minimumHeight)
		.background {
			shape
				.fill(colors.background)
				.shadow(color: theme.shadow, radius: 2, y: 1)
				.shadow(color: theme.shadow, radius: 12, y: 6)
				.shadow(color: theme.shadow, radius: 24, y: 12)
		}
		.contentShape(shape)
		.onTapGesture { onAction(.dismiss) }
		.simultaneousGesture(swipeGesture)
		.accessibilityElement(children: .combine)
	}

	private var swipeGesture: some Gesture {
		DragGesture(minimumDistance: .swipeMinimumDistance)
			.onEnded { value in
				guard value.translation.height <= -.swipeDismissDistance else { return }
				onAction(.dismiss)
			}
	}
}

private extension ToastMessage.Style {
	var systemImage: String {
		switch self {
		case .success: "checkmark"
		case .error: "exclamationmark.circle"
		case .info: "info.circle"
		case .warning: "exclamationmark.triangle"
		}
	}
}

// MARK: - Constants
private extension CGFloat {
	static let spacingXS: Self = 4
	static let spacingS: Self = 8
	static let spacingM: Self = 12
	static let spacingL: Self = 16
	static let cornerRadius: Self = 24
	static let iconSize: Self = 18
	static let swipeMinimumDistance: Self = 12
	static let swipeDismissDistance: Self = 32
	static let minimumHeight: Self = 44
	static let actionInset: Self = 6
}

// MARK: - Previews
#if DEBUG
	#Preview {
		VStack(spacing: 12) {
			ToastView(toast: .success("Username copied"), onAction: { _ in })
			ToastView(toast: .info("New reminder started"), onAction: { _ in })
			ToastView(toast: .success("Request sent to Sam", action: .dismiss), onAction: { _ in })
			ToastView(toast: .error("Couldn't save expense", action: .dismiss), onAction: { _ in })
			ToastView(toast: .success("Username copied", systemImage: "doc.on.doc"), onAction: { _ in })
			ToastView(toast: .warning("Go online to change your username", systemImage: "wifi.slash"), onAction: { _ in })
			ToastView(toast: .error("Failed to load friends"), onAction: { _ in })
		}
		.padding()
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
#endif
