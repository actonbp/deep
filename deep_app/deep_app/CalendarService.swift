import Foundation
import GoogleSignIn

// Service to interact with the Google Calendar API
class CalendarService {
    
    // --- Structs for URLSession Decoding ---
    struct EventItem: Decodable { 
        let id: String? 
        let summary: String? 
        struct EventDateTime: Decodable { let dateTime: String? } // Keep dateTime as String
        let start: EventDateTime? 
        let end: EventDateTime? 
    }
    struct EventsListResponse: Decodable { let items: [EventItem]? }
    // ---------------------------------------
    
    // Define the base URL for the Calendar API v3
    private let calendarApiBaseUrl = "https://www.googleapis.com/calendar/v3/calendars/"
    
    // Function to fetch events for today
    func fetchTodaysEvents(completion: @escaping ([CalendarEvent]?, Error?) -> Void) {
        print("CalendarService: Attempting to fetch today's events...")
        
        // 1. Check for signed-in user
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            print("CalendarService: ERROR - User not signed in.")
            // Create a custom error or use a generic one
            let error = NSError(domain: "CalendarServiceError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])
            completion(nil, error)
            return
        }
        
        // 2. Get the access token (using refreshTokensIfNeeded)
        user.refreshTokensIfNeeded { authentication, error in
            if let error = error {
                print("CalendarService: ERROR - Failed to refresh token: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            // Combine unwrapping: Check authentication and get accessToken.tokenString
            guard let tokenString = authentication?.accessToken.tokenString else {
                print("CalendarService: ERROR - Could not get access token string after refresh.")
                let error = NSError(domain: "CalendarServiceError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing access token string"])
                completion(nil, error)
                return
            }
            
            // 3. Prepare API request parameters
            let calendarId = "primary"
            let timeZone = TimeZone.current.identifier
            let today = Calendar.current.startOfDay(for: Date())
            guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) else {
                print("CalendarService: ERROR - Could not calculate tomorrow's date.")
                DispatchQueue.main.async { completion(nil, NSError(domain: "CalendarServiceError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Date calculation error"])) }
                return
            }
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime]
            let timeMin = dateFormatter.string(from: today)
            let timeMax = dateFormatter.string(from: tomorrow)
            
