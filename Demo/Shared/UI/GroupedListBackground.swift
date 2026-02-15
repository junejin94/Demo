
import SwiftUI

/// A view modifier that applies the standard grouped list background styling
/// used throughout the app.
///
/// This replaces the two-line boilerplate of `.scrollContentBackground(.hidden)`
/// and `.background(Color(uiColor: .systemGroupedBackground))`.
///
/// ## Usage
/// ```swift
/// List {
///     // content
/// }
/// .modifier(GroupedListBackground())
/// ```
struct GroupedListBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(Color(uiColor: .systemGroupedBackground))
    }
}

extension View {
    /// Applies the standard grouped list background styling.
    ///
    /// Usage:
    /// ```swift
    /// List { ... }
    ///     .groupedListBackground()
    /// ```
    ///
    /// - Returns: A view with hidden scroll content background and the
    ///   system grouped background color applied.
    func groupedListBackground() -> some View {
        modifier(GroupedListBackground())
    }
}
