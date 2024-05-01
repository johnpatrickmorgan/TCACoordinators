#  Migrating from 0.8

Version 0.9 introduced an API change to bring the library's APIs more in-line with the Composable Architecture, including the use of case paths. These are breaking changes, so it requires some migration. There are two migration routes: 

- Full migration, to bring your project fully in-line with the new APIs.
- Easy migration, for if you want to migrate as quickly as possible, so you can work on full migration at your leisure.

## Full migration

1. The state and action protocols have been deprecated/removed. You can remove conformances to the `IndexedRouterState`, `IndexedRouterAction`, `IdentifiedRouterState` and `IdentifiedRouterAction` protocols. 
2. To enable access to case paths on your coordinator's action type, add the @Reducer macro to your coordinator reducer.
3. Your coordinator's action can be simplified. Instead of the `routeAction` and `updateRoutes` cases, it should have just one case: either `case router(IndexedRouterActionOf<Screen>)` or `case router(IdentifiedRouterActionOf<Screen>)`, where `Screen` is your screen reducer. You will also need to update any references to those cases, e.g. rather than pattern-matching on `case .routeAction(_, let action):` you would pattern-match on `case .router(.routeAction(_, let action)):`, since they are now nested within the `.router(...)` case. 
4. Where you previously called `forEachRoute { ... }`, you should now pass a keypath and case path for the relevant parts of your state and action, e.g. `forEachRoute(\.routes, action: \.router) { ... }`.
5. Where you previously instantiated a `TCARouter` in your view with the coordinator's entire store, you now scope the store using the same keypath and case path, e.g.  `TCARouter(store.scope(state: \.routes, action: \.router)) { ... }`.
6. If you were previously using `Effect.routeWithDelaysIfUnsupported(state.routes) { ... }`, you will now need to additionally pass a casepath for the relevant action: e.g. `Effect.routeWithDelaysIfUnsupported(state.routes, action: \.router) { ... }`.

Here's a full diff for migrating a coordinator:

```diff
struct IndexedCoordinatorView: View {
  let store: StoreOf<IndexedCoordinator>

  var body: some View {
-    TCARouter(store) { screen in
+    TCARouter(store.scope(state: \.routes, action: \.router)) { screen in
      SwitchStore(screen) { screen in
        switch screen {
        case .home:
          CaseLet(
            \Screen.State.home,
            action: Screen.Action.home,
            then: HomeView.init
          )
        case .numbersList:
          CaseLet(
            \Screen.State.numbersList,
            action: Screen.Action.numbersList,
            then: NumbersListView.init
          )
        case .numberDetail:
          CaseLet(
            \Screen.State.numberDetail,
            action: Screen.Action.numberDetail,
            then: NumberDetailView.init
          )
        }
      }
    }
  }
}

+@Reducer
struct IndexedCoordinator {
-  struct State: Equatable, IndexedRouterState {
+  struct State: Equatable {
    var routes: [Route<Screen.State>]
  }

-  enum Action: IndexedRouterAction {
+  enum Action {
-    case routeAction(Int, action: Screen.Action)
-    case updateRoutes([Route<Screen.State>])
+    case router(IndexedRouterActionOf<Screen>)
  }

  var body: some ReducerOf<Self> {
    Reduce<State, Action> { state, action in
      switch action {
-      case .routeAction(_, .home(.startTapped)):
+      case .router(.routeAction(_, .home(.startTapped))):
        state.routes.presentSheet(.numbersList(.init(numbers: Array(0 ..< 4))), embedInNavigationView: true)

-      case let .routeAction(_, .numbersList(.numberSelected(number))):
+      case let .router(.routeAction(_, .numbersList(.numberSelected(number)))):
        state.routes.push(.numberDetail(.init(number: number)))

-      case .routeAction(_, .numberDetail(.goBackTapped)):
+      case .router(.routeAction(_, .numberDetail(.goBackTapped))):
        state.routes.goBack()

-      case .routeAction(_, .numberDetail(.goBackToRootTapped)):
+      case .router(.routeAction(_, .numberDetail(.goBackToRootTapped))):
-        return .routeWithDelaysIfUnsupported(state.routes) {
+        return .routeWithDelaysIfUnsupported(state.routes, action: \.router) {
          $0.goBackToRoot()
        }

      default:
        break
      }
      return .none
    }
-    .forEachRoute {
+    .forEachRoute(\.routes, action: \.router) {
      Screen()
    }
  }
}
```

## Easy migration

As an alternative to the above, you might prefer to perform a simpler migration in the short-term. If so, you can skip steps 2 and 3 above, and instead manually add a casepath to your coordinator's action type:

```swift
// Quick update for an action that formerly conformed to `IdentifiedRouterAction`.
enum Action: CasePathable {
  case updateRoutes(IdentifiedArrayOf<Route<Screen.State>>)
  case routeAction(Screen.State.ID, action: Screen.Action)

  static var allCasePaths = AllCasePaths()

  struct AllCasePaths {
    var router: AnyCasePath<Action, IdentifiedRouterAction<Screen.State, Screen.Action>> {
      AnyCasePath { routerAction in
        switch routerAction {
        case let .routeAction(id, action):
          return .routeAction(id, action: action)
        case let .updateRoutes(newRoutes):
          return .updateRoutes(IdentifiedArray(uniqueElements: newRoutes))
        }
      } extract: { action in
        switch action {
        case let .routeAction(id, action: action):
          return .routeAction(id: id, action: action)
        case let .updateRoutes(newRoutes):
          return .updateRoutes(newRoutes.elements)
        }
      }
    }
  }
}
``` 
