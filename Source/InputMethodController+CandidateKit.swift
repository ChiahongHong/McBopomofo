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
import Cocoa
import InputMethodKit

private let kMinKeyLabelSize: CGFloat = 10

private struct CandidateTextAnchorContext {
    let lineHeightRect: NSRect
    let usesVerticalText: Bool
    let compositionLeadingX: CGFloat
    let compositionTrailingXProvider: () -> CGFloat
}

extension CandidateController {
    static let horizontal = HorizontalCandidateController()
    static let vertical = VerticalCandidateController()
}

extension McBopomofoInputMethodController {
    func showModern(candidateWindowWith state: InputState, client: Any!) {
        let usesVerticalCandidateWindow: Bool = {
            var useVerticalMode = false
            var candidates: [InputState.Candidate] = []
            switch state {
            case let state as InputState.ChoosingCandidate:
                useVerticalMode = state.useVerticalMode
                candidates = state.candidates
            case let state as InputState.AssociatedPhrasesPlain:
                useVerticalMode = state.useVerticalMode
                candidates = state.candidates
            case let state as InputState.AssociatedPhrases:
                useVerticalMode = state.useVerticalMode
                candidates = state.candidates
            case is InputState.SelectingFeature,
                is InputState.SelectingDateMacro,
                is InputState.SelectingDictionary,
                is InputState.ShowingCharInfo,
                is InputState.Number,
                is InputState.IcuTransform:
                return true
            default:
                break
            }

            if useVerticalMode == true {
                return true
            }
            // If there is a candidate which is too long, we use the vertical
            // candidate list window automatically.
            return candidates.contains { $0.displayText.count > 8 }
        }()

        gCurrentCandidateController?.clearDelegate()
        gCurrentCandidateController?.visible = false

        let candidateController: CandidateController
        if usesVerticalCandidateWindow {
            candidateController = .vertical
        } else if Preferences.useHorizontalCandidateList {
            candidateController = .horizontal
        } else {
            candidateController = .vertical
        }
        gCurrentCandidateController = candidateController
        currentClient = client
        let usesHorizontalCandidateWindow =
            candidateController === CandidateController.horizontal

        candidateController.tooltip =
            switch state {
            case let state as InputState.SelectingDictionary:
                String(format: NSLocalizedString("Look up %@", comment: ""), state.selectedPhrase)
            case let state as InputState.AssociatedPhrases:
                String(format: NSLocalizedString("%@…", comment: ""), state.prefixValue)
            case let state as InputState.CustomMenu:
                state.title
            default:
                ""
            }

        // set the attributes for the candidate panel (which uses NSAttributedString)
        let textSize = Preferences.candidateListTextSize
        let keyLabelSize = max(textSize / 2, kMinKeyLabelSize)

        func font(name: String?, size: CGFloat) -> NSFont {
            if let name = name {
                return NSFont(name: name, size: size) ?? NSFont.systemFont(ofSize: size)
            }
            return NSFont.systemFont(ofSize: size)
        }

        let candidateKeys: String = {
            let preferredKeys = Preferences.candidateKeys
            do {
                try Preferences.validate(candidateKeys: preferredKeys)
                _ = try CandidateConfiguration(
                    indexLabels: preferredKeys,
                    pageSize: preferredKeys.count
                )
                return preferredKeys
            } catch {
                return Preferences.defaultCandidateKeys
            }
        }()
        let keyLabels = Array(candidateKeys)
        let isAutoAssociatedPhrase = (state as? InputState.AssociatedPhrases)?.autoTriggered == true
        let usesShiftedKeys = state is InputState.AssociatedPhrasesPlain
            || state is InputState.Number || state is InputState.IcuTransform

        var configuration = candidateController.configuration
        configuration.orientation = usesHorizontalCandidateWindow ? .horizontal : .vertical
        configuration.allowsExpansion = Preferences.candidateWindowAllowsExpansion
        configuration.candidateFontSize = textSize
        configuration.indexLabels = isAutoAssociatedPhrase ? "" : candidateKeys
        configuration.showsKeyLabelsAsDetails = usesShiftedKeys
        configuration.pageSize = keyLabels.count
        do {
            try candidateController.apply(configuration: configuration)
        } catch {
            assertionFailure("Validated candidate configuration was rejected: \(error)")
            return
        }

        candidateController.synchronizeTheme(
            clientAppearance: NSApp.effectiveAppearance,
            clientBundleIdentifier: NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        )
        candidateController.keyLabelFont = font(
            name: Preferences.candidateKeyLabelFontName, size: keyLabelSize)
        candidateController.candidateFont = font(
            name: Preferences.candidateTextFontName, size: textSize)

        candidateController.keyLabels = isAutoAssociatedPhrase ? [] : keyLabels.map {
            CandidateKeyLabel(key: String($0), displayedText: usesShiftedKeys ? "⇧ " + String($0) : String($0))
        }

        candidateController.delegate = modernCandidateDelegate
        candidateController.reloadData()

        guard let textClient = client as? IMKTextInput else {
            return
        }
        let anchorContext = candidateTextAnchorContext(for: state, client: textClient)

        if anchorContext.usesVerticalText {
            candidateController.set(
                windowTopLeftPoint: NSMakePoint(
                    anchorContext.lineHeightRect.maxX + 4.0,
                    anchorContext.lineHeightRect.origin.y - 4.0),
                bottomOutOfScreenAdjustmentHeight: anchorContext.lineHeightRect.size.height + 4.0)
            candidateController.visible = true
        } else {
            candidateController.show(
                near: anchorContext.lineHeightRect,
                compositionLeadingX: anchorContext.compositionLeadingX,
                compositionTrailingXProvider: anchorContext.compositionTrailingXProvider
            )
        }
    }

