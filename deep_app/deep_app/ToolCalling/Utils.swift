/*
Bryan's Brain - Utilities

Abstract:
Project utilities for logging and other miscellaneous needs, following Apple's pattern
*/

import os

enum Logging {
    static let subsystem = "com.bryansbrain.deep-app"
    
    static let general = Logger(subsystem: subsystem, category: "FoundationModels")
}