//
//  Copyright 2019 Square Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit

extension NSObject {

    /// Returns a tuple consisting of the `description` and (optionally) a `hint` that VoiceOver will read for the object.
    func accessibilityDescription(context: AccessibilityHierarchyParser.Context?) -> (description: String, hint: String?) {
        let strings = Strings(locale: accessibilityLanguage)

        var accessibilityDescription =
            accessibilityLabelOverride(for: context) ??
        (hidesAccessibilityLabel(backDescriptor: strings.backDescriptor) ? "" :
                                                            accessibilityLabel ?? "" )

        var hintDescription = accessibilityHint?.nonEmpty()


        let numberFormatter = NumberFormatter()
        if let localeIdentifier = accessibilityLanguage {
            numberFormatter.locale = Locale(identifier: localeIdentifier)
        }

        let descriptionContainsContext: Bool
        if let context = context {
            switch context {
            case let .dataTableCell(row: row, column: column, width: width, height: height, isFirstInRow: isFirstInRow, rowHeaders: rowHeaders, columnHeaders: columnHeaders):
                let headersDescription = (rowHeaders + columnHeaders).map { header -> String in
                    switch (header.accessibilityLabel?.nonEmpty(), header.accessibilityValue?.nonEmpty()) {
                    case (nil, nil):
                        return ""
                    case let (.some(label), nil):
                        return "\(label). "
                    case let (nil, .some(value)):
                        return "\(value). "
                    case let (.some(label), .some(value)):
                        return "\(label): \(value). "
                    }
                }.reduce("", +)

                let trailingPeriod = accessibilityDescription.hasSuffix(".") ? "" : "."

                let showsHeight = (height > 1 && row != NSNotFound)
                let showsWidth = (width > 1 && column != NSNotFound)
                let showsRow = (isFirstInRow && row != NSNotFound)
                let showsColumn = (column != NSNotFound)

                accessibilityDescription =
                    headersDescription
                    + accessibilityDescription
                    + trailingPeriod
                    + (showsHeight ? " " + String(format: strings.dataTableRowSpanFormat, numberFormatter.string(from: .init(value: height))!) : "")
                    + (showsWidth ? " " + String(format: strings.dataTableColumnSpanFormat, numberFormatter.string(from: .init(value: width))!) : "")
                    + (showsRow ? " " + String(format: strings.dataTableRowFormat, numberFormatter.string(from: .init(value: row + 1))!) : "")
                    + (showsColumn ? " " + String(format: strings.dataTableColumnFormat, numberFormatter.string(from: .init(value: column + 1))!) : "")

                descriptionContainsContext = true

            case .series, .tab, .tabBarItem, .listStart, .listEnd, .landmarkStart, .landmarkEnd:
                descriptionContainsContext = false
            }

        } else {
            descriptionContainsContext = false
        }

        if let accessibilityValue = accessibilityValue?.nonEmpty(), !hidesAccessibilityValue(for: context) {
            if let existingDescription = accessibilityDescription.nonEmpty() {
                if descriptionContainsContext {
                    accessibilityDescription += " \(accessibilityValue)"
                } else {
                    accessibilityDescription = "\(existingDescription): \(accessibilityValue)"
                }
            } else {
                accessibilityDescription = accessibilityValue
            }
        }

        if accessibilityTraits.contains(.selected) {
            if let existingDescription = accessibilityDescription.nonEmpty() {
                accessibilityDescription = String(format: strings.selectedTraitFormat, existingDescription)
            } else {
                accessibilityDescription = strings.selectedTraitName
            }
        }

        var traitSpecifiers: [String] = []

        if accessibilityTraits.contains(.notEnabled) {
            traitSpecifiers.append(strings.notEnabledTraitName)
        }

        let hidesButtonTraitInContext = context?.hidesButtonTrait ?? false
        let hidesButtonTraitFromTraits = [UIAccessibilityTraits.keyboardKey, .switchButton, .tabBarItem, .backButton].contains(where: { accessibilityTraits.contains($0) })
        if accessibilityTraits.contains(.button) && !hidesButtonTraitFromTraits && !hidesButtonTraitInContext {
            traitSpecifiers.append(strings.buttonTraitName)
        }
        
        if accessibilityTraits.contains(.backButton) {
            traitSpecifiers.append(strings.backButtonTraitName)
        }

        if accessibilityTraits.contains(.switchButton) {
            if accessibilityTraits.contains(.button) {
                // An element can have the private switch button trait without being a UISwitch (for example, by passing
                // through the traits of a contained switch). In this case, VoiceOver will still read the "Switch
                // Button." trait, but only if the element's traits also include the `.button` trait.
                traitSpecifiers.append(strings.switchButtonTraitName)
            }

            switch accessibilityValue {
            case "1":
                traitSpecifiers.append(strings.switchButtonOnStateName)
            case "0":
                traitSpecifiers.append(strings.switchButtonOffStateName)
            case "2":
                traitSpecifiers.append(strings.switchButtonMixedStateName)
            default:
                // Prior to iOS 17 the then private trait would suppress any other accessibility values.
                // Once the trait became public in 17 values other than the above are announced with the trait specifiers.
                if #available(iOS 17.0, *), let accessibilityValue {
                        traitSpecifiers.append(accessibilityValue)
                    }
            }
        }

