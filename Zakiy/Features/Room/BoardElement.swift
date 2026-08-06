import Foundation

/// A movable/resizable text element on the live-class whiteboard. The
/// backend stores `board_strokes` as opaque dicts (`stroke = data.get("stroke")`)
/// and only special-cases the `x`, `y`, `fontSize` keys when relaying moves
/// (`board_update_stroke`), so this client defines — and stays consistent
/// with — that same small shape.
struct BoardElement: Identifiable, Hashable {
    let id: String
    var text: String
    var x: Double
    var y: Double
    var fontSize: Double

    init(id: String = UUID().uuidString, text: String, x: Double, y: Double, fontSize: Double = 22) {
        self.id = id
        self.text = text
        self.x = x
        self.y = y
        self.fontSize = fontSize
    }

    init?(json: [String: Any]) {
        guard let id = json["id"] as? String else { return nil }
        self.id = id
        self.text = json["text"] as? String ?? ""
        self.x = json["x"] as? Double ?? 100
        self.y = json["y"] as? Double ?? 100
        self.fontSize = json["fontSize"] as? Double ?? 22
    }

    var asJSON: [String: Any] {
        ["id": id, "text": text, "x": x, "y": y, "fontSize": fontSize]
    }
}
