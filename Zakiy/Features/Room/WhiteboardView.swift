import SwiftUI

/// Shared whiteboard for the live-class mode. Elements are plain movable/
/// resizable text boxes (see `BoardElement`) rather than freehand ink,
/// matching the small `{x, y, fontSize}` patch shape the backend actually
/// relays — `handle_board_update_stroke` in app.py only ever copies the
/// `x`, `y`, and `fontSize` keys from a patch, so editing an element's text
/// after creation is intentionally not offered here: it would look like it
/// worked locally but silently fail to sync to anyone else in the room.
struct WhiteboardView: View {
    @State var store: RoomStore
    let canEdit: Bool

    @State private var draggingElementId: String?
    @State private var dragOffset: CGSize = .zero
    @State private var selectedElementId: String?
    @State private var newElementText = ""
    @State private var showAddSheet = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.zakiySurface

            ForEach(store.boardElements) { element in
                Text(element.text)
                    .font(.system(size: element.fontSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.zakiyNavy)
                    .padding(6)
                    .background(Color.zakiyMustard.opacity(selectedElementId == element.id ? 0.5 : 0.25))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .position(
                        x: element.x + (draggingElementId == element.id ? dragOffset.width : 0),
                        y: element.y + (draggingElementId == element.id ? dragOffset.height : 0)
                    )
                    .gesture(dragGesture(for: element))
                    .onTapGesture {
                        guard canEdit else { return }
                        selectedElementId = (selectedElementId == element.id) ? nil : element.id
                    }
            }

            if canEdit, let selectedId = selectedElementId, let selected = store.boardElements.first(where: { $0.id == selectedId }) {
                sizeControls(for: selected)
                    .position(x: min(selected.x + 70, 260), y: max(selected.y - 30, 30))
            }
        }
        .clipped()
        .overlay(alignment: .bottomTrailing) {
            if canEdit {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.zakiyMustard)
                        .background(Circle().fill(Color.zakiyNavy))
                }
                .padding()
            }
        }
        .alert("إضافة نص", isPresented: $showAddSheet) {
            TextField("النص", text: $newElementText)
            Button("إلغاء", role: .cancel) { newElementText = "" }
            Button("إضافة") {
                let text = newElementText.trimmingCharacters(in: .whitespaces)
                guard !text.isEmpty else { return }
                store.addBoardElement(BoardElement(text: text, x: 140, y: 140))
                newElementText = ""
            }
        }
    }

    private func dragGesture(for element: BoardElement) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard canEdit else { return }
                draggingElementId = element.id
                dragOffset = value.translation
            }
            .onEnded { value in
                guard canEdit else { return }
                draggingElementId = nil
                dragOffset = .zero
                store.moveBoardElement(id: element.id, x: element.x + value.translation.width, y: element.y + value.translation.height)
            }
    }

    private func sizeControls(for element: BoardElement) -> some View {
        HStack(spacing: ZakiySpacing.sm) {
            Button {
                store.resizeBoardElement(id: element.id, fontSize: max(12, element.fontSize - 4))
            } label: {
                Image(systemName: "minus.circle.fill")
            }
            Button {
                store.resizeBoardElement(id: element.id, fontSize: min(60, element.fontSize + 4))
            } label: {
                Image(systemName: "plus.circle.fill")
            }
        }
        .padding(ZakiySpacing.sm)
        .background(Color.zakiyNavy)
        .foregroundStyle(.white)
        .clipShape(Capsule())
    }
}
