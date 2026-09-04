// Payment_methods.dart
// All UI has moved to Orders.dart.
// This file re-exports everything so existing imports still work.
export 'Orders.dart' show SubmitOrderPage, PaymentMethod, OrderModel, OrderItem;

// PaymentMethodsPage is an alias for SubmitOrderPage
import 'Orders.dart' show SubmitOrderPage;
typedef PaymentMethodsPage = SubmitOrderPage;









