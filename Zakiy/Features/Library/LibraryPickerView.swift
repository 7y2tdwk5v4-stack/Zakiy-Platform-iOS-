import SwiftUI

/// Sheet used from the solo-upload screen to reuse a previously saved
/// library book's text instead of uploading the PDF again.
struct LibraryPickerView: View {
    let onPick: (LibraryBookDetail) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var books: [LibraryBookSummary] = []
    @State private var isLoading = true
    @State private var loadingBookId: String?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    LoadingView()
                } else if books.isEmpty {
                    EmptyStateView(systemImage: "books.vertical", title: "ما فيه ملفات محفوظة")
                } else {
                    List(books) { book in
                        Button {
                            Task { await pick(book) }
                        } label: {
                            HStack {
                                Text(book.title)
                                    .foregroundStyle(Color.zakiyTextPrimary)
                                Spacer()
                                if loadingBookId == book.id { ProgressView() }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color.zakiyBackground.ignoresSafeArea())
            .navigationTitle("اختر من مكتبتي")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") { dismiss() }
                }
            }
            .task { await load() }
            .alert("خطأ", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("حسنًا", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func load() async {
        do {
            books = try await APIClient.shared.libraryBooks()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func pick(_ book: LibraryBookSummary) async {
        loadingBookId = book.id
        do {
            let detail = try await APIClient.shared.libraryBook(id: book.id)
            dismiss()
            onPick(detail)
        } catch {
            errorMessage = error.localizedDescription
        }
        loadingBookId = nil
    }
}
