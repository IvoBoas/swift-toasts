import SwiftUI
#if canImport(UIKit)
	import UIKit
#elseif canImport(AppKit)
	import AppKit
#endif

public struct ToastTheme: Sendable {
	public var standard: Colors
	public var alert: Colors
	public var shadow: Color

	public init(standard: Colors, alert: Colors, shadow: Color) {
		self.standard = standard
		self.alert = alert
		self.shadow = shadow
	}

	public struct Colors: Sendable {
		public var background: Color
		public var foreground: Color
		public var icon: Color
		public var actionBackground: Color
		public var actionForeground: Color

		public init(
			background: Color,
			foreground: Color,
			icon: Color,
			actionBackground: Color,
			actionForeground: Color
		) {
			self.background = background
			self.foreground = foreground
			self.icon = icon
			self.actionBackground = actionBackground
			self.actionForeground = actionForeground
		}
	}

	func colors(for style: ToastMessage.Style) -> Colors {
		switch style {
		case .success, .info: standard
		case .error, .warning: alert
		}
	}
}

extension ToastTheme {
	public static let `default`: ToastTheme = {
		let background = Color(light: Color(rgb: 0x1C1C1E), dark: Color(rgb: 0xF2F2F7))
		let foreground = Color(light: Color(rgb: 0xF2F2F7), dark: Color(rgb: 0x1C1C1E))
		let alertBackground = Color(light: Color(rgb: 0xB3261E), dark: Color(rgb: 0xF9DEDC))
		let alertForeground = Color(light: Color(rgb: 0xFFFFFF), dark: Color(rgb: 0x601410))

		return ToastTheme(
			standard: Colors(
				background: background,
				foreground: foreground,
				icon: foreground,
				actionBackground: foreground.opacity(0.12),
				actionForeground: foreground
			),
			alert: Colors(
				background: alertBackground,
				foreground: alertForeground,
				icon: alertForeground,
				actionBackground: alertForeground,
				actionForeground: alertBackground
			),
			shadow: Color(light: .black.opacity(0.08), dark: .black.opacity(0.45))
		)
	}()
}

// MARK: Environment
extension EnvironmentValues {
	@Entry public var toastTheme: ToastTheme = .default
}

extension View {
	public func toastTheme(_ theme: ToastTheme) -> some View {
		environment(\.toastTheme, theme)
	}
}

// MARK: Dynamic colors
private extension Color {
	init(rgb: UInt32) {
		self.init(
			red: Double((rgb >> 16) & 0xFF) / 255,
			green: Double((rgb >> 8) & 0xFF) / 255,
			blue: Double(rgb & 0xFF) / 255
		)
	}

	init(light: Color, dark: Color) {
		#if canImport(UIKit)
			self.init(uiColor: UIColor { traits in
				traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
			})
		#elseif canImport(AppKit)
			self.init(nsColor: NSColor(name: nil) { appearance in
				appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? NSColor(dark) : NSColor(light)
			})
		#else
			self = light
		#endif
	}
}
