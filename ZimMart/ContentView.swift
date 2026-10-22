import SwiftUI

struct ContentView: View {
    @State private var store = ShopStore()

    var body: some View {
        MainTabView()
            .environment(store)
            .tint(Color(red: 0.12, green: 0.42, blue: 0.30))
    }
}

struct MainTabView: View {
    @Environment(ShopStore.self) private var store

    var body: some View {
        TabView {
            NavigationStack { ProductListView() }
                .tabItem { Label("Shop", systemImage: "storefront") }
            NavigationStack { CartView() }
                .tabItem { Label("Cart", systemImage: "cart") }
                .badge(store.cartBadgeCount == 0 ? 0 : store.cartBadgeCount)
            NavigationStack { OrderHistoryView() }
                .tabItem { Label("Orders", systemImage: "shippingbox") }
        }
    }
}

struct ProductListView: View {
    @State private var searchText = ""
    @State private var selectedCategory: ProductCategory?
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    private var matchingProducts: [Product] { CatalogFilter.products(searchText: searchText, category: selectedCategory) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ZimCart").font(.largeTitle.bold())
                        Text("Good finds, close to home").foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "sun.max.fill").font(.title).foregroundStyle(.orange)
                }
                TextField("Search products", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        categoryChip(nil, title: "All")
                        ForEach(ProductCategory.allCases) { category in categoryChip(category, title: category.rawValue) }
                    }
                }
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(matchingProducts) { product in
                        NavigationLink(value: product) { ProductCard(product: product) }
                            .buttonStyle(.plain)
                    }
                }
                if matchingProducts.isEmpty {
                    ContentUnavailableView("No products found", systemImage: "magnifyingglass", description: Text("Try another search or category."))
                }
            }
            .padding()
        }
        .navigationDestination(for: Product.self) { product in ProductDetailView(product: product) }
        .navigationBarHidden(true)
    }

    private func categoryChip(_ category: ProductCategory?, title: String) -> some View {
        Button { selectedCategory = category } label: {
            Text(title).font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14).padding(.vertical, 9)
                .background(selectedCategory == category ? Color.green.opacity(0.18) : Color(.secondarySystemBackground), in: Capsule())
        }.foregroundStyle(.primary)
    }
}

struct ProductCard: View {
    let product: Product
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 16).fill(Color.green.opacity(0.10)).frame(height: 112)
                Image(systemName: product.symbol).font(.system(size: 42)).foregroundStyle(.green).frame(maxWidth: .infinity, maxHeight: .infinity)
                if product.stock == 0 { Text("Sold out").font(.caption.bold()).padding(6).background(.white, in: Capsule()).padding(7) }
            }
            Text(product.name).font(.headline).lineLimit(2).frame(height: 42, alignment: .topLeading)
            HStack { Text(money(product.price)).font(.subheadline.bold()); Spacer(); Label(String(format: "%.1f", product.rating), systemImage: "star.fill").font(.caption).foregroundStyle(.orange) }
        }
        .padding(10).background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18))
    }
}

struct ProductDetailView: View {
    let product: Product
    @Environment(ShopStore.self) private var store
    @State private var quantity = 1
    @State private var added = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 24).fill(Color.green.opacity(0.10))
                Image(systemName: product.symbol).font(.system(size: 84)).foregroundStyle(.green)
            }.frame(height: 240)
            Text(product.category.rawValue.uppercased()).font(.caption.bold()).tracking(1.2).foregroundStyle(.green)
            Text(product.name).font(.largeTitle.bold())
            Text(product.description).foregroundStyle(.secondary)
            HStack { Text(money(product.price)).font(.title2.bold()); Spacer(); Text(product.stock > 0 ? "\(product.stock) in stock" : "Out of stock").foregroundStyle(product.stock > 0 ? .green : .red) }
            HStack {
                Button { quantity = max(1, quantity - 1) } label: { Image(systemName: "minus.circle.fill").font(.title2) }
                Text("\(quantity)").font(.headline).frame(minWidth: 36)
                Button { if product.stock > quantity { quantity += 1 }} label: { Image(systemName: "plus.circle.fill").font(.title2) }
                Spacer()
                Text("Stock limit \(product.stock)").font(.caption).foregroundStyle(.secondary)
            }
            Button {
                store.add(product, quantity: quantity)
                added = true
            } label: { Label(added ? "Added to cart" : "Add to cart", systemImage: added ? "checkmark" : "cart.badge.plus").frame(maxWidth: .infinity).padding() }
                .buttonStyle(.borderedProminent).disabled(product.stock == 0)
            Spacer()
        }
        .padding()
        .navigationTitle("Product")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CartView: View {
    @Environment(ShopStore.self) private var store

    var body: some View {
        Group {
            if store.cart.isEmpty {
                ContentUnavailableView("Your cart is empty", systemImage: "cart", description: Text("Browse the shop and add something you like."))
            } else {
                List {
                    ForEach(store.cart) { line in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: line.product.symbol).font(.title2).foregroundStyle(.green).frame(width: 42, height: 48)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(line.product.name).font(.headline)
                                Text(money(line.product.price * Double(line.quantity + 1))).font(.subheadline.bold())
                                HStack(spacing: 14) {
                                    Button { store.decrease(line) } label: { Image(systemName: "minus.circle") }
                                    Text("\(line.quantity)").monospacedDigit()
                                    Button { store.increase(line) } label: { Image(systemName: "plus.circle") }
                                }.buttonStyle(.plain)
                            }
                            Spacer()
                            Button(role: .destructive) { store.remove(line) } label: { Image(systemName: "trash") }
                        }.padding(.vertical, 7)
                    }
                    Section {
                        HStack { Text("Subtotal"); Spacer(); Text(money(store.itemSubtotal)).bold() }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    NavigationLink { CheckoutView() } label: { Text("Continue to checkout").frame(maxWidth: .infinity).padding() }
                        .buttonStyle(.borderedProminent).padding()
                }
            }
        }
        .navigationTitle("Your Cart (\(store.cart.count))")
    }
}

