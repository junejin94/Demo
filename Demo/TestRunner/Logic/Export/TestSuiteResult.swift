
import Foundation
import CoreSwift

/// A read-only snapshot of a test suite's execution results.
///
/// This structure captures the state of a test run for export or display purposes.
struct TestSuiteResult {
    /// The name of the test suite.
    let suiteName: String
    
    /// The categories containing test results.
    let categories: [CategoryResult]
    
    /// A snapshot of a category's results.
    struct CategoryResult {
        /// The name of the category.
        let name: String
        
        /// The individual test case results.
        let tests: [TestCaseResult]
    }
    
    /// A snapshot of a single test case's result.
    struct TestCaseResult {
        /// The unique identifiers of the test.
        let id: String
        
        /// The name of the test.
        let name: String
        
        /// The outcome of the test.
        let result: TestResult
    }
}

extension TestSuiteResult {
    var allTests: [TestCaseResult] {
        categories.flatMap(\.tests)
    }
    
    var totalCount: Int {
        allTests.count
    }
    
    var failureCount: Int {
        allTests.filter { $0.result.isFailed }.count
    }
    
    var passedCount: Int {
        allTests.filter { $0.result.isPassed }.count
    }
}
