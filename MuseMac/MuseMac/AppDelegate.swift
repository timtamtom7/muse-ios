import AppKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var menuBarViewModel = MenuBarViewModel()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
        
        // Hide dock icon for menu bar app
        NSApp.setActivationPolicy(.accessory)
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Muse")
            button.action = #selector(togglePopover)
            button.target = self
        }
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 480)
        popover.behavior = .transient
        popover.animates = true
        
        let menuBarView = MenuBarView(viewModel: menuBarViewModel)
        popover.contentViewController = NSHostingController(rootView: menuBarView)
    }
    
    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
