import Foundation

/// Represents a 2D grid of terminal cells
class TerminalGrid {
    /// Number of rows in the grid
    private(set) var rows: Int
    
    /// Number of columns in the grid
    private(set) var columns: Int
    
    /// The actual grid storage (row-major order)
    private var cells: [[TerminalCell]]
    
    /// Tracks which lines have wrapping enabled
    private var lineWraps: [Bool]
    
    init(rows: Int, columns: Int) {
        self.rows = rows
        self.columns = columns
        self.cells = Array(repeating: Array(repeating: TerminalCell.blank, count: columns), count: rows)
        self.lineWraps = Array(repeating: false, count: rows)
    }
    
    /// Get a cell at the specified position
    subscript(row: Int, column: Int) -> TerminalCell {
        get {
            guard row >= 0 && row < rows && column >= 0 && column < columns else {
                return TerminalCell.blank
            }
            return cells[row][column]
        }
        set {
            guard row >= 0 && row < rows && column >= 0 && column < columns else {
                return
            }
            cells[row][column] = newValue
        }
    }
    
    /// Get an entire row
    func getRow(_ row: Int) -> [TerminalCell] {
        guard row >= 0 && row < rows else {
            return Array(repeating: TerminalCell.blank, count: columns)
        }
        return cells[row]
    }
    
    /// Set an entire row
    func setRow(_ row: Int, cells: [TerminalCell]) {
        guard row >= 0 && row < rows else { return }
        self.cells[row] = cells.count == columns ? cells : 
            cells + Array(repeating: TerminalCell.blank, count: max(0, columns - cells.count))
    }
    
    /// Check if a line has wrapping enabled
    func isLineWrapped(_ row: Int) -> Bool {
        guard row >= 0 && row < rows else { return false }
        return lineWraps[row]
    }
    
    /// Set line wrapping flag
    func setLineWrapped(_ row: Int, wrapped: Bool) {
        guard row >= 0 && row < rows else { return }
        lineWraps[row] = wrapped
    }
    
    /// Clear a specific row
    func clearRow(_ row: Int, withCell cell: TerminalCell = .blank) {
        guard row >= 0 && row < rows else { return }
        cells[row] = Array(repeating: cell, count: columns)
        lineWraps[row] = false
    }
    
    /// Clear the entire grid
    func clear(withCell cell: TerminalCell = .blank) {
        cells = Array(repeating: Array(repeating: cell, count: columns), count: rows)
        lineWraps = Array(repeating: false, count: rows)
    }
    
    /// Resize the grid, preserving content where possible
    func resize(rows newRows: Int, columns newColumns: Int) {
        // Handle column changes
        if newColumns != columns {
            for i in 0..<min(rows, newRows) {
                if newColumns > columns {
                    // Add blank cells to the right
                    cells[i].append(contentsOf: Array(repeating: TerminalCell.blank, count: newColumns - columns))
                } else {
                    // Truncate cells on the right
                    cells[i] = Array(cells[i].prefix(newColumns))
                }
            }
        }
        
        // Handle row changes
        if newRows > rows {
            // Add blank rows at the bottom
            let newRow = Array(repeating: TerminalCell.blank, count: newColumns)
            cells.append(contentsOf: Array(repeating: newRow, count: newRows - rows))
            lineWraps.append(contentsOf: Array(repeating: false, count: newRows - rows))
        } else if newRows < rows {
            // Remove rows from the bottom
            cells = Array(cells.prefix(newRows))
            lineWraps = Array(lineWraps.prefix(newRows))
        }
        
        self.rows = newRows
        self.columns = newColumns
    }
    
    /// Scroll the grid up by one line (bottom line becomes blank)
    func scrollUp(top: Int = 0, bottom: Int? = nil, fillCell: TerminalCell = .blank) {
        let bottom = bottom ?? (rows - 1)
        guard top >= 0 && top < rows && bottom >= top && bottom < rows else { return }
        
        // Move lines up
        for i in top..<bottom {
            cells[i] = cells[i + 1]
            lineWraps[i] = lineWraps[i + 1]
        }
        
        // Clear the bottom line
        cells[bottom] = Array(repeating: fillCell, count: columns)
        lineWraps[bottom] = false
    }
    
    /// Scroll the grid down by one line (top line becomes blank)
    func scrollDown(top: Int = 0, bottom: Int? = nil, fillCell: TerminalCell = .blank) {
        let bottom = bottom ?? (rows - 1)
        guard top >= 0 && top < rows && bottom >= top && bottom < rows else { return }
        
        // Move lines down
        for i in stride(from: bottom, through: top + 1, by: -1) {
            cells[i] = cells[i - 1]
            lineWraps[i] = lineWraps[i - 1]
        }
        
        // Clear the top line
        cells[top] = Array(repeating: fillCell, count: columns)
        lineWraps[top] = false
    }
    
    /// Insert blank cells at position, shifting content right
    func insertBlanks(at row: Int, column: Int, count: Int, fillCell: TerminalCell = .blank) {
        guard row >= 0 && row < rows && column >= 0 && column < columns else { return }
        
        let insertCount = min(count, columns - column)
        let blanks = Array(repeating: fillCell, count: insertCount)
        let remaining = Array(cells[row][column..<(columns - insertCount)])
        
        cells[row].replaceSubrange(column..<columns, with: blanks + remaining)
    }
    
    /// Delete cells at position, shifting content left
    func deleteCells(at row: Int, column: Int, count: Int, fillCell: TerminalCell = .blank) {
        guard row >= 0 && row < rows && column >= 0 && column < columns else { return }
        
        let deleteCount = min(count, columns - column)
        let remaining = Array(cells[row][(column + deleteCount)..<columns])
        let blanks = Array(repeating: fillCell, count: deleteCount)
        
        cells[row].replaceSubrange(column..<columns, with: remaining + blanks)
    }
    
    /// Extract text from a range of cells
    func extractText(fromRow: Int, fromCol: Int, toRow: Int, toCol: Int) -> String {
        var text = ""
        
        for row in fromRow...toRow {
            guard row >= 0 && row < rows else { continue }
            
            let startCol = (row == fromRow) ? fromCol : 0
            let endCol = (row == toRow) ? toCol : columns - 1
            
            for col in startCol...endCol {
                guard col >= 0 && col < columns else { continue }
                let cell = cells[row][col]
                if !cell.isWideContinuation {
                    text.append(Character(cell.character))
                }
            }
            
            // Add newline if not the last row and line is wrapped
            if row < toRow && !lineWraps[row] {
                text.append("\n")
            }
        }
        
        return text
    }
}
