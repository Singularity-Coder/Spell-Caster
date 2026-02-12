import Foundation

/// Manages text selection in the terminal
class SelectionManager {
    // MARK: - Properties
    
    private let state: TerminalState
    private(set) var selection: Selection?
    private var selectionStart: (row: Int, col: Int)?
    
    // MARK: - Initialization
    
    init(state: TerminalState) {
        self.state = state
    }
    
    // MARK: - Selection Management
    
    func startSelection(at position: (row: Int, col: Int)) {
        selectionStart = position
        selection = Selection(
            start: position,
            end: position
        )
    }
    
    func updateSelection(to position: (row: Int, col: Int)) {
        guard let start = selectionStart else { return }
        
        // Determine start and end based on position
        let (startPos, endPos) = orderPositions(start, position)
        
        selection = Selection(
            start: startPos,
            end: endPos
        )
    }
    
    func endSelection() {
        // Selection is complete, keep it active
    }
    
    func clearSelection() {
        selection = nil
        selectionStart = nil
    }
    
    func selectAll() {
        let grid = state.activeGrid
        selection = Selection(
            start: (row: 0, col: 0),
            end: (row: grid.rows - 1, col: grid.columns - 1)
        )
    }
    
    // MARK: - Text Extraction
    
    var selectedText: String? {
        guard let selection = selection else { return nil }
        
        let grid = state.activeGrid
        return grid.extractText(
            fromRow: selection.start.row,
            fromCol: selection.start.col,
            toRow: selection.end.row,
            toCol: selection.end.col
        )
    }
    
    // MARK: - Helper Methods
    
    private func orderPositions(
        _ pos1: (row: Int, col: Int),
        _ pos2: (row: Int, col: Int)
    ) -> (start: (row: Int, col: Int), end: (row: Int, col: Int)) {
        if pos1.row < pos2.row || (pos1.row == pos2.row && pos1.col <= pos2.col) {
            return (pos1, pos2)
        } else {
            return (pos2, pos1)
        }
    }
}

// MARK: - Selection

struct Selection {
    let start: (row: Int, col: Int)
    let end: (row: Int, col: Int)
}
