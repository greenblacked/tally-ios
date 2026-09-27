import Charts
import SwiftUI

struct CategoriesView: View {
    @Environment(BudgetStore.self) private var store
    var onAdd: () -> Void

    private var slices: [CategorySlice] { store.summary.slices }
    private var total: Double { store.summary.expenses }

    var body: some View {
        List {
            Section {
                MonthPicker()
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
            }

            if slices.isEmpty {
                ContentUnavailableView(
                    "No Spending Yet",
                    systemImage: "chart.pie",
                    description: Text("Add an expense to see this month by category.")
                )
                .frame(maxWidth: .infinity, minHeight: 340)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
            } else {
                Section {
                    ZStack {
                        Chart(slices) { slice in
                            SectorMark(
                                angle: .value("Spent", slice.value),
                                innerRadius: .ratio(0.66),
                                angularInset: 1.6
                            )
                            .foregroundStyle(slice.color)
                            .cornerRadius(3)
                        }
                        .chartLegend(.hidden)
                        .accessibilityHidden(true)
                        VStack(spacing: 2) {
                            Text("Spent")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Text(store.money(total))
                                .font(.title3.bold().monospacedDigit())
                        }
                    }
                    .frame(height: 220)
                    .listRowInsets(EdgeInsets())
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Spent \(store.money(total)) this month")
                }

                Section("Breakdown") {
                    ForEach(slices) { slice in
                        HStack(spacing: 12) {
                            CategoryGlyph(name: slice.name)
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(slice.name)
                                        .font(.body)
                                    Spacer()
                                    Text(store.money(slice.value))
                                        .font(.body.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                                ProgressView(value: slice.share)
                                    .tint(slice.color)
                                    .accessibilityHidden(true)
                            }
                        }
                        .padding(.vertical, 4)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(slice.name), \(store.money(slice.value))")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                AddToolbarButton(action: onAdd)
            }
        }
    }
}
