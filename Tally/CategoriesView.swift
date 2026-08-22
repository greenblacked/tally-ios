import Charts
import SwiftUI

struct CategoriesView: View {
    @Environment(BudgetStore.self) private var store

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
                    "No spending yet",
                    systemImage: "chart.pie",
                    description: Text("Add an expense to see this month by category.")
                )
                .listRowBackground(Color.clear)
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
                        VStack(spacing: 2) {
                            Text("Spent")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                            Text(Money.format(total))
                                .font(.title3.weight(.bold).monospacedDigit())
                        }
                    }
                    .frame(height: 220)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .padding(.vertical, 8)
                    .glassEffect(.regular, in: .rect(cornerRadius: 16))
                }

                Section("Breakdown") {
                    ForEach(slices) { slice in
                        HStack(spacing: 12) {
                            CategoryGlyph(name: slice.name)
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(slice.name)
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                    Text(Money.format(slice.value))
                                        .font(.subheadline.monospacedDigit())
                                }
                                GeometryReader { geo in
                                    Capsule()
                                        .fill(Color(.tertiarySystemFill))
                                        .overlay(alignment: .leading) {
                                            Capsule()
                                                .fill(slice.color)
                                                .frame(width: max(6, geo.size.width * slice.share))
                                        }
                                }
                                .frame(height: 4)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Categories")
    }
}