        let showsTabTraitInContext = context?.showsTabTrait ?? false
        if accessibilityTraits.contains(.tabBarItem) || showsTabTraitInContext {
            traitSpecifiers.append(strings.tabTraitName)
        }

        if accessibilityTraits.contains(.textEntry) {
            if accessibilityTraits.contains(.scrollable) {
                // This is a UITextView/TextEditor
            } else {
                // This is a UITextField/TextField
            }

            traitSpecifiers.append(strings.textEntryTraitName)

            if accessibilityTraits.contains(.isEditing) {
                traitSpecifiers.append(strings.isEditingTraitName)
            }
        }

        if accessibilityTraits.contains(.header) {
            traitSpecifiers.append(strings.headerTraitName)
        }

        if accessibilityTraits.contains(.link) {
            traitSpecifiers.append(strings.linkTraitName)
        }

        if accessibilityTraits.contains(.adjustable) {
            traitSpecifiers.append(strings.adjustableTraitName)
        }

        if accessibilityTraits.contains(.image) {
            traitSpecifiers.append(strings.imageTraitName)
        }

        if accessibilityTraits.contains(.searchField) {
            traitSpecifiers.append(strings.searchFieldTraitName)
        }

        // If the description is empty, use the hint as the description.
        if accessibilityDescription.isEmpty {
            accessibilityDescription = hintDescription ?? ""
            hintDescription = nil
        }

        // Add trait specifiers to description.
        if !traitSpecifiers.isEmpty {
            if let existingDescription = accessibilityDescription.nonEmpty() {
                let trailingPeriod = existingDescription.hasSuffix(".") ? "" : "."
                accessibilityDescription = "\(existingDescription)\(trailingPeriod) \(traitSpecifiers.joined(separator: " "))"
            } else {
                accessibilityDescription = traitSpecifiers.joined(separator: " ")
            }
        }

        if let context = context {
            switch context {
            case let .series(index: index, count: count),
                 let .tabBarItem(index: index, count: count, item: _),
                 let .tab(index: index, count: count):
                accessibilityDescription = String(format:
                    strings.seriesContextFormat,
                    accessibilityDescription,
                    numberFormatter.string(from: .init(value: index))!,
                    numberFormatter.string(from: .init(value: count))!
                )

            case .listStart:
                let trailingPeriod = accessibilityDescription.hasSuffix(".") ? "" : "."
                accessibilityDescription = String(format:
                    "%@%@ %@",
                    accessibilityDescription,
                    trailingPeriod,
                    strings.listStartContext
                )

            case .listEnd:
                let trailingPeriod = accessibilityDescription.hasSuffix(".") ? "" : "."
                accessibilityDescription = String(format:
                    "%@%@ %@",
                    accessibilityDescription,
                    trailingPeriod,
                    strings.listEndContext
                )

            case .landmarkStart:
                let trailingPeriod = accessibilityDescription.hasSuffix(".") ? "" : "."
                accessibilityDescription = String(format:
                    "%@%@ %@",
                    accessibilityDescription,
                    trailingPeriod,
                    strings.landmarkStartContext
                )

            case .landmarkEnd:
                let trailingPeriod = accessibilityDescription.hasSuffix(".") ? "" : "."
                accessibilityDescription = String(format:
                    "%@%@ %@",
                    accessibilityDescription,
                    trailingPeriod,
                    strings.landmarkEndContext
                )

            case .dataTableCell:
                break
            }
        }

