
import SwiftUI
import CoreSwift // Assuming TestResult is in CoreSwift or Models. If Models, I need to know where TestResult is defined.

// MARK: StatusIcon

/// A compact status indicator that maps a discrete state to an SF Symbol
/// with a semantic color.
///
/// Reusable for any status display (test results, task progress, etc.).
///
/// ```swift
/// StatusIcon(state: .success)
/// StatusIcon(state: .inProgress)
/// ```
struct StatusIcon: View {
    /// The current status to display.
    let state: State
    
    /// Discrete states that the icon can represent.
    enum State {
        /// No action taken yet — hollow circle.
        case idle
        /// Currently in progress — spinning indicator.
        case inProgress
        /// Completed successfully — green checkmark.
        case success
        /// Failed — red X mark.
        case failure
        /// Error occurred — purple exclamation.
        case error
    }
    
    var body: some View {
        switch state {
        case .idle:
            Image(systemName: "circle")
                .foregroundStyle(.secondary)
        case .inProgress:
            ProgressView()
                .scaleEffect(0.5)
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failure:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
        case .error:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.purple)
        }
    }
}

// MARK: - TestResult Convenience

extension StatusIcon.State {
    /// Creates a ``StatusIcon/State`` from a ``TestResult``.
    ///
    /// - Parameter result: The test result to convert.
    init(from result: TestResult) {
        switch result {
        case .notRun: self = .idle
        case .running: self = .inProgress
        case .passed: self = .success
        case .failed: self = .failure
        case .error: self = .error
        }
    }
}