    private func candidateTextAnchorContext(
        for state: InputState,
        client: IMKTextInput
    ) -> CandidateTextAnchorContext {
        var cursor = 0
        var composingBuffer: String?
        if let state = state as? InputState.NotEmpty {
            composingBuffer = state.composingBuffer
            let bufferLength = (state.composingBuffer as NSString).length
            cursor = min(Int(state.cursorIndex), bufferLength)
            if cursor == bufferLength && cursor != 0 {
                cursor -= 1
            }
        }

        var lineHeightRect = NSRect.zero
        var usesVerticalText = false
        while cursor >= 0 {
            var measuredRect = NSRect.zero
            let attributes = client.attributes(
                forCharacterIndex: cursor,
                lineHeightRectangle: &measuredRect
            )
            if measuredRect != .zero {
                lineHeightRect = measuredRect
                usesVerticalText =
                    (attributes?["IMKTextOrientation"] as? NSNumber)?.intValue == 0
                break
            }
            cursor -= 1
        }
        if lineHeightRect == .zero {
            lineHeightRect = NSMakeRect(0.0, 0.0, 16.0, 16.0)
        }

        var compositionLeadingX = lineHeightRect.minX
        var compositionTrailingX = lineHeightRect.maxX
        var compositionTrailingIndex: Int?
        if let composingBuffer {
            let bufferLength = (composingBuffer as NSString).length
            if bufferLength > 0 {
                if let leadingFrame = candidateTextFrame(at: 0, client: client) {
                    compositionLeadingX = leadingFrame.minX
                }
                compositionTrailingIndex = bufferLength - 1
                if let trailingFrame = candidateTextFrame(
                    at: bufferLength - 1,
                    client: client
                ) {
                    compositionTrailingX = trailingFrame.maxX
                }
            }
        }

        let trailingXProvider = { [weak self] in
            guard let self,
                let compositionTrailingIndex,
                let currentClient = currentClient as? IMKTextInput,
                let trailingFrame = candidateTextFrame(
                    at: compositionTrailingIndex,
                    client: currentClient
                )
            else {
                return compositionTrailingX
            }
            return trailingFrame.maxX
        }
        return CandidateTextAnchorContext(
            lineHeightRect: lineHeightRect,
            usesVerticalText: usesVerticalText,
            compositionLeadingX: compositionLeadingX,
            compositionTrailingXProvider: trailingXProvider
        )
    }

    private func candidateTextFrame(at index: Int, client: IMKTextInput) -> NSRect? {
        var frame = NSRect.zero
        client.attributes(forCharacterIndex: index, lineHeightRectangle: &frame)
        return frame == .zero ? nil : frame
    }

}

@MainActor
final class ModernCandidateDelegate: NSObject, CandidateControllerDelegate {
    private weak var owner: McBopomofoInputMethodController?

    init(owner: McBopomofoInputMethodController) {
        self.owner = owner
        super.init()
    }

    func candidateCountForController(_ controller: CandidateController) -> UInt {
        UInt((owner?.state as? CandidateProvider)?.candidateCount ?? 0)
    }

    func candidateController(_ controller: CandidateController, candidateAtIndex index: UInt) -> String {
        (owner?.state as? CandidateProvider)?.candidate(at: Int(index)) ?? ""
    }

    func candidateController(_ controller: CandidateController, readingAtIndex index: UInt) -> String? {
        // Action hints occupy the detail area; readings remain available to VoiceOver.
        (owner?.state as? InputState.AssociatedPhrases)?.autoTriggered == true ? "⇧ ⏎" : nil
    }

    func candidateController(_ controller: CandidateController, accessibilityReadingAtIndex index: UInt) -> String? {
        (owner?.state as? CandidateProvider)?.reading(at: Int(index))
    }

    func candidateController(_ controller: CandidateController, requestExplanationFor candidate: String, reading: String) -> String? {
        owner?.candidateExplanation(for: candidate, reading: reading)
    }

    func candidateController(_ controller: CandidateController, didSelectCandidateAtIndex index: UInt) {
        owner?.selectCandidate(at: index)
    }
}