struct CheckoutView: View {
    @Environment(ShopStore.self) private var store
    @State private var name = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var city = "Harare"
    @State private var delivery: DeliveryMethod = .delivery
    @State private var payment: PaymentMethod = .ecoCash
    @State private var showConfirmation = false
    @State private var alertMessage: String?

    private var formIsValid: Bool {
        let basicDetails = !name.isEmpty && !phone.isEmpty
        return basicDetails && !address.isEmpty
    }

    var body: some View {
        Form {
            Section("Delivery method") {
                Picker("Method", selection: $delivery) { ForEach(DeliveryMethod.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented)
            }
            Section("Customer details") {
                TextField("Full name", text: $name)
                TextField("Phone number", text: $phone).keyboardType(.phonePad)
                if delivery == .delivery {
                    TextField("Street address", text: $address)
                    Picker("City", selection: $city) { ForEach(["Harare", "Bulawayo", "Mutare", "Gweru", "Masvingo", "Victoria Falls"], id: \.self) { Text($0) } }
                }
            }
            Section("Payment") {
                Picker("Payment method", selection: $payment) { ForEach(PaymentMethod.allCases) { Text($0.rawValue).tag($0) } }
            }
            Section("Order summary") {
                HStack { Text("Items"); Spacer(); Text(money(store.itemSubtotal)) }
                HStack { Text("\(delivery.rawValue) fee"); Spacer(); Text(money(delivery == .delivery ? 4 : 0)) }
                HStack { Text("Total").bold(); Spacer(); Text(money(store.itemSubtotal + store.deliveryFee)).bold() }
            }
            Section {
                Button("Place order") { submit() }
                    .frame(maxWidth: .infinity).disabled(!formIsValid || store.cart.isEmpty)
            }
        }
        .navigationTitle("Checkout")
        .alert("Order update", isPresented: Binding(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })) {
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: { Text(alertMessage ?? "") }
        .sheet(isPresented: $showConfirmation) {
            if let order = store.selectedOrder { NavigationStack { OrderConfirmationView(order: order) } }
        }
    }

    private func submit() {
        let customer = Customer(fullName: name, phone: phone, address: delivery == .delivery ? address : "", city: city)
        if store.placeOrder(customer: customer, delivery: delivery, payment: .ecoCash) {
            showConfirmation = true
        } else {
            alertMessage = store.lastError
        }
    }
}

struct OrderConfirmationView: View {
    let order: ShopOrder
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.seal.fill").font(.system(size: 70)).foregroundStyle(.green)
            Text("Order placed!").font(.largeTitle.bold())
            Text("Thanks, \(order.customer.fullName). Your order is pending.").multilineTextAlignment(.center).foregroundStyle(.secondary)
            VStack(spacing: 10) {
                HStack { Text("Order number"); Spacer(); Text(order.id).fontWeight(.semibold) }
                HStack { Text("Items"); Spacer(); Text(money(order.itemSubtotal)) }
                HStack { Text("Delivery"); Spacer(); Text(money(order.deliveryFee)) }
                Divider()
                HStack { Text("Total").bold(); Spacer(); Text(money(order.total)).bold() }
            }.padding().background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                    Button("Continue shopping") { dismiss() }.buttonStyle(.borderedProminent)
            Spacer()
        }.padding().padding(.top, 30)
    }
}

struct OrderHistoryView: View {
    @Environment(ShopStore.self) private var store
    var body: some View {
        Group {
            if store.orders.isEmpty {
                ContentUnavailableView("No orders yet", systemImage: "shippingbox", description: Text("Your completed checkouts will appear here."))
            } else {
                List(store.orders) { order in
                    NavigationLink(value: order) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack { Text("#\(order.id)").font(.headline); Spacer(); Text(order.status.rawValue).font(.caption.bold()).foregroundStyle(.orange) }
                            HStack { Text(order.date, style: .date); Spacer(); Text(money(order.total)).bold() }.font(.subheadline).foregroundStyle(.secondary)
                        }.padding(.vertical, 5)
                    }
                }
            }
        }
        .navigationTitle("Orders")
        .navigationDestination(for: ShopOrder.self) { OrderDetailView(order: $0) }
    }
}

struct OrderDetailView: View {
    let order: ShopOrder
    var body: some View {
        List {
            Section("Order \(order.id)") {
                LabeledContent("Status", value: order.status.rawValue)
                LabeledContent("Date", value: order.date.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Payment", value: order.paymentMethod.rawValue)
                LabeledContent("Delivery", value: order.deliveryMethod.rawValue)
                if !order.customer.address.isEmpty { LabeledContent("Address", value: "\(order.customer.address), \(order.customer.city)") }
            }
            Section("Items") {
                ForEach(order.items) { item in
                    HStack {
                        Image(systemName: item.symbol).foregroundStyle(.green)
                        VStack(alignment: .leading) { Text(item.name); Text("Qty \(item.quantity) × \(money(item.unitPrice))").font(.caption).foregroundStyle(.secondary) }
                        Spacer(); Text(money(item.subtotal)).bold()
                    }
                }
            }
            Section {
                LabeledContent("Items", value: money(order.itemSubtotal))
                LabeledContent("Delivery", value: money(order.deliveryFee))
                LabeledContent("Total", value: money(order.total)).fontWeight(.bold)
            }
        }.navigationTitle("Order details")
    }
}

#Preview {
    ContentView()
}
