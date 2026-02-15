
import SwiftUI

/// A custom linear progress bar that displays passed and failed test counts
/// as segmented green and red portions.
struct TestProgressBar: View {
    let passedCount: Int
    let failedCount: Int
    let totalTestCount: Int
    
    var body: some View {
        GeometryReader { geometry in
            let total = CGFloat(max(totalTestCount, 1))
            let minSegmentWidth: CGFloat = 4
            
            // Calculate proportional widths
            let rawPassedWidth = geometry.size.width * (CGFloat(passedCount) / total)
            let rawFailedWidth = geometry.size.width * (CGFloat(failedCount) / total)
            
            // Adjustment for minWidth: if we have failures, they must be at least minSegmentWidth
            let adjustedFailedWidth = failedCount > 0 ? max(rawFailedWidth, minSegmentWidth) : 0
            let adjustedPassedWidth = passedCount > 0 ? max(rawPassedWidth - (adjustedFailedWidth - rawFailedWidth), 0) : 0
            
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 8)
                
                HStack(spacing: 0) {
                    // Passed portion (Green)
                    if passedCount > 0 {
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: adjustedPassedWidth, height: 8)
                            .clipShape(BarEndShape(
                                isLeading: true,
                                isTrailing: failedCount == 0 && passedCount == totalTestCount
                            ))
                    }
                    
                    // Failed portion (Red)
                    if failedCount > 0 {
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: adjustedFailedWidth, height: 8)
                            .clipShape(BarEndShape(
                                isLeading: passedCount == 0,
                                isTrailing: (passedCount + failedCount) == totalTestCount
                            ))
                    }
                }
            }
        }
        .frame(height: 8)
        .animation(
            (passedCount == 0 && failedCount == 0) ? nil : .spring(duration: 0.3),
            value: passedCount
        )
        .animation(
            (passedCount == 0 && failedCount == 0) ? nil : .spring(duration: 0.3),
            value: failedCount
        )
    }
}

/// Helper shape to handle capsule ends for the colored segments
private struct BarEndShape: Shape {
    let isLeading: Bool
    let isTrailing: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cornerSize = CGSize(width: rect.height / 2, height: rect.height / 2)
        
        path.addRoundedRect(
            in: rect,
            cornerSize: cornerSize,
            style: .continuous
        )
        
        // If not leading, we want to square off the left side
        if !isLeading {
            let leftRect = CGRect(x: 0, y: 0, width: cornerSize.width, height: rect.height)
            path.addRect(leftRect)
        }
        
        // If not trailing, we want to square off the right side
        if !isTrailing {
            let rightRect = CGRect(x: rect.width - cornerSize.width, y: 0, width: cornerSize.width, height: rect.height)
            path.addRect(rightRect)
        }
        
        return path
    }
}
