import SwiftUI

struct LibraryView: View {
    @Environment(AuthSession.self) private var authSession

    @State private var books: [LibraryBookSummary] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var renamingBook: LibraryBookSummary?
    @State private var renameText = ""

    var body: some View {
        Group {
            if !authSession.isSignedIn {
                SignedOutPlaceholder(feature: "مكتبتك")
            } else if isLoading {
                LoadingView()
            } else if let errorMessage {
                ErrorBanner(message: errorMessage) { self.errorMessage = nil }
            } else if books.isEmpty {
                EmptyStateView(systemImage: "books.vertical", title: "مكتبتك فاضية", message: "أي ملف تحفظه بعد التلخيص بيظهر هنا")
            } else {
                List {
                    ForEach(books) { book in
                        NavigationLink(value: book) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(book.title)
                                    .font(.zakiyBody.weight(.semibold))
                                if let createdAt = book.createdAt {
                                    Text(createdAt)
                                        .font(.zakiyCaption)
                                        .foregroundStyle(Color.zakiyTextSecondary)
                                }
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task { await delete(book) }
                            } label: {
                                Label("حذف", systemImage: "trash")
                            }
                            Button {
                                renamingBook = book
                                renameText = book.title
                            } label: {
                                Label("إعادة تسمية", systemImage: "pencil")
                            }
                            .tint(Color.zakiyMustard)
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable { await load() }
                .navigationDestination(for: LibraryBookSummary.self) { book in
                    LibraryDetailView(bookId: book.id, title: book.title)
                }
            }
        }
        .background(Color.zakiyBackground.ignoresSafeArea())
        .navigationTitle("مكتبتي")
        .task { await load() }
        .alert("إعادة تسمية", isPresented: Binding(get: { renamingBook != nil }, set: { if !$0 { renamingBook = nil } })) {
            TextField("العنوان", text: $renameText)
            Button("إلغاء", role: .cancel) { renamingBook = nil }
            Button("حفظ") {
                if let book = renamingBook { Task { await rename(book) } }
            }
        }
    }

    private func load() async {
        guard authSession.isSignedIn else { return }
        isLoading = true
        do {
            books = try await APIClient.shared.libraryBooks()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func delete(_ book: LibraryBookSummary) async {
        do {
            try await APIClient.shared.deleteLibraryBook(id: book.id)
            books.removeAll { $0.id == book.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func rename(_ book: LibraryBookSummary) async {
        let newTitle = renameText.trimmingCharacters(in: .whitespaces)
        renamingBook = nil
        guard !newTitle.isEmpty else { return }
        do {
            try await APIClient.shared.renameLibraryBook(id: book.id, title: newTitle)
            if let index = books.firstIndex(where: { $0.id == book.id }) {
                books[index] = LibraryBookSummary(id: book.id, title: newTitle, createdAt: book.createdAt)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

/// Shown in place of any account-only feature when the user is browsing as
/// a guest, with a shortcut back to sign in.
struct SignedOutPlaceholder: View {
    let feature: String

    var body: some View {
        VStack(spacing: ZakiySpacing.md) {
            Image(systemName: "lock.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.zakiyTextSecondary)
            Text("سجّل حساب عشان توصل لـ\(feature)")
                .font(.zakiyHeadline)
                .multilineTextAlignment(.center)
        }
        .padding(ZakiySpacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.zakiyBackground.ignoresSafeArea())
    }
}

#Preview {
    NavigationStack { LibraryView() }
        .environment(AuthSession.shared)
}
