/*
Bryan's Brain - Scratchpad Retrieval Tool

Abstract:
Tool for retrieving scratchpad notes using Foundation Models framework
*/

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26.0, *)
struct GetScratchpadTool: Tool {
    let name = "getScratchpad"
    let description = "Gets the current contents of the user's scratchpad notes"
    
    @Generable
    struct Arguments {
        let retrieve: Bool
    }
    
    func call(arguments: Arguments) async -> ToolOutput {
        Logging.general.log("🚨 GetScratchpadTool: Getting scratchpad contents")
        
        let notes = UserDefaults.standard.string(forKey: "userNotes") ?? ""
        
        if notes.isEmpty {
            Logging.general.log("GetScratchpadTool: Scratchpad is empty")
            return ToolOutput("Your scratchpad is currently empty.")
        } else {
            Logging.general.log("GetScratchpadTool: Retrieved scratchpad contents")
            return ToolOutput("Your scratchpad contents:\n\n\(notes)")
        }
    }
}