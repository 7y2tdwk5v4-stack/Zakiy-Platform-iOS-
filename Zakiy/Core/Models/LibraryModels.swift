import Foundation

struct LibraryBookSummary: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title
        case createdAt = "created_at"
    }
}

struct LibraryBookDetail: Codable {
    let title: String
    let extractedText: String

    enum CodingKeys: String, CodingKey {
        case title
        case extractedText = "extracted_text"
    }
}
