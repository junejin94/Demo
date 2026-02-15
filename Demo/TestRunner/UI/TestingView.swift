import SwiftUI
import CorePresentation
import CoreSwift
import UniformTypeIdentifiers

/// The main interface for running tests and viewing results.
///
/// This view presents a hierarchical list of test suites, allows filtering by name,
/// and provides controls for running, stopping, and exporting test results.
/// It observes the `TestRunner` state to update the UI in real-time.
@MainActor
struct TestingView: View {
    @EnvironmentObject var bannerService: DefaultBannerService

    @State private var runner = TestRunner()
    @State private var suites: [TestSuite] = []
    @State private var expandedSuites: Set<String> = ["banner"]
    @State private var expandedCategories: Set<String> = []
    @State private var searchText = ""

    // Run lifecycle
    @State private var runTask: Task<Void, Never>?
    @State private var showStoppedLabel = false
    @State private var runDidFinish = false
    @State private var hasStartedExecution = false

    var body: some View {
        NavigationStack {
            testList
                .listStyle(.insetGrouped)
                .searchable(
                    text: $searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Search tests"
                )
                .onChange(of: searchText) { _, newValue in
                    if !newValue.isEmpty {
                        expandedSuites = Set(suites.map(\.id))
                        expandedCategories = Set(suites.flatMap(\.categories).map(\.id))
                    }
                }
                .navigationTitle("Testing")
                .toolbar {
                    runToolbarItem
                    ToolbarSpacer(.fixed, placement: .topBarTrailing)
                    exportToolbarItem
                }
                .task {
                    if suites.isEmpty {
                        suites = [BannerTestSuite.create(service: bannerService)]
                    }
                }
        }
    }

    // MARK: - List

    private var testList: some View {
        List {
            summarySection

            ForEach(filteredSuites) { suite in
                Section {
                    suiteRow(suite)
                }
            }
        }
    }

    // MARK: - Toolbar

