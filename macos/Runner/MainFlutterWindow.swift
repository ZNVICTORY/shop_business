import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  /// 与 Flutter 侧大屏导航断点（900）一致，默认桌面窗口尺寸。
  private static let defaultWidth: CGFloat = 1280
  private static let defaultHeight: CGFloat = 800
  private static let minWidth: CGFloat = 900
  private static let minHeight: CGFloat = 600

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    self.contentViewController = flutterViewController

    self.minSize = NSSize(
      width: Self.minWidth,
      height: Self.minHeight
    )

    let w = Self.defaultWidth
    let h = Self.defaultHeight
    if let screen = NSScreen.main {
      let vf = screen.visibleFrame
      let x = vf.origin.x + (vf.size.width - w) / 2
      let y = vf.origin.y + (vf.size.height - h) / 2
      setFrame(NSRect(x: x, y: y, width: w, height: h), display: true)
    } else {
      setFrame(NSRect(x: 0, y: 0, width: w, height: h), display: true)
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
