import Foundation

public struct ToastMessage: Equatable, Hashable, Identifiable, Sendable {
	public let id: UUID
	public let style: Style
	public let title: String
	public let systemImage: String?
	public let action: Action?
	public let alignment: Alignment
	public let duration: DisplayDuration

	public init(
		id: UUID = UUID(),
		style: Style,
		title: String,
		systemImage: String? = nil,
		action: Action? = nil,
		alignment: Alignment = .top,
		duration: DisplayDuration = .normal
	) {
		self.id = id
		self.style = style
		self.title = title
		self.systemImage = systemImage
		self.action = action
		self.alignment = alignment
		self.duration = duration
	}
}

extension ToastMessage {
	public enum Alignment: Equatable, Hashable, Sendable {
		case top
		case center
		case bottom
	}

	public enum Style: Equatable, Hashable, Sendable {
		case success
		case error
		case info
		case warning
	}

	public enum Action: Equatable, Hashable, Sendable {
		case dismiss

		public var title: String {
			switch self {
			case .dismiss: "Dismiss"
			}
		}
	}

	public enum DisplayDuration: Equatable, Hashable, Sendable {
		case short
		case normal
		case long
		case untilInteraction

		public var interval: Duration? {
			switch self {
			case .short: .seconds(2)
			case .normal: .seconds(4)
			case .long: .seconds(6)
			case .untilInteraction: nil
			}
		}
	}
}

// MARK: Convenience
extension ToastMessage {
	public static func success(
		_ title: String,
		systemImage: String? = nil,
		action: Action? = nil,
		alignment: Alignment = .top,
		duration: DisplayDuration = .normal
	) -> Self {
		.init(
			style: .success,
			title: title,
			systemImage: systemImage,
			action: action,
			alignment: alignment,
			duration: duration
		)
	}

	public static func error(
		_ title: String,
		systemImage: String? = nil,
		action: Action? = nil,
		alignment: Alignment = .top,
		duration: DisplayDuration = .long
	) -> Self {
		.init(
			style: .error,
			title: title,
			systemImage: systemImage,
			action: action,
			alignment: alignment,
			duration: duration
		)
	}

	public static func info(
		_ title: String,
		systemImage: String? = nil,
		action: Action? = nil,
		alignment: Alignment = .top,
		duration: DisplayDuration = .normal
	) -> Self {
		.init(
			style: .info,
			title: title,
			systemImage: systemImage,
			action: action,
			alignment: alignment,
			duration: duration
		)
	}

	public static func warning(
		_ title: String,
		systemImage: String? = nil,
		action: Action? = nil,
		alignment: Alignment = .top,
		duration: DisplayDuration = .long
	) -> Self {
		.init(
			style: .warning,
			title: title,
			systemImage: systemImage,
			action: action,
			alignment: alignment,
			duration: duration
		)
	}
}
