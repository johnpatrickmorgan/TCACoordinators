import ComposableArchitecture
import FlowStacks
import Foundation
import SwiftUI
import CombineSchedulers

public extension Effect {
	/// Allows arbitrary changes to be made to the routes collection, even if SwiftUI does not support such changes within a single
	/// state update. For example, SwiftUI only supports pushing, presenting or dismissing one screen at a time. Any changes can be
	/// made to the routes passed to the transform closure, and where those changes are not supported within a single update by
	/// SwiftUI, an Effect stream of smaller permissible updates will be returned, interspersed with sufficient delays.
	///
	/// - Parameter routes: The routes in their current state.
	/// - Parameter scheduler: The scheduler for scheduling delays. E.g. a test scheduler can be used in tests.
	/// - Parameter transform: A closure transforming the routes into their new state.
	/// - Returns: An Effect stream of actions with incremental updates to routes over time. If the proposed change is supported
	///   within a single update, the Effect stream will include only one element.
	static func routeWithDelaysIfUnsupported<ScreenState, ScreenAction>(
		_ routes: [Route<ScreenState>],
		action: CaseKeyPath<Action, IndexedRouterAction<ScreenState, ScreenAction>>,
		scheduler: AnySchedulerOf<DispatchQueue> = .main,
		_ transform: (inout [Route<ScreenState>]) -> Void
	) -> Self {
		var transformedRoutes = routes
		transform(&transformedRoutes)
		let steps = RouteSteps.calculateSteps(from: routes, to: transformedRoutes)
		return .run { send in
			for await step in scheduledSteps(steps: steps, scheduler: scheduler) {
				await send(action.appending(path: \.updateRoutes)(step))
			}
		}
	}
}

public extension Effect where Action: CasePathable {
  /// Allows arbitrary changes to be made to the routes collection, even if SwiftUI does not support such changes within a single
  /// state update. For example, SwiftUI only supports pushing, presenting or dismissing one screen at a time. Any changes can be
  /// made to the routes passed to the transform closure, and where those changes are not supported within a single update by
  /// SwiftUI, an Effect stream of smaller permissible updates will be returned, interspersed with sufficient delays.
  ///
  /// - Parameter routes: The routes in their current state.
  /// - Parameter scheduler: The scheduler for scheduling delays. E.g. a test scheduler can be used in tests.
  /// - Parameter transform: A closure transforming the routes into their new state.
  /// - Returns: An Effect stream of actions with incremental updates to routes over time. If the proposed change is supported
  ///   within a single update, the Effect stream will include only one element.
	static func routeWithDelaysIfUnsupported<ScreenState: Identifiable, ScreenAction>(
		_ routes: IdentifiedArrayOf<Route<ScreenState>>,
		action: CaseKeyPath<Action, IdentifiedRouterAction<ScreenState, ScreenAction>>,
		scheduler: AnySchedulerOf<DispatchQueue> = .main,
		_ transform: (inout IdentifiedArrayOf<Route<ScreenState>>) -> Void
	) -> Self {
    var transformedRoutes = routes
    transform(&transformedRoutes)
    let steps = RouteSteps.calculateSteps(from: Array(routes), to: Array(transformedRoutes))

    return .run { send in
      for await step in scheduledSteps(steps: steps, scheduler: scheduler) {
				await send(action.appending(path: \.updateRoutes)(IdentifiedArray(uncheckedUniqueElements: step)))
      }
    }
  }
}

func scheduledSteps<Screen>(steps: [[Route<Screen>]], scheduler: AnySchedulerOf<DispatchQueue>) -> AsyncStream<[Route<Screen>]> {
  guard let first = steps.first else { return .finished }
  let second = steps.dropFirst().first
  let remainder = steps.dropFirst(2)

  return AsyncStream { continuation in
    Task {
      do {
        continuation.yield(first)
        if let second {
          continuation.yield(second)
        }

        for step in remainder {
          try await scheduler.sleep(for: .milliseconds(650))
          continuation.yield(step)
        }

        continuation.finish()
      } catch {
        continuation.finish()
      }
    }
  }
}
