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
        if overspent { return "\(Money.format(abs(summary.remaining))) over" }
        if summary.remaining >= store.savingsGoal { return "Goal met" }
        return "\(Money.format(max(0, store.savingsGoal - summary.remaining))) to go"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                MonthPicker()
                    .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Left this month")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(Money.format(summary.remaining))
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(overspent ? Color.red : Color.primary)
                }

                HStack(spacing: 0) {
                    StatCell(label: "Income", value: Money.format(summary.income), tint: Color(red: 0.20, green: 0.78, blue: 0.35))
                    Divider()
                    StatCell(label: "Spent", value: Money.format(summary.expenses), tint: .red)
                    Divider()
                    StatCell(label: "Saved", value: Money.format(max(0, summary.remaining)), tint: .primary)
                }
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                Button { showGoal = true } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Savings goal")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text(goalCopy)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            ProgressView(value: overspent ? 0 : progress)
                                .tint(Color(red: 0, green: 0.48, blue: 1))
                        }
                        Spacer(minLength: 8)
                        Text(Money.format(store.savingsGoal))
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Tally")
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
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
    }
}