    private var runToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if runner.isRunning {
                Button {
                    bannerService.dismissAll()
                    runner.stop()
                    runTask?.cancel()
                    showStoppedLabel = true
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
            } else {
                Button {
                    bannerService.dismissAll()
                    startFreshRun()
                } label: {
                    Label("Run", systemImage: "play.fill")
                }
                .disabled(bannerService.currentBanner != nil)
            }
        }
    }

    private var exportToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Section("Export") {
                    ShareLink(
                        item: XMLTestExport(result: prepareExport()),
                        preview: SharePreview(
                            "Test Results (XML)",
                            image: Image(systemName: "doc.text.fill")
                        )
                    ) {
                        Label("Export XML", systemImage: "doc.text")
                    }
                    ShareLink(
                        item: JSONTestExport(result: prepareExport()),
                        preview: SharePreview(
                            "Test Results (JSON)",
                            image: Image(systemName: "curlybraces")
                        )
                    ) {
                        Label("Export JSON", systemImage: "curlybraces")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
            }
            .opacity(runner.canExport && !runner.isRunning ? 1 : 0.4)
            .disabled(!runner.canExport || runner.isRunning)
        }
    }

    // MARK: - Status Text

    private var statusSubtitle: String {
        let total = totalTestCount

        if runner.isRunning {
            var parts = ["Running… \(runner.totalRun)/\(total)"]
            if runner.passedCount > 0 { parts.append("✓ \(runner.passedCount)") }
            if runner.failedCount > 0 { parts.append("✗ \(runner.failedCount)") }
            return parts.joined(separator: " · ")
        }

        if showStoppedLabel {
            var parts = ["Stopped \(runner.totalRun)/\(total)"]
            if runner.passedCount > 0 { parts.append("✓ \(runner.passedCount)") }
            if runner.failedCount > 0 { parts.append("✗ \(runner.failedCount)") }
            if runner.totalDuration > 0 {
                parts.append(String(format: "%.2fs", runner.totalDuration))
            }
            return parts.joined(separator: " · ")
        }

        if runDidFinish && runner.totalRun > 0 {
            var parts = ["Finished \(runner.totalRun)/\(total)"]
            if runner.passedCount > 0 { parts.append("✓ \(runner.passedCount)") }
            if runner.failedCount > 0 { parts.append("✗ \(runner.failedCount)") }
            if runner.totalDuration > 0 {
                parts.append(String(format: "%.2fs", runner.totalDuration))
            }
            return parts.joined(separator: " · ")
        }

        return "\(total) tests"
    }

    // MARK: - Run Lifecycle

    private func startFreshRun() {
        runTask?.cancel()
        hasStartedExecution = true
        runner.reset()
        runDidFinish = false
        showStoppedLabel = false

        runTask = Task {
            await runner.runAll(suites)
            if !showStoppedLabel {
                runDidFinish = true
                exportResults()
            }
        }
    }

    private func exportResults() {
        let result = prepareExport()

        do {
            let xmlURL = try ResultExporter.exportToTemp(result: result, format: .xml)
            let jsonURL = try ResultExporter.exportToTemp(result: result, format: .json)

            CoreLogger.shared.info("""
                Result
                XML  : \(xmlURL.path)
                JSON : \(jsonURL.path)
                """, category: .testing)
        } catch {
            CoreLogger.shared.error("Export failed: \(error.localizedDescription)", category: .testing)
        }
    }

    // MARK: - Filtering

    private var filteredSuites: [TestSuite] {
        if searchText.isEmpty { return suites }

        return suites.compactMap { suite in
            let filteredCategories = suite.categories.compactMap { category -> TestCategory? in
                let matchingTests = category.tests.filter {
                    $0.name.localizedCaseInsensitiveContains(searchText)
                }
                guard !matchingTests.isEmpty else { return nil }
                return TestCategory(id: category.id, name: category.name, tests: matchingTests)
            }
            guard !filteredCategories.isEmpty else { return nil }
            return TestSuite(id: suite.id, name: suite.name, categories: filteredCategories)
        }
    }

    // MARK: - Summary

    private var showsSummary: Bool {
        hasStartedExecution
    }

    @ViewBuilder
    private var summarySection: some View {
        if showsSummary {
            TestSummaryView(
                passedCount: runner.passedCount,
                failedCount: runner.failedCount,
                totalRun: runner.totalRun,
                totalDuration: runner.totalDuration,
                totalTestCount: totalTestCount
            )
        }
    }

    private var totalTestCount: Int {
        suites.reduce(0) { $0 + $1.categories.reduce(0) { $0 + $1.tests.count } }
    }

    private func suiteRow(_ suite: TestSuite) -> some View {
        let actualTotal = suite.categories.reduce(0) { $0 + $1.tests.count }
        let passed = suite.categories.flatMap { $0.tests }
            .filter { runner.results[$0.id]?.isPassed == true }.count
        let failed = suite.categories.flatMap { $0.tests }
            .filter { runner.results[$0.id]?.isFailed == true }.count

        let badgeStatus: CountBadge.Status = {
            if failed > 0 { return .failure }
            if passed == actualTotal && actualTotal > 0 { return .success }
            return .neutral
        }()

        return DisclosureGroup(
            isExpanded: Binding(
                get: { expandedSuites.contains(suite.id) },
                set: { expandedSuites.toggle(suite.id, insert: $0) }
            )
        ) {
            ForEach(suite.categories) { category in
                categoryRow(category)
            }
        } label: {
            HStack {
                Text(suite.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                CountBadge(
                    value: passed,
                    total: actualTotal,
                    status: badgeStatus,
                    font: .caption.bold(),
                    horizontalPadding: 8,
                    verticalPadding: 4
                )
            }
            .contentShape(Rectangle())
        }
        .contextMenu {
            if !runner.isRunning {
                exportMenuItems(for: suite)
            }
        }
    }

    private func categoryRow(_ category: TestCategory) -> some View {
        let passCount = category.tests.filter { runner.results[$0.id]?.isPassed == true }.count
        let failCount = category.tests.filter { runner.results[$0.id]?.isFailed == true }.count
        let totalCount = category.tests.count

        let badgeStatus: CountBadge.Status = {
            if failCount > 0 { return .failure }
            if passCount == totalCount && totalCount > 0 { return .success }
            return .neutral
        }()

        return DisclosureGroup(
            isExpanded: Binding(
                get: { expandedCategories.contains(category.id) },
                set: { expandedCategories.toggle(category.id, insert: $0) }
            )
        ) {
            ForEach(category.tests, id: \.id) { test in
                testRow(test)
            }
        } label: {
            HStack {
                Text(category.name)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Spacer()
                CountBadge(value: passCount, total: totalCount, status: badgeStatus)
            }
            .contentShape(Rectangle())
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 20))
        .contextMenu {
            if !runner.isRunning {
                exportMenuItems(for: category)
            }
        }
    }

    private func testRow(_ test: any TestCase) -> some View {
        let result = runner.results[test.id] ?? .notRun

        return Button {
            Task { await runner.runTest(test) }
        } label: {
            HStack {
                Text(test.name)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                if let duration = runner.durations[test.id] {
                    Text(String(format: "%.2fs", duration))
                        .font(.caption)
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                        .monospacedDigit()
                }
                Spacer()
                StatusIcon(state: StatusIcon.State(from: result))
            }
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(top: 0, leading: 32, bottom: 0, trailing: 20))
        .disabled(runner.isRunning)
    }

    // MARK: - Export Helpers

    @ViewBuilder
    private func exportMenuItems(for suite: TestSuite) -> some View {
        if runner.canExport {
            ShareLink(item: XMLTestExport(result: prepareExport(suite: suite)),
                      preview: SharePreview("\(suite.name) Results (XML)", image: Image(systemName: "doc.text.fill"))) {
                Label("Export XML", systemImage: "doc.text")
            }

            ShareLink(item: JSONTestExport(result: prepareExport(suite: suite)),
                      preview: SharePreview("\(suite.name) Results (JSON)", image: Image(systemName: "curlybraces"))) {
                Label("Export JSON", systemImage: "curlybraces")
            }
        }
    }

    @ViewBuilder
    private func exportMenuItems(for category: TestCategory) -> some View {
        if runner.canExport {
            ShareLink(item: XMLTestExport(result: prepareExport(category: category)),
                      preview: SharePreview("\(category.name) Results (XML)", image: Image(systemName: "doc.text.fill"))) {
                Label("Export XML", systemImage: "doc.text")
            }

            ShareLink(item: JSONTestExport(result: prepareExport(category: category)),
                      preview: SharePreview("\(category.name) Results (JSON)", image: Image(systemName: "curlybraces"))) {
                Label("Export JSON", systemImage: "curlybraces")
            }
        }
    }

    private func prepareExport(suite: TestSuite? = nil, category: TestCategory? = nil) -> TestSuiteResult {
        let suitesToExport: [TestSuite]

        if let suite {
            suitesToExport = [suite]
        } else if let category,
                  let parentSuite = suites.first(where: { $0.categories.contains { $0.id == category.id } }) {
            suitesToExport = [TestSuite(id: parentSuite.id, name: parentSuite.name, categories: [category])]
        } else {
            suitesToExport = suites
        }

        let categoryResults = suitesToExport.flatMap { suite in
            suite.categories.map { category in
                TestSuiteResult.CategoryResult(name: category.name,
                                               tests: category.tests.map { test in
                    TestSuiteResult.TestCaseResult(id: test.id,
                                                   name: test.name,
                                                   result: runner.results[test.id] ?? .notRun)
                })
            }
        }

        return TestSuiteResult(suiteName: suite?.name ?? category?.name ?? "All Suites",
                               categories: categoryResults)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TestingView()
            .environmentObject(DefaultBannerService())
    }
}

