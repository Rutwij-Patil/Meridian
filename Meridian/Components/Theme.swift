//
//  Theme.swift
//  Meridian
//

import SwiftUI

enum Theme {
    static let bgPrimary    = Color(red: 0.106, green: 0.106, blue: 0.114)
    static let bgSecondary  = Color(red: 0.122, green: 0.122, blue: 0.129)
    static let bgTertiary   = Color(red: 0.137, green: 0.137, blue: 0.145)
    static let bgInput      = Color(red: 0.165, green: 0.165, blue: 0.173)

    static let borderSubtle = Color.white.opacity(0.06)
    static let borderStrong = Color.white.opacity(0.12)

    static let textPrimary   = Color(red: 0.910, green: 0.902, blue: 0.890)
    static let textSecondary = Color(red: 0.659, green: 0.647, blue: 0.624)
    static let textTertiary  = Color(red: 0.424, green: 0.416, blue: 0.400)
    static let textQuiet     = Color(red: 0.533, green: 0.533, blue: 0.533)

    static let accent       = Color(red: 0.369, green: 0.761, blue: 0.761)
    static let accentMuted  = Color(red: 0.122, green: 0.180, blue: 0.176)
    static let accentBorder = Color(red: 0.369, green: 0.761, blue: 0.761).opacity(0.35)

    static let statusOK     = Color(red: 0.290, green: 0.871, blue: 0.502)
}
