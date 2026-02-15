
import Foundation

/// The outcome of a ``TestCase`` execution.
enum TestResult: Sendable, Equatable {
    /// The test has not yet been executed.
    case notRun
    
    /// The test is currently executing.
    case running
    
    /// The test completed successfully.
    case passed
    
    /// The test failed with a specific reason.
    /// - Parameter reason: A clear description of why the test failed.
    case failed(reason: String)
    
    /// The test encountered an unexpected error (e.g., throw).
    /// - Parameter message: The error description.
    case error(message: String)
    
    /// Indicates if the result represents a successful execution.
    var isPassed: Bool {
        if case .passed = self { return true }
        return false
    }
    
    /// Indicates if the result represents a failure or error.
    var isFailed: Bool {
        switch self {
        case .failed, .error: return true
        default: return false
        }
    }
}
