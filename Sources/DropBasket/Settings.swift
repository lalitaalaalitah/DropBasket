//
//  Settings.swift
//  DropBasket
//
//  Author: lalitaalaalitah
//  Website: https://www.lalitaalaalitah.com
//  GitHub Profile: https://github.com/lalitaalaalitah
//

import Foundation
import CoreGraphics

public enum ShakeSensitivity: String, CaseIterable, Sendable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    public var minStrokeDistance: CGFloat {
        switch self {
        case .low: return 10.0
        case .medium: return 6.5   // Fast & effortless
        case .high: return 4.0    // Ultra sensitive
        }
    }

    public var minReversals: Int {
        switch self {
        case .low: return 2
        case .medium: return 2   // Just 2 reversals (quick flick-and-back)
        case .high: return 2
        }
    }

    public var minTotalPath: CGFloat {
        switch self {
        case .low: return 42.0
        case .medium: return 26.0
        case .high: return 16.0
        }
    }

    public var timeWindow: TimeInterval {
        switch self {
        case .low: return 0.40
        case .medium: return 0.45
        case .high: return 0.50
        }
    }
}

public final class AppSettings: @unchecked Sendable {
    public static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let sensitivity = "db_sensitivity"
        static let triggerOnFinderSelection = "db_trigger_on_finder_sel"
        static let defaultActionIsMove = "db_default_action_is_move"
        static let soundEffects = "db_sound_effects"
        static let autoHideEmpty = "db_auto_hide_empty"
        static let autoHideDelay = "db_auto_hide_delay"
    }

    public var sensitivity: ShakeSensitivity {
        get {
            if let val = defaults.string(forKey: Keys.sensitivity),
               let s = ShakeSensitivity(rawValue: val) {
                return s
            }
            return .medium
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.sensitivity)
        }
    }

    public var triggerOnFinderSelection: Bool {
        get {
            defaults.object(forKey: Keys.triggerOnFinderSelection) == nil ? true : defaults.bool(forKey: Keys.triggerOnFinderSelection)
        }
        set {
            defaults.set(newValue, forKey: Keys.triggerOnFinderSelection)
        }
    }

    public var defaultActionIsMove: Bool {
        get {
            defaults.bool(forKey: Keys.defaultActionIsMove)
        }
        set {
            defaults.set(newValue, forKey: Keys.defaultActionIsMove)
        }
    }

    public var soundEffects: Bool {
        get {
            defaults.object(forKey: Keys.soundEffects) == nil ? true : defaults.bool(forKey: Keys.soundEffects)
        }
        set {
            defaults.set(newValue, forKey: Keys.soundEffects)
        }
    }

    public var autoHideEmpty: Bool {
        get {
            defaults.object(forKey: Keys.autoHideEmpty) == nil ? true : defaults.bool(forKey: Keys.autoHideEmpty)
        }
        set {
            defaults.set(newValue, forKey: Keys.autoHideEmpty)
        }
    }

    public var autoHideDelay: TimeInterval {
        get {
            let val = defaults.double(forKey: Keys.autoHideDelay)
            return val > 0 ? val : 5.0
        }
        set {
            defaults.set(newValue, forKey: Keys.autoHideDelay)
        }
    }

    private init() {}
}
