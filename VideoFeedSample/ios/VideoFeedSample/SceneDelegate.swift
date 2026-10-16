import UIKit
import React_RCTAppDelegate

/// Required by the iOS 27 SDK (Xcode 27): apps must adopt the UIKit scene life cycle.
/// RCTAppDelegate still owns the React Native factory; this delegate creates the
/// UIWindow for the connected UIWindowScene.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else {
      return
    }
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
      return
    }
    guard let moduleName = appDelegate.moduleName else {
      return
    }

    let rootView = appDelegate.rootViewFactory.view(
      withModuleName: moduleName,
      initialProperties: appDelegate.initialProps,
      launchOptions: nil
    )
    rootView.backgroundColor = .black

    let rootViewController = UIViewController()
    rootViewController.view = rootView

    let window = UIWindow(windowScene: windowScene)
    window.frame = windowScene.coordinateSpace.bounds
    window.backgroundColor = .black
    window.rootViewController = rootViewController
    self.window = window
    appDelegate.window = window
    window.makeKeyAndVisible()
  }
}
