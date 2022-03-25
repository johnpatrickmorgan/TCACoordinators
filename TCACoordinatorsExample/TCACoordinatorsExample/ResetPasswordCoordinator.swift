import ComposableArchitecture
import FlowStacks
import SwiftUI
import TCACoordinators

// Coordinator

struct ResetPasswordCoordinatorView: View {
  let store: Store<ResetPasswordCoordinatorState, ResetPasswordCoordinatorAction>

  var body: some View {
    TCARouter(store) { screen in
      SwitchStore(screen) {
        CaseLet(
          state: /ResetPasswordScreenState.forgotPassword,
          action: ResetPasswordScreenAction.forgotPassword,
          then: ForgotPasswordView.init
        )
        CaseLet(
          state: /ResetPasswordScreenState.forgotPasswordSuccess,
          action: ResetPasswordScreenAction.forgotPasswordSuccess,
          then: ForgotPasswordSuccessView.init
        )
      }
    }
  }
}

struct ResetPasswordCoordinatorState: Equatable, IndexedRouterState {
  enum ScreenIdentifier {
    case forgotPassword
    case forgotPasswordSuccess
  }
  
  static let initialState = ResetPasswordCoordinatorState(
    screenIdentifiers: [.root(.forgotPassword, embedInNavigationView: true)]
  )

  var email = ""
  var screenIdentifiers: [Route<ScreenIdentifier>]
  var routes: [Route<ResetPasswordScreenState>] {
    get {
      screenIdentifiers.map {
        $0.map {
          switch $0 {
          case .forgotPassword:
            return .forgotPassword(.init(email: email))
          case .forgotPasswordSuccess:
            return .forgotPasswordSuccess(.init(email: email))
          }
        }
      }
    }
    set {
      screenIdentifiers = newValue.map {
        $0.map {
          switch $0 {
          case .forgotPassword(let state):
            email = state.email
            return .forgotPassword
          case .forgotPasswordSuccess:
            return .forgotPasswordSuccess
          }
        }
      }
    }
  }
}

enum ResetPasswordCoordinatorAction: IndexedRouterAction {
  case routeAction(Int, action: ResetPasswordScreenAction)
  case updateRoutes([Route<ResetPasswordScreenState>])
}

typealias ResetPasswordCoordinatorReducer = Reducer<ResetPasswordCoordinatorState, ResetPasswordCoordinatorAction, Void>

let resetPasswordCoordinatorReducer: ResetPasswordCoordinatorReducer = resetPasswordScreenReducer
  .forEachIndexedRoute(environment: { _ in })
  .withRouteReducer(Reducer { state, action, _ in
    switch action {
    case .routeAction(let i, .forgotPassword(.emailConfirmed(let email))):
      state.screenIdentifiers.push(.forgotPasswordSuccess)

    case .routeAction(_, .forgotPasswordSuccess(.goBack)):
      state.screenIdentifiers.goBack()

    default:
      break
    }
    return .none
  })

// Screen

enum ResetPasswordScreenAction {
  case forgotPassword(ForgotPasswordAction)
  case forgotPasswordSuccess(ForgotPasswordSuccessAction)
}

enum ResetPasswordScreenState: Equatable {
  case forgotPassword(ForgotPasswordState)
  case forgotPasswordSuccess(ForgotPasswordSuccessState)
}

let resetPasswordScreenReducer = Reducer<ResetPasswordScreenState, ResetPasswordScreenAction, Void>.combine(
  forgotPasswordReducer
    .pullback(
      state: /ResetPasswordScreenState.forgotPassword,
      action: /ResetPasswordScreenAction.forgotPassword,
      environment: { _ in }
    ),
  forgotPasswordSuccessReducer
    .pullback(
      state: /ResetPasswordScreenState.forgotPasswordSuccess,
      action: /ResetPasswordScreenAction.forgotPasswordSuccess,
      environment: { _ in }
    )
)

// ForgotPassword

struct ForgotPasswordView: View {
  let store: Store<ForgotPasswordState, ForgotPasswordAction>

  var body: some View {
    WithViewStore(store) { viewStore in
      VStack(spacing: 8.0) {
        TextField("Enter email", text: viewStore.binding(get: { $0.email }, send: ForgotPasswordAction.emailChanged))
        Button("Reset password", action: {
          viewStore.send(.emailConfirmed(viewStore.email))
        })
      }.padding()
    }
    .navigationTitle("Forgot Password")
  }
}

enum ForgotPasswordAction {
  case emailChanged(String)
  case emailConfirmed(String)
}

struct ForgotPasswordState: Equatable {
  var email: String
}

let forgotPasswordReducer = Reducer<
  ForgotPasswordState, ForgotPasswordAction, Void
> { state, action, _ in
  switch action {
  case .emailChanged(let email):
    state.email = email
    
  case .emailConfirmed:
    // Handled by coordinator.
    break
  }
  return .none
}

// ForgotPasswordSuccess

struct ForgotPasswordSuccessView: View {
  let store: Store<ForgotPasswordSuccessState, ForgotPasswordSuccessAction>

  var body: some View {
    WithViewStore(store) { viewStore in
      VStack {
        Text("Sent to \(viewStore.email)")
        Button("Go back", action: {
          viewStore.send(.goBack)
        })
      }
    }
    .navigationTitle("Success")
  }
}

enum ForgotPasswordSuccessAction {
  case goBack
}

struct ForgotPasswordSuccessState: Equatable {
  let email: String
}

let forgotPasswordSuccessReducer = Reducer<ForgotPasswordSuccessState, ForgotPasswordSuccessAction, Void> { _, _, _ in
  .none
}
