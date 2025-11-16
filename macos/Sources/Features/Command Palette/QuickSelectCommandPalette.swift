import SwiftUI
import GhosttyKit


struct QuickSelectCommandPalette: View {
    let surfaceView: Ghostty.SurfaceView
    
    @Binding var isPresented: Bool
    
    private var commandOptions: [CommandOption] {
        var options: [CommandOption] = []
        guard let surface = surfaceView.surfaceModel else { return options };
        do {
            let links = try surface.quickSelect().map{ link in
                return CommandOption(title: link, description: link, action: {
                    // This is probably something that can be handled from the ghostty core library via a callback,
                    // but for now this is kept simple. Not sure what logic should be placed there and what should
                    // be placed within the UI code.
                    // What would probably need to happen is that this triggers a callback, which then invokes the writeClipboard
                    // callback that the ghostty core has access to.
                    let pb = NSPasteboard.ghostty(GHOSTTY_CLIPBOARD_STANDARD)
                    pb?.declareTypes([.string], owner: nil)
                    pb?.setString(link, forType: .string)
                })
            }
            options.append(contentsOf: links);
        } catch {
            return options;
        }
        return options;
    }
    
    var body: some View {
        ZStack {
            if isPresented {
                GeometryReader { geometry in
                    VStack {
                        Spacer().frame(height: geometry.size.height * 0.05)
                        
                        ResponderChainInjector(responder: surfaceView)
                            .frame(width: 0, height: 0)
                        
                        CommandPaletteView(isPresented: $isPresented, options: commandOptions)
                            .transition(
                                .move(edge: .top)
                                .combined(with: .opacity)
                                .animation(.spring(response: 0.4, dampingFraction: 0.8))
                            )
                            .zIndex(1)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
                }
            }
        }
        .onChange(of: isPresented) { newValue in
            if !newValue {
                DispatchQueue.main.async {
                    surfaceView.window?.makeFirstResponder(surfaceView)
                }
            }
        }
    }
}

/// This is done to ensure that the given view is in the responder chain.
/// From TerminalCommandPaletteView
fileprivate struct ResponderChainInjector: NSViewRepresentable {
    let responder: NSResponder

    func makeNSView(context: Context) -> NSView {
        let dummy = NSView()
        DispatchQueue.main.async {
            dummy.nextResponder = responder
        }
        return dummy
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
