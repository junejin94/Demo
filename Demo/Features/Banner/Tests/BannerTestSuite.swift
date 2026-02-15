import Foundation
import CorePresentation

@MainActor
struct BannerTestSuite {
    static func create(service: any Banner.Service) -> TestSuite {
        TestSuite(
            id: "banner",
            name: "Banner Feature Tests",
            categories: [
                IntegrationTests.category(service: service),
                PriorityTests.category(service: service),
                EdgeCaseTests.category(service: service),
                DismissalTests.category(service: service),
                QueueTests.category(service: service),
                OverflowTests.category(service: service),
                DuplicateTests.category(service: service),
                ActionTests.category(service: service),
                CallbackTests.category(service: service),
                ServiceMethodTests.category(service: service),
                RapidTests.category(service: service),
                StyleTests.category(service: service),
                BackgroundColorTests.category(service: service),
                ConfigurationTests.category(service: service)
            ]
        )
    }
}
