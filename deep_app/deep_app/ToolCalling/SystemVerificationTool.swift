/*
Bryan's Brain - System Verification Tool

Abstract:
Simple tool for verifying the Foundation Models system is working
*/

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26.0, *)
struct SystemVerificationTool: Tool {
    let name = "verifySystem"
    let description = "Verifies that the system is working correctly"
    
    @Generable
    struct Arguments {
        @Guide(description: "Message to verify with")
        let message: String
    }
    
    func call(arguments: Arguments) async -> ToolOutput {
        Logging.general.log("🚨 SystemVerificationTool: Verifying with message: \(arguments.message)")
        
        let timestamp = Date().formatted(date: .abbreviated, time: .shortened)
        let output = "System verification successful. Message: '\(arguments.message)' at \(timestamp)"
        
        Logging.general.log("SystemVerificationTool: Verification complete")
        return ToolOutput(output)
    }
}