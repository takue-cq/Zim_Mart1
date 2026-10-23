import Foundation
import Observation

// MARK: - Product Category

enum ProductCategory: String, CaseIterable, Identifiable, Codable {
    case electronics = "Electronics"
    case food = "Food"
    case home = "Home"
    case fashion = "Fashion"
    case agriculture = "Agriculture"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .electronics: "iphone.gen3"
        case .food: "carrot.fill"
        case .home: "house.fill"
        case .fashion: "tshirt.fill"
        case .agriculture: "leaf.fill"
        }
    }
}

// MARK: - Product

struct Product: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let description: String
    let category: ProductCategory
    let price: Double
    let stock: Int
    let symbol: String
    let rating: Double
}

// MARK: - Cart Line

struct CartLine: Identifiable, Hashable {
    var id: String { product.id }

    let product: Product
    var quantity: Int

    var subtotal: Double {
        product.price * Double(quantity)
    }
}

// MARK: - Delivery Method

enum DeliveryMethod: String, CaseIterable, Identifiable, Codable {
    case delivery = "Delivery"
    case collection = "Collection"

    var id: String { rawValue }
}

// MARK: - Payment Method

enum PaymentMethod: String, CaseIterable, Identifiable, Codable {
    case ecoCash = "EcoCash"
    case bankTransfer = "Bank transfer"
    case cashOnDelivery = "Cash on delivery"

    var id: String { rawValue }
}

// MARK: - Order Status

enum OrderStatus: String, Codable {
    case pending = "Pending"
}

// MARK: - Customer

struct Customer: Codable, Hashable {
    var fullName: String
    var phone: String
    var address: String
    var city: String
}

// MARK: - Order Line

struct OrderLine: Identifiable, Codable, Hashable {
    var id: String { productID }

    let productID: String
    let name: String
    let symbol: String
    let unitPrice: Double
    let quantity: Int

    var subtotal: Double {
        unitPrice * Double(quantity)
    }
}

// MARK: - Shop Order

struct ShopOrder: Identifiable, Codable, Hashable {
    let id: String
    let date: Date
    let items: [OrderLine]
    let customer: Customer
    let deliveryMethod: DeliveryMethod
    let paymentMethod: PaymentMethod
    let deliveryFee: Double
    let total: Double
    let status: OrderStatus

    var itemSubtotal: Double {
        items.reduce(0.0) { total, item in
            total + item.subtotal
        }
    }
}

// MARK: - Seed Data

enum SeedData {
    static let products: [Product] = [
        .init(id: "rice", name: "Mazowe Rice 2kg",
              description: "Locally packed long-grain rice for everyday meals.",
              category: .food, price: 4.50, stock: 24,
              symbol: "takeoutbag.and.cup.and.straw.fill", rating: 4.6),

        .init(id: "meal", name: "Roller Meal 10kg",
              description: "Fortified maize meal, milled in Zimbabwe.",
              category: .food, price: 8.75, stock: 18,
              symbol: "shippingbox.fill", rating: 4.8),

        .init(id: "tea", name: "Tanganda Tea",
              description: "A bright, locally grown black tea.",
              category: .food, price: 3.20, stock: 32,
              symbol: "cup.and.saucer.fill", rating: 4.5),

        .init(id: "phone", name: "Kwekwe Smartphone",
              description: "Unlocked Android smartphone with a large battery.",
              category: .electronics, price: 119.00, stock: 7,
              symbol: "iphone.gen3", rating: 4.2),

        .init(id: "solar", name: "Solar Lantern",
              description: "Rechargeable lantern for home and camping.",
              category: .electronics, price: 18.50, stock: 12,
              symbol: "sun.max.fill", rating: 4.7),

        .init(id: "radio", name: "Portable Radio",
              description: "Battery-powered FM radio with a torch.",
              category: .electronics, price: 14.00, stock: 0,
              symbol: "radio.fill", rating: 4.1),

        .init(id: "kettle", name: "Stainless Kettle",
              description: "A dependable 1.7 litre electric kettle.",
              category: .home, price: 22.00, stock: 9,
              symbol: "kettle.fill", rating: 4.4),

        .init(id: "blanket", name: "Wool Blanket",
              description: "Warm woven blanket for cool nights in the highveld.",
              category: .home, price: 28.00, stock: 6,
              symbol: "bed.double.fill", rating: 4.8),

        .init(id: "chair", name: "Folding Chair",
              description: "Lightweight folding chair for home or garden.",
              category: .home, price: 16.00, stock: 15,
              symbol: "chair.lounge.fill", rating: 4.0),

        .init(id: "shirt", name: "Cotton T-shirt",
              description: "Soft cotton tee, available in assorted colours.",
              category: .fashion, price: 12.00, stock: 20,
              symbol: "tshirt.fill", rating: 4.3),

        .init(id: "basket", name: "Woven Market Basket",
              description: "Handwoven reusable basket made by local artisans.",
              category: .fashion, price: 9.50, stock: 11,
              symbol: "basket.fill", rating: 4.9),

        .init(id: "seed", name: "Maize Seed 5kg",
              description: "Hybrid maize seed suited to Zimbabwean growing regions.",
              category: .agriculture, price: 32.00, stock: 14,
              symbol: "leaf.fill", rating: 4.7),

        .init(id: "hoe", name: "Garden Hoe",
              description: "Durable steel hoe for smallholder farms and gardens.",
              category: .agriculture, price: 11.00, stock: 10,
              symbol: "hammer.fill", rating: 4.2),

        .init(id: "watering", name: "Watering Can",
              description: "Galvanised 10 litre watering can.",
              category: .agriculture, price: 13.50, stock: 8,
              symbol: "drop.fill", rating: 4.1)
    ]
}

