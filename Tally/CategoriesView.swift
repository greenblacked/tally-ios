import Charts
import SwiftUI

struct CategoriesView: View {
    @Environment(BudgetStore.self) private var store
    var onAdd: () -> Void

    private var slices: [CategorySlice] { store.summary.slices }
    private var total: Double { store.summary.expenses }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                MonthPicker()

                if slices.isEmpty {
                    VStack(spacing: 8) {
                        Text("No spending yet")
                            .font(.headline)
                        Text("Add an expense to see this month by category.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                } else {
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
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(spacing: 0) {
                        ForEach(Array(slices.enumerated()), id: \.element.id) { index, slice in
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
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            if index < slices.count - 1 {
                                Divider().padding(.leading, 60)
                            }
                        }
                    }
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Categories")
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
