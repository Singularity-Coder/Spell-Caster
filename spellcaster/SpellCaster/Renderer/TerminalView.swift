import AppKit
import Combine

/// NSView subclass for terminal rendering
class TerminalView: NSView {
    // MARK: - Properties
    
    private let renderer: TerminalRenderer
    private var state: TerminalState
    private var cancellables = Set<AnyCancellable>()
    private var cursorTimer: Timer?
    private var cursorVisible = true
    
    var selectionManager: SelectionManager?
    
    // MARK: - Callbacks
    
    var onKeyEvent: ((NSEvent) -> Void)?
    var onResize: ((Int, Int) -> Void)?
    var onPaste: ((String) -> Void)?
    
    // MARK: - Initialization
    
    init(state: TerminalState, profile: Profile) {
        self.state = state
        self.renderer = TerminalRenderer(profile: profile)
        self.selectionManager = SelectionManager(state: state)
        
        super.init(frame: .zero)
        
        setupView()
        setupObservers()
        startCursorBlink()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        cursorTimer?.invalidate()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        wantsLayer = true
        layer?.isOpaque = true
        
        // Enable key events
        acceptsFirstResponder = true
    }
    
    private func setupObservers() {
        state.$needsDisplay
            .sink { [weak self] needsDisplay in
                if needsDisplay {
                    self?.needsDisplay = true
                    self?.state.needsDisplay = false
                }
            }
            .store(in: &cancellables)
    }
    
    private func startCursorBlink() {
        cursorTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.state.cursorBlink {
                self.cursorVisible.toggle()
                self.needsDisplay = true
            }
        }
    }
    
    // MARK: - Drawing
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        // Draw terminal content
        renderer.render(
            state: state,
            in: bounds,
            context: context,
            cursorVisible: cursorVisible && state.cursorVisible
        )
        
        // Draw selection
        if let selection = selectionManager?.selection {
            renderer.renderSelection(selection, in: bounds, context: context)
        }
    }
    
    // MARK: - Layout
    
    override func resize(withOldSuperviewSize oldSize: NSSize) {
        super.resize(withOldSuperviewSize: oldSize)
        updateTerminalSize()
    }
    
    private func updateTerminalSize() {
        let cellSize = renderer.cellSize
        let rows = Int(bounds.height / cellSize.height)
        let columns = Int(bounds.width / cellSize.width)
        
        if rows > 0 && columns > 0 {
            onResize?(rows, columns)
        }
    }
    
    // MARK: - First Responder
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func becomeFirstResponder() -> Bool {
        return true
    }
    
    // MARK: - Key Events
    
    override func keyDown(with event: NSEvent) {
        onKeyEvent?(event)
    }
    
    override func flagsChanged(with event: NSEvent) {
        // Handle modifier key changes if needed
    }
    
    // MARK: - Mouse Events
    
    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let cellSize = renderer.cellSize
        let row = Int(point.y / cellSize.height)
        let col = Int(point.x / cellSize.width)
        
        selectionManager?.startSelection(at: (row, col))
        needsDisplay = true
    }
    
    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let cellSize = renderer.cellSize
        let row = Int(point.y / cellSize.height)
        let col = Int(point.x / cellSize.width)
        
        selectionManager?.updateSelection(to: (row, col))
        needsDisplay = true
    }
    
    override func mouseUp(with event: NSEvent) {
        selectionManager?.endSelection()
        
        // Copy selection to pasteboard if double-click
        if event.clickCount == 2, let text = selectionManager?.selectedText {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(text, forType: .string)
        }
    }
    
    // MARK: - Paste
    
    override func paste(_ sender: Any?) {
        let pasteboard = NSPasteboard.general
        if let string = pasteboard.string(forType: .string) {
            onPaste?(string)
        }
    }
    
    // MARK: - Copy
    
    override func copy(_ sender: Any?) {
        guard let text = selectionManager?.selectedText else { return }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    // MARK: - Select All
    
    override func selectAll(_ sender: Any?) {
        selectionManager?.selectAll()
        needsDisplay = true
    }
}
