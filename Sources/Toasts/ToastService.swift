import Dependencies
import Foundation

public struct ToastService: Sendable {
	public var show: @Sendable (ToastMessage) async -> Void
	public var observe: @Sendable () async -> AsyncStream<ToastMessage>

	public init(
		show: @escaping @Sendable (ToastMessage) async -> Void,
		observe: @escaping @Sendable () async -> AsyncStream<ToastMessage>
	) {
		self.show = show
		self.observe = observe
	}
}

// MARK: Implementation
extension ToastService {
	public static let live: ToastService = {
		let actor = ToastServiceActor()

		return ToastService(
			show: { await actor.show($0) },
			observe: { await actor.observe() }
		)
	}()
}

private actor ToastServiceActor {
	private var continuations: [UUID: AsyncStream<ToastMessage>.Continuation] = [:]

	deinit {
		for (_, stream) in continuations { stream.finish() }
	}

	func show(_ toast: ToastMessage) {
		for (_, stream) in continuations {
			stream.yield(toast)
		}
	}

	func observe() -> AsyncStream<ToastMessage> {
		let id = UUID()
		let (stream, continuation) = AsyncStream<ToastMessage>.makeStream(bufferingPolicy: .bufferingNewest(5))
		continuations[id] = continuation
		continuation.onTermination = { [weak self] _ in
			Task { await self?.remove(id) }
		}
		return stream
	}

	private func remove(_ id: UUID) {
		continuations[id]?.finish()
		continuations.removeValue(forKey: id)
	}
}

// MARK: Dependencies
extension ToastService: DependencyKey {
	public static let liveValue: ToastService = .live
}

extension DependencyValues {
	public var toastService: ToastService {
		get { self[ToastService.self] }
		set { self[ToastService.self] = newValue }
	}
}
