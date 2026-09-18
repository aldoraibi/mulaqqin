import Cocoa
import WebKit

final class AppDelegate: NSObject, NSApplicationDelegate, WKScriptMessageHandler, WKNavigationDelegate, NSWindowDelegate {
    var window: NSWindow!
    var web: WKWebView!
    var activity: NSObjectProtocol?
    var pinItem: NSMenuItem!
    let selfTest = ProcessInfo.processInfo.environment["MULAQQIN_SELFTEST"] != nil

    func applicationDidFinishLaunching(_ note: Notification) {
        buildMenu()

        let cfg = WKWebViewConfiguration()
        cfg.websiteDataStore = .default()
        cfg.userContentController.add(self, name: "wake")
        cfg.userContentController.add(self, name: "pin")
        cfg.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

        web = WKWebView(frame: .zero, configuration: cfg)
        web.navigationDelegate = self
        web.setValue(false, forKey: "drawsBackground")
        web.allowsMagnification = false

        let bg = NSColor(srgbRed: 0x0A/255, green: 0x0C/255, blue: 0x0A/255, alpha: 1)
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1100, height: 760),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "الملقّن العربي"
        window.appearance = NSAppearance(named: .darkAqua)
        window.backgroundColor = bg
        window.minSize = NSSize(width: 460, height: 420)
        window.contentView = web
        window.delegate = self
        window.setFrameAutosaveName("MulaqqinMain")
        if !window.setFrameUsingName("MulaqqinMain") { window.center() }
        window.collectionBehavior = [.fullScreenPrimary]

        if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
            web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ s: NSApplication) -> Bool { true }

    // ===== جسر الصفحة =====
    func userContentController(_ c: WKUserContentController, didReceive m: WKScriptMessage) {
        if m.name == "wake" { setWake((m.body as? Bool) ?? false) }
        if m.name == "pin" { togglePin(nil) }
    }

    func setWake(_ on: Bool) {
        if on, activity == nil {
            activity = ProcessInfo.processInfo.beginActivity(
                options: [.idleDisplaySleepDisabled, .userInitiated],
                reason: "تشغيل الملقّن أثناء التصوير")
        } else if !on, let a = activity {
            ProcessInfo.processInfo.endActivity(a); activity = nil
        }
    }

    @objc func togglePin(_ sender: Any?) {
        let pinned = window.level != .floating
        window.level = pinned ? .floating : .normal
        pinItem.state = pinned ? .on : .off
        web.evaluateJavaScript("window.__setPinned && window.__setPinned(\(pinned))")
    }

    func webView(_ w: WKWebView, didFinish n: WKNavigation!) {
        w.evaluateJavaScript("window.__setPinned && window.__setPinned(\(window.level == .floating))")
        guard selfTest else { return }
        let js = "(function(){var p=localStorage.getItem('selftest'); localStorage.setItem('selftest','ok'); return 'prev=' + p + ' dialog=' + (typeof HTMLDialogElement) + ' bridge=' + !!(window.webkit&&window.webkit.messageHandlers.wake) + ' guideOpen=' + document.getElementById('guide').open + ' flowTop=' + document.getElementById('flow').getBoundingClientRect().top + ' vh=' + innerHeight;})()"
        w.evaluateJavaScript(js) { r, e in
            print("SELFTEST", r ?? "nil", e.map { "\($0)" } ?? "")
            fflush(stdout)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { NSApp.terminate(nil) }
        }
    }

    // الروابط الخارجية تفتح في المتصفح
    func webView(_ w: WKWebView, decidePolicyFor a: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let u = a.request.url, a.navigationType == .linkActivated, u.scheme != "file" {
            NSWorkspace.shared.open(u); decisionHandler(.cancel); return
        }
        decisionHandler(.allow)
    }

    @objc func showGuide(_ s: Any?) { web.evaluateJavaScript("window.__openGuide && window.__openGuide()") }
    @objc func zoomText(_ s: NSMenuItem) { web.evaluateJavaScript("window.__size && window.__size(\(s.tag))") }

    // ===== القوائم =====
    func buildMenu() {
        let main = NSMenu()
        func sub(_ title: String) -> NSMenu {
            let item = NSMenuItem(); let m = NSMenu(title: title); item.submenu = m; main.addItem(item); return m
        }
        let app = sub("الملقّن العربي")
        app.addItem(withTitle: "عن الملقّن العربي", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        app.addItem(.separator())
        app.addItem(withTitle: "إخفاء الملقّن", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        app.addItem(withTitle: "إنهاء الملقّن", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        let edit = sub("تحرير")
        edit.addItem(withTitle: "تراجع", action: Selector(("undo:")), keyEquivalent: "z")
        edit.addItem(withTitle: "إعادة", action: Selector(("redo:")), keyEquivalent: "Z")
        edit.addItem(.separator())
        edit.addItem(withTitle: "قص", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "نسخ", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "لصق", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "تحديد الكل", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        let view = sub("عرض")
        let bigger = view.addItem(withTitle: "تكبير الخط", action: #selector(zoomText(_:)), keyEquivalent: "+"); bigger.tag = 4; bigger.target = self
        let smaller = view.addItem(withTitle: "تصغير الخط", action: #selector(zoomText(_:)), keyEquivalent: "-"); smaller.tag = -4; smaller.target = self
        view.addItem(.separator())
        pinItem = view.addItem(withTitle: "فوق كل النوافذ", action: #selector(togglePin(_:)), keyEquivalent: "t")
        pinItem.keyEquivalentModifierMask = [.command, .shift]; pinItem.target = self
        let fs = view.addItem(withTitle: "ملء الشاشة", action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f")
        fs.keyEquivalentModifierMask = [.command, .control]

        let win = sub("نافذة")
        win.addItem(withTitle: "تصغير", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        win.addItem(withTitle: "إغلاق", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        NSApp.windowsMenu = win

        let help = sub("مساعدة")
        let g = help.addItem(withTitle: "طريقة الاستخدام", action: #selector(showGuide(_:)), keyEquivalent: "?"); g.target = self
        NSApp.helpMenu = help

        NSApp.mainMenu = main
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
