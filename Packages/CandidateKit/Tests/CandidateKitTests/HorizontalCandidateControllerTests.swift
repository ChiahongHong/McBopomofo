import AppKit
import XCTest

@testable import CandidateKit

@MainActor
final class HorizontalCandidateControllerTests: XCTestCase {
    private let screenshotCandidates = [
        "小麥注音", "注音", "因", "音", "陰", "姻", "殷", "茵", "慇",
        "氤", "痕", "暗", "壅", "湮", "惜", "裡", "絪", "袒",
        "闇", "駰", "銦", "蔭", "諳", "垔", "馨", "洇", "湮", "愔", "禋", "絪",
    ].map { Candidate(displayString: $0) }

    func testDefaultMetricsMatchSpecification() {
        let metrics = CandidateMetrics(
            requestedCandidateFont: .systemFont(ofSize: 16),
            requestedIndexFont: .systemFont(ofSize: 8)
        )

        XCTAssertEqual(metrics.itemHeight, 28)
        XCTAssertEqual(metrics.leadingPadding, 4)
        XCTAssertEqual(metrics.indexSlotWidth, 11)
        XCTAssertEqual(metrics.indexCandidateGap, 2)
        XCTAssertEqual(metrics.candidateDetailGap, 11)
        XCTAssertEqual(metrics.trailingPadding, 9)
        XCTAssertEqual(metrics.baseCellWidth, 42)
        XCTAssertEqual(metrics.detailFont.pointSize, 12)
        XCTAssertEqual(metrics.cornerRadius, 6)
        XCTAssertEqual(metrics.dragActivationDistance, 3)
    }

    func testEmptyIndexLabelsRemoveTheReservedColumn() throws {
        let configuration = try CandidateConfiguration(indexLabels: "")
        let candidates = (0..<9).map { _ in Candidate(displayString: "永") }
        let pages = HorizontalCandidateLayoutEngine.packedPages(
            candidates: candidates,
            configuration: configuration,
            metrics: defaultMetrics
        )

        XCTAssertEqual(defaultMetrics.baseCellWidth(showsIndexColumn: false), 34)
        XCTAssertEqual(pages.count, 1)
        XCTAssertEqual(pages[0].items.map(\.frame.width), Array(repeating: 34, count: 9))
    }

    func testPagedLayoutDistributesOnlyFirstPageAndKeepsFollowingPagesNatural() throws {
        var configuration = CandidateConfiguration.default
        configuration.allowsExpansion = false
        let pages = HorizontalCandidateLayoutEngine.packedPages(
            candidates: screenshotCandidates,
            configuration: configuration,
            metrics: defaultMetrics
        )
        XCTAssertGreaterThan(pages.count, 2)

        let firstPage = pages[0]
        let firstLayout = HorizontalCandidateLayoutEngine.pagedLayout(
            pages: pages,
            pageIndex: 0,
            keyLabels: defaultKeyLabels,
            configuration: configuration,
            metrics: defaultMetrics
        )
        let firstNaturalWidth = try XCTUnwrap(firstPage.items.last).frame.maxX
        let distributedWidth = (firstLayout.windowSize.width - firstNaturalWidth)
            / CGFloat(firstPage.items.count)

        XCTAssertEqual(firstLayout.windowSize.width, 384)
        XCTAssertEqual(try XCTUnwrap(firstLayout.items.last).frame.maxX, 384, accuracy: 0.000_001)
        for (index, pair) in zip(firstPage.items, firstLayout.items).enumerated() {
            XCTAssertEqual(
                pair.1.frame.width,
                pair.0.frame.width + distributedWidth,
                accuracy: 0.000_001
            )
            XCTAssertEqual(
                pair.1.frame.minX,
                pair.0.frame.minX + CGFloat(index) * distributedWidth,
                accuracy: 0.000_001
            )
        }

        let middlePage = pages[1]
        let middleLayout = HorizontalCandidateLayoutEngine.pagedLayout(
            pages: pages,
            pageIndex: 1,
            keyLabels: defaultKeyLabels,
            configuration: configuration,
            metrics: defaultMetrics
        )
        XCTAssertEqual(middleLayout.windowSize.width, 384)
        XCTAssertEqual(middleLayout.items.map(\.frame), middlePage.items.map(\.frame))

        let finalPageIndex = pages.index(before: pages.endIndex)
        let finalPage = pages[finalPageIndex]
        let finalLayout = HorizontalCandidateLayoutEngine.pagedLayout(
            pages: pages,
            pageIndex: finalPageIndex,
            keyLabels: defaultKeyLabels,
            configuration: configuration,
            metrics: defaultMetrics
        )

        XCTAssertEqual(finalLayout.items.map(\.frame), finalPage.items.map(\.frame))
        XCTAssertEqual(
            finalLayout.windowSize.width,
            384
        )
        XCTAssertLessThan(
            try XCTUnwrap(finalLayout.items.last).frame.maxX,
            finalLayout.windowSize.width
        )
    }

    func testOneOversizedCandidateAlwaysOccupiesOnePage() {
        let candidates = [Candidate(displayString: String(repeating: "永", count: 100))]
        let pages = HorizontalCandidateLayoutEngine.packedPages(
            candidates: candidates,
            configuration: .default,
            metrics: defaultMetrics
        )

        XCTAssertEqual(pages.count, 1)
        XCTAssertEqual(pages[0].items.count, 1)
        XCTAssertEqual(pages[0].items[0].frame.width, 384)
    }

    func testConfigurationValidation() throws {
        XCTAssertThrowsError(try CandidateConfiguration(pageSize: 0))
        XCTAssertNoThrow(try CandidateConfiguration(pageSize: 15))
        XCTAssertThrowsError(try CandidateConfiguration(pageSize: 16))
        XCTAssertThrowsError(try CandidateConfiguration(indexLabels: "１２３"))
        XCTAssertNoThrow(try CandidateConfiguration(indexLabels: ""))
        XCTAssertNoThrow(try CandidateConfiguration(indexLabels: "1 1"))

        var mutatedConfiguration = CandidateConfiguration.default
        mutatedConfiguration.pageSize = 0
        XCTAssertThrowsError(try mutatedConfiguration.validate())
    }

    func testPagedDownPreservesShortcutSlotAcrossVariableWidthPages() {
        let controller = HorizontalCandidateController(expandable: false)
        controller.replaceCandidates(screenshotCandidates, initialSelectedIndex: 6)
        controller.visible = true
        defer { controller.visible = false }

        XCTAssertEqual(controller.candidates[controller.selectionIndex].displayString, "殷")
        XCTAssertTrue(controller.navigate(.down))
        XCTAssertEqual(controller.currentPageIndex, 1)
        XCTAssertEqual(controller.selectionIndex, 13)
        XCTAssertEqual(controller.candidates[controller.selectionIndex].displayString, "湮")
        XCTAssertEqual(controller.currentLayout.item(for: 13)?.indexText, "7")

        XCTAssertTrue(controller.navigate(.up))
        XCTAssertEqual(controller.currentPageIndex, 0)
        XCTAssertEqual(controller.selectionIndex, 6)
    }

    private var defaultMetrics: CandidateMetrics {
        CandidateMetrics(
            requestedCandidateFont: .systemFont(ofSize: 16),
            requestedIndexFont: .systemFont(ofSize: 8)
        )
    }

    private var defaultKeyLabels: [CandidateKeyLabel] {
        "1234567890".map {
            CandidateKeyLabel(key: String($0), displayedText: String($0))
        }
    }

}
