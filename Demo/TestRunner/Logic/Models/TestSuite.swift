
import Foundation

/// A collection of test categories representing a full testing suite.
struct TestSuite: Identifiable {
    /// The unique identifier of the suite.
    let id: String
    
    /// The display name of the suite.
    let name: String
    
    /// The categories of tests contained within this suite.
    var categories: [TestCategory]
}
