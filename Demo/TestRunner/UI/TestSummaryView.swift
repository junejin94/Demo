
import SwiftUI

/// A collapsible dashboard view summarizing the current test run.
///
/// Displays passed/failed counts, total duration, and a progress gauge.
/// Automatically hides itself when `isSearching` is true in the environment.
struct TestSummaryView: View {
    @Environment(\.isSearching) private var isSearching
    @State private var shouldShow = true

    /// The number of tests passed so far.
    let passedCount: Int

    /// The number of tests failed so far.
    let failedCount: Int

    /// The number of tests executed so far.
    let totalRun: Int

    /// The total elapsed time of the run.
    let totalDuration: TimeInterval

    /// The total number of tests in the suite.
    let totalTestCount: Int

    var body: some View {
        Section {
            if shouldShow {
                VStack(spacing: 12) {
                    HStack {
                        Label("\(passedCount)", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.subheadline.bold())

                        Spacer()

                        if failedCount > 0 {
                            Label("\(failedCount)", systemImage: "xmark.circle.fill")
                                .foregroundStyle(.red)
                                .font(.subheadline.bold())

                            Spacer()
                        }

                        Label(
                            totalDuration > 0
                            ? String(format: "%.2fs", totalDuration)
                            : "0.00s",
                            systemImage: "clock"
                        )
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                        .font(.subheadline)
                    }

                    let total = max(totalTestCount, 1)

                    // Custom split progress bar
                    TestProgressBar(
                        passedCount: passedCount,
                        failedCount: failedCount,
                        totalTestCount: total
                    )

                    Text("\(totalRun)/\(totalTestCount)")
                        .font(.caption2)
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                }
                .padding(.vertical, 4)
            }

        }
        .onAppear {
            shouldShow = !isSearching
        }
        .onChange(of: isSearching) { _, newValue in
            withAnimation(.easeOut(duration: 0.4)) {
                shouldShow = !newValue
            }
        }
    }
}
