// Copyright (c) 2026 and onwards The McBopomofo Authors.
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

import CandidateKit
import CandidateUI
import Cocoa

@objc enum CandidateWindowNavigation: Int {
    case rowStart
    case rowEnd
    case previousCandidate
    case nextCandidate
}

// Both renderers expose the same keyboard contract without sharing Objective-C class names.
@MainActor
@objc protocol CandidateWindowController: AnyObject {
    var selectedCandidateIndex: UInt { get set }
    var visible: Bool { get set }
    var isHorizontal: Bool { get }
    var usesModernStyle: Bool { get }
    var selectionKeys: [String] { get }
    func clearDelegate()
    func showNextPage() -> Bool
    func showPreviousPage() -> Bool
    func highlightNextCandidate() -> Bool
    func highlightPreviousCandidate() -> Bool
    func candidateIndexAtKeyLabelIndex(_ index: UInt) -> UInt
    @objc optional func navigateCandidates(_ navigation: CandidateWindowNavigation) -> Bool
}

extension CandidateUI.CandidateController: CandidateWindowController {
    @objc var isHorizontal: Bool { self is CandidateUI.HorizontalCandidateController }
    @objc var usesModernStyle: Bool { false }
    @objc var selectionKeys: [String] { keyLabels.map(\.key) }
    @objc func clearDelegate() { delegate = nil }
}

extension CandidateKit.CandidateController: CandidateWindowController {
    @objc var isHorizontal: Bool { configuration.orientation == .horizontal }
    @objc var usesModernStyle: Bool { true }
    @objc var selectionKeys: [String] { keyLabels.map(\.key) }
    @objc func clearDelegate() { delegate = nil }
    @objc func navigateCandidates(_ navigation: CandidateWindowNavigation) -> Bool {
        switch navigation {
        case .rowStart: navigate(.home)
        case .rowEnd: navigate(.end)
        case .previousCandidate: navigate(.itemBackward, wrapping: true)
        case .nextCandidate: navigate(.itemForward, wrapping: true)
        }
    }
}
