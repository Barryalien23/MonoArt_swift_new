import CoreVideo
import AVFoundation
import AsciiDomain

struct GridDescriptor {
    let columns: Int
    let rows: Int

    var totalCells: Int {
        columns * rows
    }
}

enum GridPlanner {
    // Fixed aspect ratios for consistent output
    private static let landscapeAspectRatio: Double = 16.0 / 9.0  // 1.78 (horizontal)
    private static let portraitAspectRatio: Double = 9.0 / 16.0   // 0.56 (vertical)
    
    private static let minColumns = 40
    private static let maxColumns = 180
    private static let minRows = 30
    private static let maxRows = 140

    static func makeGrid(
        for pixelBuffer: CVPixelBuffer,
        orientation: AVCaptureVideoOrientation,
        parameters: EffectParameters,
        maxCells: Int
    ) -> GridDescriptor {
        let aspect: Double = orientation.isLandscape ? landscapeAspectRatio : portraitAspectRatio

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

private extension AVCaptureVideoOrientation {
    var isLandscape: Bool {
        switch self {
        case .landscapeLeft, .landscapeRight:
            return true
        default:
            return false
        }
    }
}

