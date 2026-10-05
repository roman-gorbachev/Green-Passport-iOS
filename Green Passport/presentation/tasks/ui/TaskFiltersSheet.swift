import SwiftUI

struct TaskFiltersSheet: View {
    let initialFilters: TaskFilters
    let profileCity: String?
    let resultCount: (TaskFilters) -> Int
    let onApply: (TaskFilters) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: TaskFilters

    init(
        initialFilters: TaskFilters,
        profileCity: String?,
        resultCount: @escaping (TaskFilters) -> Int,
        onApply: @escaping (TaskFilters) -> Void
    ) {
        self.initialFilters = initialFilters
        self.profileCity = profileCity
        self.resultCount = resultCount
        self.onApply = onApply
        _draft = State(initialValue: initialFilters)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(selection: $draft.status) {
                        ForEach(TaskStatusFilter.allCases, id: \.self) { status in
                            Text(status.title)
                                .tag(status)
                        }
                    } label: {
                        Text(.status)
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text(.status)
                }
                Section {
                    ForEach(TaskVerification.filterOrder, id: \.self) { verification in
                        checkRow(
                            title: verification.title,
                            subtitle: verification.hint,
                            systemImage: verification.systemImage,
                            isOn: draft.verifications.contains(verification)
                        ) {
                            toggle(verification, in: \.verifications)
                        }
                    }
                } header: {
                    Text(.confirmation)
                }
                Section {
                    Picker(selection: $draft.city) {
                        Text(TaskCityFilter.profileCity.title(profileCity: profileCity))
                            .tag(TaskCityFilter.profileCity)
                        Text(TaskCityFilter.all.title(profileCity: profileCity))
                            .tag(TaskCityFilter.all)
                        ForEach(SupportedCities.all.filter { return $0 != profileCity }, id: \.self) { city in
                            Text(CityName.title(city))
                                .tag(TaskCityFilter.city(city))
                        }
                    } label: {
                        Text(.city)
                    }
                    .pickerStyle(.menu)
                    .tint(Palette.forest)
                }
                Section {
                    ForEach(TaskCategory.allCases, id: \.self) { category in
                        checkRow(
                            title: category.title,
                            subtitle: nil,
                            systemImage: category.systemImage,
                            isOn: draft.categories.contains(category)
                        ) {
                            toggle(category, in: \.categories)
                        }
                    }
                } header: {
                    Text(.category)
                }
            }
            .tint(Palette.forest)
            .safeAreaInset(edge: .bottom) {
                AppButton(title: .showTasksCount(resultCount(draft))) {
                    onApply(draft)
                    dismiss()
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.bottom, Spacing.medium)
            }
            .navigationTitle(Text(.filters))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        draft = TaskFilters()
                    } label: {
                        Text(.reset)
                    }
                    .disabled(draft == TaskFilters())
                }
                ToolbarItem(placement: .topBarTrailing) {
                    CloseButton {
                        dismiss()
                    }
                }
            }
            .animation(.snappy, value: draft)
            .sensoryFeedback(.selection, trigger: draft)
        }
    }

    private func checkRow(
        title: LocalizedStringResource,
        subtitle: LocalizedStringResource?,
        systemImage: String,
        isOn: Bool,
        action: @escaping () -> Void
    ) -> some View {
        return Button(action: action) {
            HStack(spacing: Spacing.small) {
                SymbolTile(systemImage: systemImage, style: isOn ? .prominent : .accent)
                VStack(alignment: .leading, spacing: Spacing.hairline) {
                    Text(title)
                        .foregroundStyle(Color.primary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(Palette.secondaryText)
                    }
                }
                Spacer(minLength: Spacing.small)
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Palette.forest)
                    .opacity(isOn ? 1 : 0)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private func toggle<Value: Hashable>(_ value: Value, in keyPath: WritableKeyPath<TaskFilters, Set<Value>>) {
        if draft[keyPath: keyPath].contains(value) {
            draft[keyPath: keyPath].remove(value)
        } else {
            draft[keyPath: keyPath].insert(value)
        }
    }
}

#Preview {
    TaskFiltersSheet(initialFilters: TaskFilters(), profileCity: "Минск", resultCount: { _ in return 4 }, onApply: { _ in })
}
