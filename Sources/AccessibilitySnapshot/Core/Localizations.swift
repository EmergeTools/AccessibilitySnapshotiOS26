//
//  Localizations.swift
//  AccessibilitySnapshot
//
//  Created by Soroush Khanlou on 7/1/25.
//

#if SWIFT_PACKAGE
import AccessibilitySnapshotParser
#endif

enum Strings {

    static func actionsAvailableText(for locale: String?) -> String {
        return "Actions Available"
    }

    static func moreContentAvailableText(for locale: String?) -> String {
        return "More Content Available"
    }
    
    static func adjustableInputLabelText(for locale: String?) -> String {
        return "Adjustable."
    }
    static func buttonInputLabelText(for locale: String?) -> String {
        return "Button."
    }
}
