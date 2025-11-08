import CoreVideo
import AsciiDomain

struct GridDescriptor {
    let columns: Int
    let rows: Int

    var totalCells: Int {
        columns * rows
    }
}

enum GridPlanner {
    // Fixed aspect ratio for consistent output (16:9 landscape)
    private static let fixedAspectRatio: Double = 16.0 / 9.0
    
    private static let minColumns = 40
    private static let maxColumns = 180
    private static let minRows = 30
    private static let maxRows = 140

    static func makeGrid(
        for pixelBuffer: CVPixelBuffer,
        parameters: EffectParameters,
        maxCells: Int
    ) -> GridDescriptor {
        // Use fixed aspect ratio instead of input buffer aspect
        // This ensures the grid always maintains the same proportions regardless of cell size
        let aspect = fixedAspectRatio

        // Cell parameter now controls density (number of columns) while maintaining aspect ratio
        // Inverted logic: higher cell value = more columns = higher density
        let cellPercent = parameters.cell.rawValue / EffectParameterValue.range.upperBound
        let unclampedColumns = Double(minColumns) + (Double(maxColumns) - Double(minColumns)) * cellPercent
        var columns = max(Int(unclampedColumns.rounded()), minColumns)
        columns = min(columns, maxColumns)

        // Calculate rows to maintain fixed aspect ratio
        var rows = max(Int((Double(columns) / aspect).rounded()), minRows)
        rows = min(rows, maxRows)

        // Ensure we don't exceed maxCells while maintaining aspect ratio
        while columns * rows > maxCells && columns > minColumns {
            columns -= 1
            rows = max(Int((Double(columns) / aspect).rounded()), minRows)
            rows = min(rows, maxRows)
        }

        while columns * rows > maxCells && rows > minRows {
            rows -= 1
        }

        return GridDescriptor(columns: max(columns, minColumns), rows: max(rows, minRows))
    }
}

