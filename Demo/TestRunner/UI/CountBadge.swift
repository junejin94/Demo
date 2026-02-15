
import SwiftUI

// MARK: CountBadge

/// A capsule-shaped badge displaying a count ratio (e.g. "3/10") with a
/// semantic color indicating pass/fail/neutral status.
///
/// Reusable across any context that needs to show progress or results
/// as a compact indicator.
///
/// ```swift
/// CountBadge(value: passed, total: total, status: failed > 0 ? .failure : .success)
/// ```
struct CountBadge: View {
    /// The numerator count (e.g. number of passed items).
    let value: Int
    
    /// The denominator count (e.g. total items).
    let total: Int
    
    /// The semantic status that determines the badge color.
    var status: Status = .neutral
    
    /// The font used for the badge text.
    var font: Font = .caption2.bold()
    
    /// The horizontal padding inside the capsule.
    var horizontalPadding: CGFloat = 6
    
    /// The vertical padding inside the capsule.
    var verticalPadding: CGFloat = 2
    
    /// Semantic status options that determine badge color.
    enum Status {
        /// All items succeeded — green badge.
        case success
        /// One or more items failed — red badge.
        case failure
        /// Default state, no results yet — secondary badge.
        case neutral
    }
    
    var body: some View {
        Text("\(value)/\(total)")
            .font(font)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(badgeColor)
            .foregroundStyle(foregroundColor)
            .clipShape(Capsule())
    }
    
    // MARK: - Private
    
    private var badgeColor: Color {
        switch status {
        case .failure: .red
        case .success: .green
        case .neutral: .secondary.opacity(0.3)
        }
    }
    
    private var foregroundColor: Color {
        switch status {
        case .failure, .success: .white
        case .neutral: .primary
        }
    }
}
