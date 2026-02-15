import Observation
import Foundation
import CoreSwift

/// The central coordinator for executing test suites.
///
/// `TestRunner` manages the state of test execution, including running tests,
/// tracking results, and handling concurrency/cancellation.
///
/// ## Usage
/// ```swift
/// let runner = TestRunner()
/// await runner.runAll(suites)
/// ```
@MainActor
@Observable
final class TestRunner {
    /// A dictionary mapping test IDs to their execution results.
    private(set) var results: [String: TestResult] = [:]

    /// A dictionary mapping test IDs to their execution duration in seconds.
    private(set) var durations: [String: TimeInterval] = [:]

    /// The total duration of the current or last test run.
    private(set) var totalDuration: TimeInterval = 0
    private var runStartTime: Date?

    /// Indicates if the runner is currently executing tests.
    private(set) var isRunning = false

    /// Indicates if the runner is currently paused.
    private(set) var isPaused = false

    /// The name of the test currently being executed.
    private(set) var currentTestName: String?

    /// The total number of tests in the current run queue.
    private(set) var totalTestsCount: Int = 0


    private var pauseContinuation: CheckedContinuation<Void, Never>?


    var passedCount: Int { results.values.filter { $0.isPassed }.count }
    var failedCount: Int { results.values.filter { $0.isFailed }.count }
    var totalRun: Int { results.values.filter { $0 != .notRun && $0 != .running }.count  } // Count completed tests

    var canExport: Bool { !results.isEmpty }

    // MARK: - Run All

    func reset() {
        results.removeAll()
        durations.removeAll()
        runStartTime = nil
        totalDuration = 0
        isRunning = false
        isPaused = false
    }

    /// Runs all provided test suites sequentially.
    ///
    /// This method suspends until all tests complete, the runner is stopped, or the task is cancelled.
    /// It resets any previous results before starting.
    ///
    /// - Parameter suites: The list of ``TestSuite``s to execute.
    func runAll(_ suites: [TestSuite]) async {
        guard !isRunning else { return }

        // Clear previous results
        reset()

        // Calculate total tests
        totalTestsCount = suites.reduce(0) { suitesum, suite in
            suitesum + suite.categories.reduce(0) { catsum, cat in
                catsum + cat.tests.count
            }
        }

        runStartTime = Date()

        isRunning = true
        isPaused = false

        for suite in suites {
            if Task.isCancelled { break }
            for category in suite.categories {
                if Task.isCancelled { break }
                for test in category.tests {
                    if Task.isCancelled { break }
                    await checkPausePoint()
                    if Task.isCancelled { break }

                    results[test.id] = .running
                    currentTestName = test.name

                    CoreLogger.shared.info("▶ \(test.id)", category: .testing)

                    let start = Date()
                    let result = await runSingleTest(test)
                    currentTestName = nil

                    // If the result came back as .notRun (due to cancellation), stop
                    if result == .notRun && Task.isCancelled { break }

                    let elapsed = Date().timeIntervalSince(start)
                    durations[test.id] = elapsed
                    let time = String(format: "%.3fs", elapsed)

                    switch result {
                    case .passed:
                        CoreLogger.shared.info("✓ \(test.id) (\(time))", category: .testing)
                    case .failed(let reason):
                        CoreLogger.shared.error("✗ \(test.id) (\(time))", category: .testing)
                        CoreLogger.shared.error("  reason: \(reason)", category: .testing)
                    case .error(let message):
                        CoreLogger.shared.error("⚠ \(test.id) (\(time))", category: .testing)
                        CoreLogger.shared.error("  error: \(message)", category: .testing)
                    case .notRun, .running:
                        CoreLogger.shared.notice("⊘ \(test.id)", category: .testing)
                    }

                    if Task.isCancelled { break }
                    results[test.id] = result
                    
                    // Update total duration incrementally for live UI
                    if let start = runStartTime {
                        totalDuration = Date().timeIntervalSince(start)
                    }
                }
            }
        }

        totalDuration = Date().timeIntervalSince(runStartTime ?? Date())
        isRunning = false
    }

    func runTest(_ test: any TestCase) async {
        guard !isRunning else { return } // Prevent running individual while suite is running
        results[test.id] = .running

        let start = Date()
        let result = await runSingleTest(test)
        let elapsed = Date().timeIntervalSince(start)
        durations[test.id] = elapsed

        results[test.id] = result
    }

    func runCategory(_ category: TestCategory) async {
        guard !isRunning else { return }
        for test in category.tests {
            if Task.isCancelled { break }
            results[test.id] = .running
            let result = await runSingleTest(test)
            if Task.isCancelled { break }
            results[test.id] = result
        }
    }

    // MARK: - Stop / Pause

    /// Stops the execution of tests.
    ///
    /// Resumes any paused continuation and resets internal state to ensure a clean exit.
    /// Calling this method helps the `runAll` loop exit gracefully.
    func stop() {
        pauseContinuation?.resume()
        pauseContinuation = nil
        isPaused = false
        currentTestName = nil

        // Reset any tests that were still marked as running
        for (id, result) in results where result == .running {
            results[id] = .notRun
        }
    }

    /// Pauses the test execution at the next available check point.
    func pause() {
        isPaused = true
    }

    /// Resumes test execution if currently paused.
    func resume() {
        isPaused = false
        pauseContinuation?.resume()
        pauseContinuation = nil
    }

    private func checkPausePoint() async {
        guard isPaused else { return }
        await withCheckedContinuation { self.pauseContinuation = $0 }
    }

    private func runSingleTest(_ test: any TestCase) async -> TestResult {
        // 1. Check before running
        if Task.isCancelled { return .notRun }

        do {
            // 2. Run the test
            let result = try await test.run()

            // 3. Check after running (before returning result)
            if Task.isCancelled { return .notRun }

            return result
        } catch {
            return .error(message: error.localizedDescription)
        }
    }

}
