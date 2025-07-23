/*
Bryan's Brain - Scratchpad Update Tool

Abstract:
Tool for updating scratchpad notes using Foundation Models framework
*/

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26.0, *)
struct UpdateScratchpadTool: Tool {
    let name = "updateScratchpad"
    let description = "Updates the contents of the user's scratchpad notes"
    
    @Generable
    struct Arguments {
        @Guide(description: "The new content to save to the scratchpad")
        let content: String
        
        @Guide(description: "Whether to append to existing content (true) or replace it (false). Default is false")
        let append: Bool?
    }
    
    func call(arguments: Arguments) async -> String {
        Logging.general.log("🚨 UpdateScratchpadTool: Updating scratchpad")
        
        let shouldAppend = arguments.append ?? false
        let newContent: String
        
        if shouldAppend {
            let existingContent = UserDefaults.standard.string(forKey: "userNotes") ?? ""
            newContent = existingContent.isEmpty ? arguments.content : "\(existingContent)\n\n\(arguments.content)"
            Logging.general.log("UpdateScratchpadTool: Appending to existing content")
        } else {
            newContent = arguments.content
            Logging.general.log("UpdateScratchpadTool: Replacing existing content")
        }
        
        UserDefaults.standard.set(newContent, forKey: "userNotes")
        
        let action = shouldAppend ? "appended to" : "updated"
        Logging.general.log("UpdateScratchpadTool: Scratchpad \(action) successfully")
        return "Scratchpad \(action) successfully."
    }
}