            // Construct the URL
            guard var urlComponents = URLComponents(string: "\(self.calendarApiBaseUrl)\(calendarId)/events") else {
                print("CalendarService: ERROR - Invalid base URL.")
                 DispatchQueue.main.async { completion(nil, NSError(domain: "CalendarServiceError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid URL components"])) }
                return
            }
            urlComponents.queryItems = [
                URLQueryItem(name: "timeMin", value: timeMin),
                URLQueryItem(name: "timeMax", value: timeMax),
                URLQueryItem(name: "timeZone", value: timeZone),
                URLQueryItem(name: "singleEvents", value: "true"), // Expand recurring events
                URLQueryItem(name: "orderBy", value: "startTime") // Sort by start time
            ]
            
            guard let url = urlComponents.url else {
                print("CalendarService: ERROR - Could not construct final URL.")
                DispatchQueue.main.async { completion(nil, NSError(domain: "CalendarServiceError", code: 500, userInfo: [NSLocalizedDescriptionKey: "URL construction error"])) }
                return
            }
            
            print("CalendarService: Fetching URL: \(url.absoluteString)")
            
            // 4. Create URLRequest and add Authorization header manually
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            // --- Debugging: Print token string and header --- 
            print("CalendarService: Using Access Token String starting with: \(String(tokenString.prefix(10)))... ending with: \(String(tokenString.suffix(10)))")
            let authHeaderValue = "Bearer \(tokenString)"
            request.setValue(authHeaderValue, forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Accept") // Good practice
            print("CalendarService: Authorization header set to: Bearer \(String(tokenString.prefix(10)))... [REDACTED]")
            // -----------------------------------------
            
            // 5. Execute the request (No authorizer needed now)
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                // Handle errors (network, HTTP status)
                if let error = error {
                    print("CalendarService: ERROR - Network request failed: \(error.localizedDescription)")
                    DispatchQueue.main.async { completion(nil, error) }
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    print("CalendarService: ERROR - HTTP Error: Status Code \(statusCode)")
                    
                    // --- Attempt to decode error body --- 
                    var errorDetails = "HTTP Error \(statusCode)"
                    if let data = data, let jsonError = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("CalendarService: Received error details JSON: \(jsonError)")
                        // Try to extract common Google API error fields
                        if let errorDict = jsonError["error"] as? [String: Any] {
                            let message = errorDict["message"] as? String
                            let reason = (errorDict["errors"] as? [[String: Any]])?.first?["reason"] as? String
                            errorDetails = "\(statusCode): \(message ?? "Unknown error") (Reason: \(reason ?? "N/A"))"
                        } else if let message = jsonError["message"] as? String {
                             errorDetails = "\(statusCode): \(message)"
                        }
                    }
                    // -----------------------------------
                    
                    let error = NSError(domain: "CalendarServiceError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: errorDetails]) // Use detailed message
                    DispatchQueue.main.async { completion(nil, error) }
                    return
                }
                
                guard let data = data else {
                    print("CalendarService: ERROR - No data received.")
                    let error = NSError(domain: "CalendarServiceError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                    DispatchQueue.main.async { completion(nil, error) }
                    return
                }
                
                // 6. Decode the JSON response
                struct EventsResponse: Decodable {
                    let items: [CalendarEvent]?
                }
                
                do {
                    let decoder = JSONDecoder()
                    let eventsResponse = try decoder.decode(EventsResponse.self, from: data)
                    print("CalendarService: Successfully fetched \(eventsResponse.items?.count ?? 0) events.")
                    DispatchQueue.main.async { completion(eventsResponse.items ?? [], nil) }
                } catch {
                    print("CalendarService: ERROR - JSON Decoding failed: \(error)")
                    #if DEBUG
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("--- Received JSON --- \n\(jsonString)\n---------------------")
                    }
                    #endif
                    DispatchQueue.main.async { completion(nil, error) }
                }
            }
            task.resume()
        }
    }
    
    // MARK: - Event Creation
    
    func createCalendarEvent(summary: String, description: String?, startTime: Date, endTime: Date, completion: @escaping (String?, Error?) -> Void) {
        print("CalendarService: Attempting to create event '\(summary)'...")
        
        // 1. Check user & get token
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            let error = NSError(domain: "CalendarServiceError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])
            completion(nil, error)
            return
        }
        
        user.refreshTokensIfNeeded { authentication, error in
            if let error = error {
                print("CalendarService: ERROR - Failed to refresh token for event creation: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            guard let tokenString = authentication?.accessToken.tokenString else {
                print("CalendarService: ERROR - Could not get access token string for event creation.")
                let error = NSError(domain: "CalendarServiceError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing access token string"])
                completion(nil, error)
                return
            }
            
            // 2. Prepare API Request
            let calendarId = "primary"
            let urlString = "\(self.calendarApiBaseUrl)\(calendarId)/events"
            guard let url = URL(string: urlString) else {
                print("CalendarService: ERROR - Invalid URL for event creation.")
                let error = NSError(domain: "CalendarServiceError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid URL for event creation"])
                 DispatchQueue.main.async { completion(nil, error) } // Dispatch completion
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(tokenString)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // 3. Construct JSON Body
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            let startTimeStr = dateFormatter.string(from: startTime)
            let endTimeStr = dateFormatter.string(from: endTime)
            
            // Google API expects timeZone within start/end objects
            let timeZone = TimeZone.current.identifier
            
            var requestBody: [String: Any] = [
                "summary": summary,
                "start": [
                    "dateTime": startTimeStr,
                    "timeZone": timeZone
                ],
                "end": [
                    "dateTime": endTimeStr,
                    "timeZone": timeZone
                ]
            ]
            
            if let description = description, !description.isEmpty {
                requestBody["description"] = description
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
                request.httpBody = jsonData
                print("CalendarService: Sending request body: \(String(data: jsonData, encoding: .utf8) ?? "[Could not encode]")")
            } catch {
                print("CalendarService: ERROR - Failed to serialize JSON body: \(error)")
                 DispatchQueue.main.async { completion(nil, error) } // Dispatch completion
                return
            }
            
            // 4. Execute Request
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                 // Handle network/HTTP errors (similar to fetchEvents)
                if let error = error {
                    print("CalendarService: ERROR - Event creation network request failed: \(error.localizedDescription)")
                     DispatchQueue.main.async { completion(nil, error) }
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    print("CalendarService: ERROR - Event creation HTTP Error: Status Code \(statusCode)")
                    var errorDetails = "HTTP Error \(statusCode)"
                    if let data = data, let jsonError = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("CalendarService: Received error details JSON: \(jsonError)")
                        if let errorDict = jsonError["error"] as? [String: Any] {
                            let message = errorDict["message"] as? String
                            let reason = (errorDict["errors"] as? [[String: Any]])?.first?["reason"] as? String
                            errorDetails = "\(statusCode): \(message ?? "Unknown error") (Reason: \(reason ?? "N/A"))"
                        } else if let message = jsonError["message"] as? String {
                             errorDetails = "\(statusCode): \(message)"
                        }
                    }
                    let nsError = NSError(domain: "CalendarServiceError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: errorDetails])
                     DispatchQueue.main.async { completion(nil, nsError) }
                    return
                }
                
                // Success! Optionally decode the created event ID from the response data
                var createdEventId: String? = nil
                if let data = data, let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    createdEventId = jsonResponse["id"] as? String
                    print("CalendarService: Successfully created event. ID: \(createdEventId ?? "N/A")")
                } else {
                     print("CalendarService: Successfully created event (Could not parse response ID).")
                }
                DispatchQueue.main.async { completion(createdEventId, nil) }
            }
            task.resume()
        }
    }
    
    // MARK: - Event Deletion (Rewritten to use URLSession)
    
    func deleteCalendarEvent(summary: String, startTime: Date, completion: @escaping (Bool, Error?) -> Void) {
        print("CalendarService: Attempting to delete event '\(summary)' starting at \(startTime)...")
        
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            completion(false, NSError(domain: "CalendarServiceError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not signed in"]))
            return
        }
        
        user.refreshTokensIfNeeded { [weak self] authentication, error in
            guard let self = self else { return }
            if let error = error { completion(false, error); return }
            guard let tokenString = authentication?.accessToken.tokenString else {
                completion(false, NSError(domain: "CalendarServiceError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing access token string"]))
                return
            }
            
            // Fetch events to find the ID
            self.fetchEventsHelper(around: startTime, tokenString: tokenString) { events, fetchError in
                guard let events = events, fetchError == nil else {
                    completion(false, fetchError ?? NSError(domain: "CalendarService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not fetch events to find for deletion."]))
                    return
                }
                
                // Find the specific event (using ISO date comparison for safety)
                let isoFormatter = ISO8601DateFormatter()
                isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds] // Match Google's precision
                let targetStartTimeString = isoFormatter.string(from: startTime)
                
                // --- Debug Logging ---
                if UserDefaults.standard.bool(forKey: AppSettings.debugLogEnabledKey) {
                    print("DEBUG [CalendarService Delete]: Searching for event with Summary: \"\(summary)\" and ISO Start Time: \(targetStartTimeString)")
                    print("DEBUG [CalendarService Delete]: Fetched events within window:")
                    if events.isEmpty {
                        print("    (No events found in the fetched time window)")
                    } else {
                        for event in events {
                            let fetchedSummary = event.summary ?? "(Nil Summary)"
                            let fetchedStartTime = event.start?.dateTime ?? "(Nil Start DateTime)"
                            print("    - Summary: \"\(fetchedSummary)\", Start: \(fetchedStartTime)")
                        }
                    }
                }
                // --- End Debug Logging ---
                
                guard let eventToDelete = events.first(where: { 
                          $0.summary == summary && 
                          $0.start?.dateTime == targetStartTimeString 
                      }),
                      let eventId = eventToDelete.id else { // Use the ID from our EventItem struct
                    print("Error: Could not find event with summary '\(summary)' starting exactly at \(startTime) (ISO: \(targetStartTimeString)) to delete.")
                    completion(false, NSError(domain: "CalendarService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Event '\(summary)' starting at that specific time not found."]))
                    return
                }
                
                print("CalendarService: Found event to delete: ID = \(eventId)")
                
                // Create and execute the DELETE request
                let calendarId = "primary"
                let urlString = "\(self.calendarApiBaseUrl)\(calendarId)/events/\(eventId)"
                guard let url = URL(string: urlString) else {
                    completion(false, NSError(domain: "CalendarServiceError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid URL for event deletion"]))
                    return
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "DELETE"
                request.setValue("Bearer \(tokenString)", forHTTPHeaderField: "Authorization")
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    self.handleApiResponse(data: data, response: response, error: error, completion: completion)
                }
                task.resume()
            }
        }
    }
    
    // MARK: - Event Update (Rewritten to use URLSession)
    
    func updateCalendarEventTime(summary: String, originalStartTime: Date, newStartTime: Date, newEndTime: Date, completion: @escaping (Bool, Error?) -> Void) {
        print("CalendarService: Attempting to update event '\(summary)' from \(originalStartTime) to \(newStartTime) - \(newEndTime)...")
        
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            completion(false, NSError(domain: "CalendarServiceError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not signed in"]))
            return
        }
        
        user.refreshTokensIfNeeded { [weak self] authentication, error in
            guard let self = self else { return }
            if let error = error { completion(false, error); return }
            guard let tokenString = authentication?.accessToken.tokenString else {
                completion(false, NSError(domain: "CalendarServiceError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing access token string"]))
                return
            }
            
            // Fetch events to find the ID
            self.fetchEventsHelper(around: originalStartTime, tokenString: tokenString) { events, fetchError in
                guard let events = events, fetchError == nil else {
                    completion(false, fetchError ?? NSError(domain: "CalendarService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Could not fetch events to find for update."]))
                    return
                }
                
                // Find the specific event (using ISO date comparison)
                let isoFormatter = ISO8601DateFormatter()
                isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let targetStartTimeString = isoFormatter.string(from: originalStartTime)
                
                guard let eventToUpdate = events.first(where: { 
                          $0.summary == summary && 
                          $0.start?.dateTime == targetStartTimeString 
                      }),
                      let eventId = eventToUpdate.id else {
                    print("Error: Could not find event with summary '\(summary)' starting exactly at \(originalStartTime) (ISO: \(targetStartTimeString)) to update.")
                    completion(false, NSError(domain: "CalendarService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Event '\(summary)' starting at the original time not found."]))
                    return
                }
                
                print("CalendarService: Found event to update: ID = \(eventId)")
                
                // Construct JSON Body for PATCH
                let timeZone = TimeZone.current.identifier
                let requestBody: [String: Any] = [
                    "start": [
                        "dateTime": isoFormatter.string(from: newStartTime),
                        "timeZone": timeZone
                    ],
                    "end": [
                        "dateTime": isoFormatter.string(from: newEndTime),
                        "timeZone": timeZone
                    ]
                ]
                
                // Create and execute the PATCH request
                let calendarId = "primary"
                let urlString = "\(self.calendarApiBaseUrl)\(calendarId)/events/\(eventId)"
                guard let url = URL(string: urlString) else {
                    completion(false, NSError(domain: "CalendarServiceError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid URL for event update"]))
                    return
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "PATCH"
                request.setValue("Bearer \(tokenString)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
                } catch {
                    DispatchQueue.main.async { completion(false, error) }
                    return
                }
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    self.handleApiResponse(data: data, response: response, error: error, completion: completion)
                }
                task.resume()
            }
        }
    }
    
    // --- HELPER: Fetch Events using URLSession (Rewritten) ---
    // Uses a simple Decodable struct, similar to fetchTodaysEvents
    private func fetchEventsHelper(around date: Date, tokenString: String, completion: @escaping ([CalendarService.EventItem]?, Error?) -> Void) {
        print("CalendarService Helper: Fetching events around \(date)...")
        let calendar = Calendar.current
        guard let timeMinDate = calendar.date(byAdding: .hour, value: -4, to: date),
              let timeMaxDate = calendar.date(byAdding: .hour, value: 4, to: date) else {
            completion(nil as [CalendarService.EventItem]?, NSError(domain: "CalendarService", code: -5, userInfo: [NSLocalizedDescriptionKey: "Could not calculate time range for fetch."]))
            return
        }
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        let timeMin = dateFormatter.string(from: timeMinDate)
        let timeMax = dateFormatter.string(from: timeMaxDate)
        
        let calendarId = "primary"
        guard var urlComponents = URLComponents(string: "\(self.calendarApiBaseUrl)\(calendarId)/events") else {
            completion(nil as [CalendarService.EventItem]?, NSError(domain: "CalendarServiceError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid URL components for helper fetch"]))
            return
        }
        urlComponents.queryItems = [
            URLQueryItem(name: "timeMin", value: timeMin),
            URLQueryItem(name: "timeMax", value: timeMax),
            URLQueryItem(name: "singleEvents", value: "true"), 
            URLQueryItem(name: "orderBy", value: "startTime")
        ]
        
        guard let url = urlComponents.url else {
            completion(nil as [CalendarService.EventItem]?, NSError(domain: "CalendarServiceError", code: 500, userInfo: [NSLocalizedDescriptionKey: "URL construction error for helper fetch"]))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(tokenString)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(nil as [CalendarService.EventItem]?, error) }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                print("CalendarService Helper Fetch: ERROR - HTTP Error: Status Code \(statusCode)")
                let error = NSError(domain: "CalendarServiceError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Helper fetch HTTP error \(statusCode)"])
                DispatchQueue.main.async { completion(nil as [CalendarService.EventItem]?, error) }
                return
            }
            
            guard let data = data else {
                let error = NSError(domain: "CalendarServiceError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received in helper fetch"])
                DispatchQueue.main.async { completion(nil as [CalendarService.EventItem]?, error) }
                return
            }
            
            // Decode using simple Decodable struct
            
            do {
                let decoder = JSONDecoder()
                let eventsResponse = try decoder.decode(CalendarService.EventsListResponse.self, from: data)
                print("CalendarService Helper Fetch: Successfully decoded \(eventsResponse.items?.count ?? 0) potential events.")
                DispatchQueue.main.async { completion(eventsResponse.items, nil) } 
            } catch {
                print("CalendarService Helper Fetch: ERROR - JSON Decoding failed: \(error)")
                DispatchQueue.main.async { completion(nil as [CalendarService.EventItem]?, error) }
            }
        }
        task.resume()
    }
    // --- END HELPER ---
    
    // --- HELPER: Handle API Response (NEW) ---
    // Centralized logic for checking HTTP status and errors for POST/PATCH/DELETE
    private func handleApiResponse(data: Data?, response: URLResponse?, error: Error?, completion: @escaping (Bool, Error?) -> Void) {
        if let error = error {
            print("CalendarService: ERROR - Network request failed: \(error.localizedDescription)")
            DispatchQueue.main.async { completion(false, error) }
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("CalendarService: ERROR - Invalid response received.")
            let error = NSError(domain: "CalendarServiceError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            DispatchQueue.main.async { completion(false, error) }
            return
        }
        
        // Check for successful status codes (200-299 range, includes 204 No Content for DELETE)
        if (200...299).contains(httpResponse.statusCode) {
            print("CalendarService: Request successful (Status code: \(httpResponse.statusCode)).")
            DispatchQueue.main.async { completion(true, nil) }
        } else {
            // Handle HTTP errors
            let statusCode = httpResponse.statusCode
            print("CalendarService: ERROR - HTTP Error: Status Code \(statusCode)")
            var errorDetails = "HTTP Error \(statusCode)"
            if let data = data, let jsonError = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let errorDict = jsonError["error"] as? [String: Any], let message = errorDict["message"] as? String {
                    errorDetails = "\(statusCode): \(message)"
                }
            }
            let nsError = NSError(domain: "CalendarServiceError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: errorDetails])
            DispatchQueue.main.async { completion(false, nsError) }
        }
    }
    // --- END RESPONSE HANDLER ---
} 