        if accessibilityTraits.contains(.switchButton) && !accessibilityTraits.contains(.notEnabled) {
            if let existingHintDescription = hintDescription?.nonEmpty()?.strippingTrailingPeriod() {
                hintDescription = String(format: strings.switchButtonTraitHintFormat, existingHintDescription)
            } else {
                hintDescription = strings.switchButtonTraitHint
            }
        }

        if accessibilityTraits.contains(.textEntry) && !accessibilityTraits.contains(.notEnabled) {
            if accessibilityTraits.contains(.isEditing) {
                hintDescription = strings.textEntryIsEditingTraitHint
            } else {
                if accessibilityTraits.contains(.scrollable) {
                    // This is a UITextView/TextEditor
                    hintDescription = strings.scrollableTextEntryTraitHint
                } else {
                    // This is a UITextField/TextField
                    hintDescription = strings.textEntryTraitHint
                }
            }
        }

        let hasHintOnly = (accessibilityHint?.nonEmpty() != nil) && (accessibilityLabel?.nonEmpty() == nil) && (accessibilityValue?.nonEmpty() == nil)
        let hidesAdjustableHint = accessibilityTraits.contains(.notEnabled) || accessibilityTraits.contains(.switchButton) || hasHintOnly
        if accessibilityTraits.contains(.adjustable) && !hidesAdjustableHint {
            if let existingHintDescription = hintDescription?.nonEmpty()?.strippingTrailingPeriod() {
                hintDescription = String(format: strings.adjustableTraitHintFormat, existingHintDescription)
            } else {
                hintDescription = strings.adjustableTraitHint
            }
        }

