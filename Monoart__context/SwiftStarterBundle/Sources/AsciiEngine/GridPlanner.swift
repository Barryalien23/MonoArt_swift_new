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
    private static let minColumns = 40
    private static let maxColumns = 180
    private static let minRows = 30
    private static let maxRows = 140

    static func makeGrid(
        for pixelBuffer: CVPixelBuffer,
        parameters: EffectParameters,
        maxCells: Int
    ) -> GridDescriptor {
        let width = max(CVPixelBufferGetWidth(pixelBuffer), 1)
        let height = max(CVPixelBufferGetHeight(pixelBuffer), 1)
        let aspect = max(Double(width) / Double(height), 0.1)

        let cellPercent = parameters.cell.rawValue / EffectParameterValue.range.upperBound
        let unclampedColumns = Double(minColumns) + (Double(maxColumns) - Double(minColumns)) * cellPercent
        var columns = max(Int(unclampedColumns.rounded()), minColumns)
        columns = min(columns, maxColumns)

        var rows = max(Int((Double(columns) / aspect).rounded()), minRows)
        rows = min(rows, maxRows)

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

