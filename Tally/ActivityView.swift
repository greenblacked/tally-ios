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
            ToolbarItem(placement: .topBarTrailing) {
                AddToolbarButton(action: onAdd)
            }
        }
    }
}

struct TransactionRow: View {
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
            Text("\(tx.type == .income ? "+" : "−")\(Money.format(tx.amount))")
                .font(.body.monospacedDigit())
                .foregroundStyle(tx.type == .income ? Color.income : Color.primary)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .accessibilityLabel("\(tx.note.isEmpty ? tx.category : tx.note), \(tx.type == .income ? "income" : "expense") \(Money.format(tx.amount))")
        .accessibilityHint("Opens editor")
    }
}