        return (accessibilityDescription, hintDescription)
    }

    // MARK: - Private Methods

    private func accessibilityLabelOverride(for context: AccessibilityHierarchyParser.Context?) -> String? {
        guard let context = context else {
            return nil
        }

        switch context {
        case .tabBarItem(index: _, count: _, item: _):
            return nil

        case .series, .tab, .dataTableCell, .listStart, .listEnd, .landmarkStart, .landmarkEnd:
            return nil
        }
    }

    private func hidesAccessibilityValue(for context: AccessibilityHierarchyParser.Context?) -> Bool {
        if accessibilityTraits.contains(.switchButton) {
            return true
        }

        guard let context = context else {
            return false
        }

        switch context {
        case .tabBarItem(index: _, count: _, item: _):
            return false

        case .series, .tab, .dataTableCell, .listStart, .listEnd, .landmarkStart, .landmarkEnd:
            return false
        }
    }
    
    private func hidesAccessibilityLabel(backDescriptor: String) -> Bool {
        // To prevent duplication, Back Button elements omit their label if it matches the localized "Back" descriptor.
        guard accessibilityTraits.contains(.backButton),
              let label = accessibilityLabel else { return false }
        return label.lowercased() == backDescriptor.lowercased()
    }

    // MARK: - Private Static Properties

    // MARK: - Private

    private struct Strings {

        // MARK: - Public Properties

        let selectedTraitName: String

        let selectedTraitFormat: String

        let notEnabledTraitName: String

        let buttonTraitName: String
        
        let backButtonTraitName: String
        
        let backDescriptor: String

        let tabTraitName: String

        let headerTraitName: String

        let linkTraitName: String

        let adjustableTraitName: String

        let adjustableTraitHint: String

        let adjustableTraitHintFormat: String

        let imageTraitName: String

        let searchFieldTraitName: String

        let switchButtonTraitName: String

        let switchButtonOnStateName: String

        let switchButtonOffStateName: String

        let switchButtonMixedStateName: String

        let switchButtonTraitHint: String

        let switchButtonTraitHintFormat: String

        let seriesContextFormat: String

        let dataTableRowSpanFormat: String

        let dataTableColumnSpanFormat: String

        let dataTableRowFormat: String

        let dataTableColumnFormat: String

        let listStartContext: String

        let listEndContext: String

        let landmarkStartContext: String

        let landmarkEndContext: String

        let textEntryTraitName: String

        let textEntryTraitHint: String

        let textEntryIsEditingTraitHint: String

        let scrollableTextEntryTraitHint: String

        let isEditingTraitName: String

        // MARK: - Life Cycle

        init(locale: String?) {
            self.selectedTraitName = "Selected."
            self.selectedTraitFormat = "Selected: %@"
            self.notEnabledTraitName = "Dimmed."
            self.buttonTraitName = "Button."
            self.backButtonTraitName = "Back Button."
            self.backDescriptor = "Back"
            self.tabTraitName = "Tab."
            self.headerTraitName = "Heading."
            self.linkTraitName = "Link."
            self.adjustableTraitName = "Adjustable."
            self.adjustableTraitHint = "Swipe up or down with one finger to adjust the value."
            self.adjustableTraitHintFormat = "%@. Swipe up or down with one finger to adjust the value."
            self.imageTraitName = "Image."
            self.searchFieldTraitName = "Search Field."
            self.switchButtonTraitName = "Switch Button."
            self.switchButtonOnStateName = "On."
            self.switchButtonOffStateName = "Off."
            self.switchButtonMixedStateName = "Mixed."
            self.switchButtonTraitHint = "Double tap to toggle setting."
            self.switchButtonTraitHintFormat = "%@. Double tap to toggle setting."
            self.seriesContextFormat = "%@ %@ of %@."
            self.dataTableRowSpanFormat = "Spans %@ rows."
            self.dataTableColumnSpanFormat = "Spans %@ columns."
            self.dataTableRowFormat = "Row %@."
            self.dataTableColumnFormat = "Column %@."
            self.listStartContext = "List Start."
            self.listEndContext = "List End."
            self.landmarkStartContext = "Landmark."
            self.landmarkEndContext = "End."
            self.textEntryTraitName = "Text Field."
            self.textEntryTraitHint = "Double tap to edit."
            self.textEntryIsEditingTraitHint = "Use the rotor to access Misspelled Words"
            self.scrollableTextEntryTraitHint = "Double tap to edit., Use the rotor to access Misspelled Words"
            self.isEditingTraitName = "Is editing."
        }

    }

}

// MARK: -

extension String {

    /// Returns the string if it is non-empty, otherwise nil.
    func nonEmpty() -> String? {
        return isEmpty ? nil : self
    }

    func strippingTrailingPeriod() -> String {
        if hasSuffix(".") {
            return String(dropLast())
        } else {
            return self
        }
    }

}

// MARK: -

extension UIAccessibilityTraits {

    static let textEntry = UIAccessibilityTraits(rawValue: 1 << 18) // 0x0000000000040000
    
    static let isEditing = UIAccessibilityTraits(rawValue: 1 << 21) // 0x0000000000200000
    
    static let backButton = UIAccessibilityTraits(rawValue: 1 << 27) // 0x0000000008000000
    
    static let tabBarItem = UIAccessibilityTraits(rawValue: 1 << 28) // 0x0000000010000000
    
    static let scrollable = UIAccessibilityTraits(rawValue: 1 << 47) // 0x0000800000000000
    
    static let switchButton = UIAccessibilityTraits(rawValue: 1 << 53) //0x0020000000000000

}

// MARK: -

extension AccessibilityHierarchyParser.Context {

    var hidesButtonTrait: Bool {
        switch self {
        case .series, .tabBarItem, .dataTableCell, .listStart, .listEnd, .landmarkStart, .landmarkEnd:
            return false

        case .tab:
            return true
        }
    }

    var showsTabTrait: Bool {
        switch self {
        case .series, .dataTableCell, .listStart, .listEnd, .landmarkStart, .landmarkEnd:
            return false

        case .tab, .tabBarItem:
            return true
        }
    }

}
