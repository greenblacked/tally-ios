import SwiftUI

struct OverviewView: View {
    @Environment(BudgetStore.self) private var store
    var onAdd: () -> Void
    @State private var showGoal = false

    private var summary: MonthSummary { store.summary }
    private var overspent: Bool { summary.remaining < 0 }
    private var progress: Double {
        guard store.savingsGoal > 0 else { return 0 }
        return min(1, max(0, summary.remaining / store.savingsGoal))
    }

    private var goalCopy: String {
        if overspent { return "\(store.money(abs(summary.remaining))) over" }
        if summary.remaining >= store.savingsGoal { return "Goal met" }
        return "\(store.money(max(0, store.savingsGoal - summary.remaining))) to go"
    }

    var body: some View {
        List {
            Section {
                MonthPicker()
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Left this month")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text(store.money(summary.remaining))
                        .font(.largeTitle.bold())
                        .monospacedDigit()
                        .foregroundStyle(overspent ? Color.red : Color.primary)
                        .minimumScaleFactor(0.6)
                }
                .padding(.vertical, 4)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 4, bottom: 8, trailing: 4))
                .listRowSeparator(.hidden)
                .accessibilityElement(children: .combine)
            }

            Section("This Month") {
                // "Saved" used to sit here restating the balance already shown
                // above it. Income and Spent are the two numbers the hero does
                // not give you, so the row carries those and nothing else.
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 0) {
                        StatCell(label: "Income", value: store.money(summary.income), tint: Color.income)
                        Divider()
                        StatCell(label: "Spent", value: store.money(summary.expenses), tint: .red)
                    }
                    // At the accessibility text sizes two cells cannot share a
                    // line legibly, so they stack rather than shrink to nothing.
                    VStack(spacing: 0) {
                        StatCell(label: "Income", value: store.money(summary.income), tint: Color.income)
                        Divider()
                        StatCell(label: "Spent", value: store.money(summary.expenses), tint: .red)
                    }
                }
                .listRowInsets(EdgeInsets())
            }

            Section("Savings") {
                Button { showGoal = true } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Savings Goal")
                                .font(.body)
                                .foregroundStyle(.primary)
                            Text(goalCopy)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            ProgressView(value: overspent ? 0 : progress)
                                .tint(Color.tallyAccent)
                        }
                        Spacer(minLength: 8)
                        Text(store.money(store.savingsGoal))
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens the savings goal editor")

                Picker("Currency", selection: Binding(
                    get: { store.currencyCode },
                    set: { store.setCurrency($0) }
                )) {
                    ForEach(Money.selectableCodes, id: \.self) { code in
                        Text("\(code) — \(Money.name(for: code))").tag(code)
                    }
                }
                .pickerStyle(.navigationLink)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Tally")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                AddToolbarButton(action: onAdd)
            }
        }
        .sheet(isPresented: $showGoal) {
            GoalFormView()
        }
    }
}

private struct StatCell: View {
    var label: String
    var value: String
    var tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.weight(.semibold).monospacedDigit())
                .foregroundStyle(tint)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .accessibilityElement(children: .combine)
    }
}
