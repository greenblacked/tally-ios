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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                MonthPicker()
                    .frame(maxWidth: .infinity)

                Picker("Filter", selection: $filter) {
                    Text("All").tag(Optional<TxType>.none)
                    Text("Expenses").tag(Optional.some(TxType.expense))
                    Text("Income").tag(Optional.some(TxType.income))
                }
                .pickerStyle(.segmented)

                if items.isEmpty {
                    VStack(spacing: 10) {
                        Text("Nothing here yet")
                            .font(.headline)
                        Text("Add income or an expense for this month.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Add transaction", action: onAdd)
                            .buttonStyle(.borderedProminent)
                            .padding(.top, 6)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                } else {
                    ForEach(groups, id: \.date) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(Month.parseISO(group.date), format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            VStack(spacing: 0) {
                                ForEach(Array(group.items.enumerated()), id: \.element.id) { index, tx in
                                    Button { onEdit(tx) } label: {
                                        TransactionRow(tx: tx)
                                    }
                                    .buttonStyle(.plain)
                                    if index < group.items.count - 1 {
                                        Divider().padding(.leading, 56)
                                    }
                                }
                            }
                            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Activity")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.body.weight(.bold))
                        .frame(width: 32, height: 32)
                        .foregroundStyle(.white)
                        .background(Color(red: 0, green: 0.48, blue: 1), in: Circle())
                }
                .accessibilityLabel("Add transaction")
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
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if !tx.note.isEmpty {
                    Text(tx.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            Text("\(tx.type == .income ? "+" : "−")\(Money.format(tx.amount))")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(tx.type == .income ? Color(red: 0.20, green: 0.78, blue: 0.35) : Color.primary)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(minHeight: 56)
        .contentShape(Rectangle())
        .accessibilityLabel("Edit \(tx.note.isEmpty ? tx.category : tx.note)")
    }
}
