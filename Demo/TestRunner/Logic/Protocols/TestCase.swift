
import Foundation

/// A protocol defining a single executable test case.
///
/// Conforming types represent individual tests that can be run by the ``TestRunner``.
/// Each test case must identify itself and provide an asynchronous `run()` method.
///
/// ## Example
/// ```swift
/// struct ExampleTest: TestCase {
///     let id = "example.test"
///     let name = "Example Test"
///
///     func run() async throws -> TestResult {
///         // Perform testing logic
///         return .passed
///     }
/// }
/// ```
protocol TestCase: Identifiable, Sendable {
    /// A unique identifier for the test case.
    ///
    /// Used for referencing the test in results and logs.
    var id: String { get }

    /// A human-readable name for the test case.
    ///
    /// Displayed in the UI and reports.
    var name: String { get }
    
    /// Executes the test logic.
    ///
    /// - Returns: A ``TestResult`` indicating success, failure, or other states.
    /// - Throws: Any error encountered during execution (will be caught and reported as `.error`).
    func run() async throws -> TestResult
}
