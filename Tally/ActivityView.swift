import SwiftUI

struct ActivityView: View {
    @Environment(BudgetStore.self) private var store
    var onAdd: () -> Void
    var onEdit: (Transaction) -> Void
    @State private var filter: TxType? = nil

    private var items: [Transaction] {
        let all = store.summary.items
        guard let filter else { return all }
        return all.filter { $0.type == filter }
    }

    private var groups: [(date: String, items: [Transaction])] {
        var map: [String: [Transaction]] = [:]
        var order: [String] = []
        for item in items {
            if map[item.date] == nil {
                order.append(item.date)
                map[item.date] = []
            }
            map[item.date, default: []].append(item)
        }
        return order.map { (date: $0, items: map[$0] ?? []) }
    }

    var body: some View {
        List {
            Section {
                MonthPicker()
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
            }

            Section {
                Picker("Filter", selection: $filter) {
                    Text("All").tag(Optional<TxType>.none)
                    Text("Expenses").tag(Optional.some(TxType.expense))
                    Text("Income").tag(Optional.some(TxType.income))
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                .accessibilityLabel("Filter transactions")
            }

            if items.isEmpty {
                ContentUnavailableView {
                    Label("Nothing Here Yet", systemImage: "list.bullet")
                } description: {
                    Text("Add income or an expense for this month.")
                } actions: {
                    Button("Add Transaction", systemImage: "plus", action: onAdd)
                }
                .frame(maxWidth: .infinity, minHeight: 340)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
            } else {
                ForEach(groups, id: \.date) { group in
                    Section {
                        ForEach(group.items) { tx in
                            Button { onEdit(tx) } label: {
                                TransactionRow(tx: tx)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    store.delete(id: tx.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    } header: {
                        Text(Month.parseISO(group.date), format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            // Swiping a row away is a single gesture with no confirmation, so
            // the way back has to be visible rather than a shake-to-undo secret.
            ToolbarItem(placement: .topBarLeading) {
                Button("Undo", systemImage: "arrow.uturn.backward") {
                    store.undoDelete()
                }
                .disabled(store.lastDeleted == nil)
                .accessibilityLabel("Undo delete")
            }
            ToolbarItem(placement: .topBarTrailing) {
                AddToolbarButton(action: onAdd)
            }
        }
        // A stale undo from three screens ago is worse than none.
        .onDisappear { store.clearUndo() }
    }
}

struct TransactionRow: View {
    // Reads the store so the row re-renders when the currency changes.
    @Environment(BudgetStore.self) private var store
    var tx: Transaction

    var body: some View {
        HStack(spacing: 12) {
            CategoryGlyph(name: tx.category)
            VStack(alignment: .leading, spacing: 2) {
                Text(tx.note.isEmpty ? tx.category : tx.note)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if !tx.note.isEmpty {
                    Text(tx.category)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            Text("\(tx.type == .income ? "+" : "−")\(store.money(tx.amount))")
                .font(.body.monospacedDigit())
                .foregroundStyle(tx.type == .income ? Color.income : Color.primary)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .accessibilityLabel("\(tx.note.isEmpty ? tx.category : tx.note), \(tx.type == .income ? "income" : "expense") \(store.money(tx.amount))")
        .accessibilityHint("Opens editor")
    }
}
