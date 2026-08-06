import SwiftUI

struct ProfileEditView: View {
    let profile: ProfileDetail
    var onSaved: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var bio: String
    @State private var schoolName: String
    @State private var isPrivate: Bool
    @State private var showPerformance: Bool
    @State private var showLibrary: Bool
    @State private var showArchive: Bool
    @State private var showFriends: Bool
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(profile: ProfileDetail, onSaved: @escaping () async -> Void) {
        self.profile = profile
        self.onSaved = onSaved
        _bio = State(initialValue: profile.bio ?? "")
        _schoolName = State(initialValue: profile.schoolName ?? "")
        _isPrivate = State(initialValue: profile.isPrivate)
        _showPerformance = State(initialValue: profile.showPerformance ?? true)
        _showLibrary = State(initialValue: profile.showLibrary ?? true)
        _showArchive = State(initialValue: profile.showArchive ?? true)
        _showFriends = State(initialValue: profile.showFriends ?? true)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("عنك") {
                    TextField("نبذة عنك", text: $bio, axis: .vertical)
                    TextField("المدرسة", text: $schoolName)
                }

                Section("الخصوصية") {
                    Toggle("حساب خاص", isOn: $isPrivate)
                    Toggle("إظهار الأداء", isOn: $showPerformance)
                    Toggle("إظهار المكتبة", isOn: $showLibrary)
                    Toggle("إظهار الأرشيف", isOn: $showArchive)
                    Toggle("إظهار الأصدقاء", isOn: $showFriends)
                }

                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
            .navigationTitle("تعديل البروفايل")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving { ProgressView() } else { Text("حفظ") }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        let patch: [String: Any] = [
            "bio": bio, "school_name": schoolName, "is_private": isPrivate,
            "show_performance": showPerformance, "show_library": showLibrary,
            "show_archive": showArchive, "show_friends": showFriends,
        ]
        do {
            try await APIClient.shared.updateProfile(patch: patch)
            await onSaved()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
