import CombineSchedulers
import ComposableArchitecture
import FlowStacks
import Foundation
import SwiftUI

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
  @available(*, deprecated, message: "No longer necessary, desired state changes can be made directly in one update")
  static func routeWithDelaysIfUnsupported<ScreenState>(
    _ routes: [Route<ScreenState>],
    action: CaseKeyPath<Action, IndexedRouterAction<ScreenState, some Any>>,
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
  @available(*, deprecated, message: "No longer necessary, desired state changes can be made directly in one update")
  static func routeWithDelaysIfUnsupported<ScreenState: Identifiable>(
    _ routes: IdentifiedArrayOf<Route<ScreenState>>,
    action: CaseKeyPath<Action, IdentifiedRouterAction<ScreenState, some Any>>,
    scheduler: AnySchedulerOf<DispatchQueue> = .main,
    _ transform: (inout IdentifiedArrayOf<Route<ScreenState>>) -> Void
  ) -> Self {
    var transformedRoutes = routes
    transform(&transformedRoutes)
    let steps = RouteSteps.calculateSteps(from: Array(routes), to: Array(transformedRoutes))

    return .run { send in
      for await step in scheduledSteps(steps: steps, scheduler: scheduler) {
        await send(action.appending(path: \.updateRoutes)(step))
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

private enum RouteSteps {
  /// For a given update to an array of routes, returns the minimum intermediate steps
  /// required to ensure each update is supported by SwiftUI.
  /// - Returns: An Array of Route arrays, representing a series of permissible steps
  ///   from start to end.
  static func calculateSteps<Screen>(from start: [Route<Screen>], to end: [Route<Screen>]) -> [[Route<Screen>]] {
    let pairs = Array(zip(start, end))
    let firstDivergingIndex = pairs.dropFirst()
      .firstIndex(where: { $0.style != $1.style }) ?? pairs.endIndex
    let firstDivergingPresentationIndex = start[firstDivergingIndex ..< start.count]
      .firstIndex(where: { $0.isPresented }) ?? start.endIndex

    // Initial step is to change screen content without changing navigation structure.
    let initialStep = Array(end[..<firstDivergingIndex] + start[firstDivergingIndex...])
    var steps = [initialStep]

    // Dismiss extraneous presented stacks.
    while var dismissStep = steps.last, dismissStep.count > firstDivergingPresentationIndex {
      var dismissed: Route<Screen>? = dismissStep.popLast()
      // Ignore pushed screens as they can be dismissed en masse.
      while dismissed?.isPresented == false, dismissStep.count > firstDivergingPresentationIndex {
        dismissed = dismissStep.popLast()
      }
      steps.append(dismissStep)
    }

    // Pop extraneous pushed screens.
    while var popStep = steps.last, popStep.count > firstDivergingIndex {
      var popped: Route<Screen>? = popStep.popLast()
      while popped?.style == .push, popStep.count > firstDivergingIndex, popStep.last?.style == .push {
        popped = popStep.popLast()
      }
      steps.append(popStep)
    }

    // Push or present each new step.
    while var newStep = steps.last, newStep.count < end.count {
      newStep.append(end[newStep.count])
      steps.append(newStep)
    }

    return steps
  }
}

private func apply<T>(_ transform: (inout T) -> Void, to input: T) -> T {
  var transformed = input
  transform(&transformed)
  return transformed
}
