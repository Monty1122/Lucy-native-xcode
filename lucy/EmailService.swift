// EmailService.swift

import Foundation

// A struct to match the JSON body required by the Resend API.
struct ResendEmailRequest: Codable {
    let from: String
    let to: [String]
    let subject: String
    let html: String
}

@MainActor
class EmailService {
    // ** API Key has been correctly inserted **
    private let apiKey = "re_Q2gSqJz2_HD26z7SLVQLpBUdbYYncqSmx"
    private let apiURL = URL(string: "https://api.resend.com/emails")!

    /// Sends an email using the Resend.com API.
    func sendEmail(to: String, subject: String, body: String) async throws {
        // You must use a "from" address that you have verified in your Resend account.
        // For testing, Resend allows sending from "onboarding@resend.dev".
        let fromAddress = "Lucy Assistant <onboarding@resend.dev>"
        
        let requestBody = ResendEmailRequest(
            from: fromAddress,
            to: [to],
            subject: subject,
            html: "<strong>\(body)</strong>" // Resend uses an 'html' field for the body
        )
        
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            print("Error encoding request body: \(error)")
            throw error
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            // This will help debug if Resend returns an error
            if let responseBody = String(data: data, encoding: .utf8) {
                print("Resend API Error: \(responseBody)")
            }
            throw NSError(domain: "EmailServiceError", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: "Failed to send email."])
        }
        
        print("Email sent successfully!")
    }
}
