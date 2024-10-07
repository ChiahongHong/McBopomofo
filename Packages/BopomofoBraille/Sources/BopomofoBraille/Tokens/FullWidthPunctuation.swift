// Copyright (c) 2022 and onwards The McBopomofo Authors.
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

import Foundation

/// Represents the full-width punctuations
public enum FullWidthPunctuation: String, CaseIterable {
    init?(braille: String) {
        let aCase = FullWidthPunctuation.allCases.first { aCase in
            aCase.braille == braille
        }
        if let aCase {
            self = aCase
        } else {
            return nil
        }
    }

    var bopomofo: String {
        return rawValue
    }

    var braille: String {
        switch self {
        case .period:
            "⠤"
        case .dot:
            "⠤"
        case .comma:
            "⠆"
        case .semicolon:
            "⠰"
        case .ideographicComma:
            "⠠"
        case .questionMark:
            "⠕"
        case .exclamationMark:
            "⠇"
        case .colon:
            "⠒⠒"
        case .personNameMark:
            "⠰⠰"
        case .slash:
            "⠐⠂"
        case .bookNameMark:
            "⠠⠤"
        case .ellipsis:
            "⠐⠐⠐"
        case .referenceMark:
            "⠈⠼"
        case .doubleRing:
            "⠪⠕"
        case .singleQuotationMarkLeft:
            "⠰⠤"
        case .singleQuotationMarkRight:
            "⠤⠆"
        case .doubleQuotationMarkLeft:
            "⠰⠤⠰⠤"
        case .doubleQuotationMarkRight:
            "⠤⠆⠤⠆"
        case .parenthesesLeft:
            "⠪"
        case .parenthesesRight:
            "⠕"
        case .bracketLeft:
            "⠯"
        case .bracketRight:
            "⠽"
        case .braceLeft:
            "⠦"
        case .braceRight:
            "⠴"
        }
    }

    var supposedToBeAtStart: Bool {
        switch self {
        case .singleQuotationMarkLeft:
            true
        case .doubleQuotationMarkLeft:
            true
        case .parenthesesLeft:
            true
        case .bracketLeft:
            true
        case .braceLeft:
            true
        default:
            false
        }

    }

    case period = "。"
    case dot = "·"
    case comma = "，"
    case semicolon = "；"
    case ideographicComma = "、"
    case questionMark = "？"
    case exclamationMark = "！"
    case colon = "："
    case personNameMark = "╴"
    case slash = "—"
    case bookNameMark = "﹏"
    case ellipsis = "…"
    case referenceMark = "※"
    case doubleRing = "◎"
    case singleQuotationMarkLeft = "「"
    case singleQuotationMarkRight = "」"
    case doubleQuotationMarkLeft = "『"
    case doubleQuotationMarkRight = "』"
    case parenthesesLeft = "（"
    case parenthesesRight = "）"
    case bracketLeft = "〔"
    case bracketRight = "〕"
    case braceLeft = "｛"
    case braceRight = "｝"
}
