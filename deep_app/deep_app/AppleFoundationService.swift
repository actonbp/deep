import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Lightweight wrapper around Apple's on-device Foundation Model.
/// Provides a minimal `processConversation` API that mirrors `OpenAIService` for
/// basic text-only chat (no tool calls yet).
@available(iOS 26.0, *)
actor AppleFoundationService {

    enum APIResult {
        case success(text: String)
        case failure(error: Error?)
    }

    /// Convert our internal ChatMessage array into a single prompt string and
    /// get an answer from the on-device model.
    func processConversation(messages: [OpenAIService.ChatMessage]) async -> APIResult {
#if canImport(FoundationModels)
        // Build a very simple prompt: system context (if any) + last user message.
        guard let lastUser = messages.last(where: { $0.role == "user" }),
              let userText = lastUser.content else {
            return .failure(error: nil)
        }

        let systemText = messages.first(where: { $0.role == "system" })?.content ?? ""
        let prompt = [systemText, userText]
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")

        do {
            // Create a session with default configuration
            let session = LanguageModelSession()
            
            // Use the respond API which returns a Generated<String>
            let response = try await session.respond(to: prompt)
            
            return .success(text: response.content)
        } catch {
            return .failure(error: error)
        }
#else
        return .failure(error: nil)
#endif
    }
} 