
import Foundation

/// A grouping of related test cases.
struct TestCategory: Identifiable {
    /// The unique identifier of the category.
    let id: String
    
    /// The display name of the category.
    let name: String
    
    /// The list of test cases in this category.
    var tests: [any TestCase]
}
