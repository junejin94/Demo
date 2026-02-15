
import Foundation

/// Errors that can occur during the export of test results.
enum ExportError: Error, LocalizedError {
    /// The write operation to disk failed.
    case writeFailed(Error)
    
    /// Import functionality is not supported for this format.
    case importNotSupported
    
    var errorDescription: String? {
        switch self {
        case .writeFailed(let error):
            return "Failed to write export: \(error.localizedDescription)"
        case .importNotSupported:
            return "Importing test results is not supported"
        }
    }
}