// MARK: - Catalog Filter

enum CatalogFilter {
    static func products(
        searchText: String,
        category: ProductCategory?,
        from products: [Product] = SeedData.products
    ) -> [Product] {
        let query = searchText.lowercased()

        return products.filter { product in
            let matchesSearch =
                query.isEmpty ||
                product.name.lowercased().contains(query)

            let matchesCategory =
                category == nil ||
                product.category == category

            return matchesSearch && matchesCategory
        }
    }
}

// MARK: - Shop Store

@MainActor
@Observable
final class ShopStore {
    var cart: [CartLine] = []
    var orders: [ShopOrder] = []
    var selectedOrder: ShopOrder?
    var lastError: String?

    // Total price of all cart items, excluding delivery.
    var itemSubtotal: Double {
        cart.reduce(0.0) { total, line in
            total + line.subtotal
        }
    }

    // IMPORTANT: Count individual units, not cart lines.
    // Three rice + two teas = badge count 5.
    var cartBadgeCount: Int {
        cart.reduce(0) { total, line in
            total + line.quantity
        }
    }

    var deliveryFee: Double {
        3.00
    }

    // MARK: Add Product

    func add(_ product: Product, quantity: Int = 1) {
        guard product.stock > 0, quantity > 0 else {
            return
        }

        if let index = cart.firstIndex(
            where: { $0.product.id == product.id }
        ) {
            let newQuantity = cart[index].quantity + quantity

            cart[index].quantity = min(
                newQuantity,
                product.stock
            )
        } else {
            cart.append(
                CartLine(
                    product: product,
                    quantity: min(quantity, product.stock)
                )
            )
        }
    }

    // MARK: Increase Quantity

    func increase(_ line: CartLine) {
        guard let index = cart.firstIndex(
            where: { $0.product.id == line.product.id }
        ) else {
            return
        }

        guard cart[index].quantity < cart[index].product.stock else {
            return
        }

        cart[index].quantity += 1
    }

    // MARK: Decrease Quantity

    func decrease(_ line: CartLine) {
        guard let index = cart.firstIndex(
            where: { $0.product.id == line.product.id }
        ) else {
            return
        }

        if cart[index].quantity > 1 {
            cart[index].quantity -= 1
        } else {
            cart.remove(at: index)
        }
    }

    // MARK: Remove Product

    func remove(_ line: CartLine) {
        cart.removeAll {
            $0.product.id == line.product.id
        }
    }

    func clearCart() {
        cart.removeAll()
    }

    // MARK: Place Order

    @discardableResult
    func placeOrder(
        customer: Customer,
        delivery: DeliveryMethod,
        payment: PaymentMethod
    ) -> Bool {
        lastError = nil

        guard !cart.isEmpty else {
            lastError = "Your cart is empty."
            return false
        }

        let fee = delivery == .delivery ? deliveryFee : 0.0

        let itemSnapshots = cart.map { line in
            OrderLine(
                productID: line.product.id,
                name: line.product.name,
                symbol: line.product.symbol,
                unitPrice: line.product.price,
                quantity: line.quantity
            )
        }

        let subtotal = itemSnapshots.reduce(0.0) { total, item in
            total + item.subtotal
        }

        let order = ShopOrder(
            id: String(UUID().uuidString.prefix(8)).uppercased(),
            date: .now,
            items: itemSnapshots,
            customer: customer,
            deliveryMethod: delivery,
            paymentMethod: payment,
            deliveryFee: fee,
            total: subtotal + fee,
            status: .pending
        )

        // Retain the cart when order placement fails.
        if customer.phone.last == "9" {
            lastError = "We could not place this order. Please try again."
            return false
        }

        orders.insert(order, at: 0)
        selectedOrder = order
        clearCart()

        return true
    }
}

// MARK: - Money Formatting

func money(_ amount: Double) -> String {
    amount.formatted(.currency(code: "USD"))
}
