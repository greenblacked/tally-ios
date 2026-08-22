import SwiftUI

struct TransactionFormView: View {
    @Environment(BudgetStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var editing: Transaction?

    @State private var type: TxType
    @State private var amount: String
    @State private var category: String
    @State private var note: String
    @State private var date: Date
    @State private var confirmDelete = false
    @State private var error: String?

    init(editing: Transaction?) {
        self.editing = editing
        _type = State(initialValue: editing?.type ?? .expense)
        _amount = State(initialValue: editing.map { String($0.amount) } ?? "")
        _category = State(initialValue: editing?.category ?? "Food")
        _note = State(initialValue: editing?.note ?? "")
        _date = State(initialValue: editing.map { Month.parseISO($0.date) } ?? Date())
    }

    private var categories: [String] { CategoryCatalog.names(for: type) }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Type", selection: $type) {
                    ForEach(TxType.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: type) { _, newValue in
                    if !CategoryCatalog.names(for: newValue).contains(category) {
                        category = CategoryCatalog.names(for: newValue)[0]
                    }
                }

                Section {
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.body.monospacedDigit().weight(.semibold))
                    }
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { item in
                            Text(item).tag(item)
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    HStack {
                        Text("Note")
                        TextField("Optional", text: $note)
                            .multilineTextAlignment(.trailing)
                    }
                }

                if editing != nil {
                    Section {
                        Button("Delete Transaction", role: .destructive) {
                            confirmDelete = true
                        }
                    }
                }
            }
            .navigationTitle(editing == nil ? "New Transaction" : "Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editing == nil ? "Add" : "Save") { save() }
                }
            }
            .alert("Check the amount", isPresented: Binding(
                get: { error != nil },
                set: { if !$0 { error = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(error ?? "")
            }
            .confirmationDialog("Delete this transaction?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let editing {
                        store.delete(id: editing.id)
                    }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("\(editing?.note.isEmpty == false ? editing!.note : editing?.category ?? "This item") will be removed.")
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func save() {
        let cleaned = amount.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        guard let value = Double(cleaned), value > 0 else {
            error = "Enter an amount greater than zero."
            return
        }
        let rounded = (value * 100).rounded() / 100
        let item = Transaction(
            id: editing?.id ?? UUID().uuidString,
            type: type,
            amount: rounded,
            category: category,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            date: Month.isoDate(date)
        )
        if editing == nil {
            store.add(item)
        } else {
            store.update(item)
        }
        dismiss()
    }
}

struct GoalFormView: View {
    @Environment(BudgetStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var value: String
    @State private var error: String?

    init() {
        _value = State(initialValue: "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("0", text: $value)
                            .keyboardType(.decimalPad)
                            .font(.title.weight(.semibold).monospacedDigit())
                    }
                } footer: {
                    Text("How much do you want left over at the end of each month?")
                }
            }
            .navigationTitle("Savings Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear {
                if value.isEmpty {
                    value = String(store.savingsGoal)
                }
            }
            .alert("Check the amount", isPresented: Binding(
                get: { error != nil },
                set: { if !$0 { error = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(error ?? "")
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func save() {
        let cleaned = value.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        guard let amount = Double(cleaned), amount > 0 else {
            error = "Enter a savings goal greater than zero."
            return
        }
        store.setGoal((amount * 100).rounded() / 100)
        dismiss()
    }
}
