import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Register our native UIKit platform view factory for testing dynamic iOS bottom tab bar
    let registrar = self.registrar(forPlugin: "NativeTabBarPlugin")
    if let reg = registrar {
        reg.register(
            NativeTabBarFactory(messenger: reg.messenger()),
            withId: "native_ios_tab_bar"
        )
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

// MARK: - Native Tab Bar Platform View Factory
public class NativeTabBarFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    public func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return NativeTabBarView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger
        )
    }

    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

// MARK: - Native Tab Bar Platform View Implementation
public class NativeTabBarView: NSObject, FlutterPlatformView, UITabBarDelegate {
    private var _tabBar: UITabBar
    private var channel: FlutterMethodChannel
    private var blurView: UIVisualEffectView?
    private var tintView: UIView?
    private var topBorder: UIView?

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        _tabBar = UITabBar(frame: frame)
        channel = FlutterMethodChannel(name: "native_tab_bar_\(viewId)", binaryMessenger: messenger)
        super.init()
        _tabBar.delegate = self
        setupTabBar(args: args)
    }

    public func view() -> UIView {
        return _tabBar
    }

    private func setupTabBar(args: Any?) {
        let dict = args as? [String: Any]
        let currentIndex = dict?["currentIndex"] as? Int ?? 0
        let activeColorHex = dict?["accentColor"] as? String ?? "#007AFF"
        let bgColorHex = dict?["backgroundColor"] as? String ?? "#FFFFFF"
        let isDarkBackground = dict?["isDarkBackground"] as? Bool ?? false
        
        let activeColor = hexStringToUIColor(hex: activeColorHex)
        let bgColor = hexStringToUIColor(hex: bgColorHex)

        // 1. Make standard UITabBar container background completely clear to unlock transparency
        _tabBar.backgroundImage = UIImage()
        _tabBar.shadowImage = UIImage()
        _tabBar.backgroundColor = .clear

        // 2. Clear out any previous custom subviews we added
        blurView?.removeFromSuperview()
        tintView?.removeFromSuperview()
        topBorder?.removeFromSuperview()

        // 3. Setup system-level high-fidelity frosted glass blur using systemUltraThinMaterial
        let blurEffect: UIBlurEffect
        if #available(iOS 13.0, *) {
            blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        } else {
            blurEffect = UIBlurEffect(style: .light)
        }
        
        let localBlurView = UIVisualEffectView(effect: blurEffect)
        localBlurView.frame = _tabBar.bounds
        localBlurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        _tabBar.insertSubview(localBlurView, at: 0)
        self.blurView = localBlurView

        // 4. Custom translucent tint overlay dynamically blended over the blur
        let localTintView = UIView(frame: localBlurView.bounds)
        localTintView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        if isDarkBackground {
            // Blend 10% of the active dark background color into semi-transparent black for visual depth
            let darkBlend = ColorBlend(base: .black, blend: bgColor, ratio: 0.1)
            localTintView.backgroundColor = darkBlend.withAlphaComponent(0.18)
        } else {
            // Check for warm orange/red hues
            let isWarm = checkIsWarmColor(color: bgColor)
            if isWarm {
                // Peach-translucent light overlay
                localTintView.backgroundColor = bgColor.withAlphaComponent(0.18)
            } else {
                // Soft white frosted overlay
                localTintView.backgroundColor = UIColor.white.withAlphaComponent(0.18)
            }
        }
        localBlurView.contentView.addSubview(localTintView)
        self.tintView = localTintView

        // 5. Dynamic micro-thin top border (0.5 points)
        let border = UIView(frame: CGRect(x: 0, y: 0, width: _tabBar.bounds.width, height: 0.5))
        border.autoresizingMask = [.flexibleWidth]
        border.backgroundColor = isDarkBackground 
            ? UIColor.white.withAlphaComponent(0.15) 
            : UIColor.black.withAlphaComponent(0.12)
        _tabBar.addSubview(border)
        self.topBorder = border

        // 6. Set appearance settings dynamically
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground() // Ensure transparency in UITabBar itself
        
        let inactiveColor = isDarkBackground 
            ? UIColor.white.withAlphaComponent(0.5) 
            : UIColor.black.withAlphaComponent(0.55)

        appearance.stackedLayoutAppearance.normal.iconColor = inactiveColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: inactiveColor,
            .font: UIFont.systemFont(ofSize: 10, weight: .regular)
        ]
        
        appearance.stackedLayoutAppearance.selected.iconColor = activeColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: activeColor,
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]

        _tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            _tabBar.scrollEdgeAppearance = appearance
        }

        // 7. Set tab items with system SF Symbols
        let itemsData = [
            ("Today", "doc.text.image"),
            ("Games", "gamecontroller"),
            ("Apps", "square.stack.3d.up"),
            ("Arcade", "play.circle"),
            ("Search", "magnifyingglass")
        ]

        var tabBarItems: [UITabBarItem] = []
        for (index, data) in itemsData.enumerated() {
            var image: UIImage? = nil
            var selectedImage: UIImage? = nil
            
            if #available(iOS 13.0, *) {
                image = UIImage(systemName: data.1)
                selectedImage = UIImage(systemName: data.1)
            }
            
            let item = UITabBarItem(title: data.0, image: image, tag: index)
            item.selectedImage = selectedImage
            tabBarItems.append(item)
        }

        _tabBar.items = tabBarItems
        if currentIndex < tabBarItems.count {
            _tabBar.selectedItem = tabBarItems[currentIndex]
        }
        
        _tabBar.tintColor = activeColor
    }

    // UITabBarDelegate callback
    public func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        channel.invokeMethod("onTap", arguments: item.tag)
    }

    private func checkIsWarmColor(color: UIColor) -> Bool {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard color.getRed(&r, green: &g, blue: &b, alpha: &a) else { return false }
        
        // HSL mapping in Swift
        let maxVal = max(r, g, b)
        let minVal = min(r, g, b)
        var h: CGFloat = 0
        var s: CGFloat = 0
        let l: CGFloat = (maxVal + minVal) / 2.0

        if maxVal != minVal {
            let d = maxVal - minVal
            s = l > 0.5 ? d / (2.0 - maxVal - minVal) : d / (maxVal + minVal)
            if maxVal == r {
                h = (g - b) / d + (g < b ? 6.0 : 0.0)
            } else if maxVal == g {
                h = (b - r) / d + 2.0
            } else if maxVal == b {
                h = (r - g) / d + 4.0
            }
            h /= 6.0
        }
        
        let hueDegrees = h * 360.0
        // Warm ranges: Reds/Oranges/Yellows [340, 360] or [0, 50]
        return (hueDegrees >= 340.0 || hueDegrees <= 50.0) && s > 0.2 && l > 0.3
    }

    private func ColorBlend(base: UIColor, blend: UIColor, ratio: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        guard base.getRed(&r1, green: &g1, blue: &b1, alpha: &a1) else { return base }
        guard blend.getRed(&r2, green: &g2, blue: &b2, alpha: &a2) else { return base }
        
        return UIColor(
            red: r1 * (1.0 - ratio) + r2 * ratio,
            green: g1 * (1.0 - ratio) + g2 * ratio,
            blue: b1 * (1.0 - ratio) + b2 * ratio,
            alpha: 1.0
        )
    }

    private func hexStringToUIColor(hex: String) -> UIColor {
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }

        if cString.count != 6 {
            return UIColor.systemBlue
        }

        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: 1.0
        )
    }
}
