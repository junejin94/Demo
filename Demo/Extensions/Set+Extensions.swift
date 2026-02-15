
import Foundation

/// Extensions providing convenience methods for `Set`.
extension Set {
    /// Inserts or removes a member based on a boolean flag.
    ///
    /// Useful for two-way bindings with `DisclosureGroup` or similar controls
    /// where the expanded state maps to set membership.
    ///
    /// - Parameters:
    ///   - member: The element to insert or remove.
    ///   - insert: If `true`, inserts the member; if `false`, removes it.
    mutating func toggle(_ member: Element, insert: Bool) {
        if insert {
            self.insert(member)
        } else {
            self.remove(member)
        }
    }
}
