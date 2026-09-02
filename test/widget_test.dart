import 'package:electrocitybd1/Front-end/All%20Pages/CART/Cart_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('CartProvider add/update/remove flow works', () async {
    SharedPreferences.setMockInitialValues({});

    final cart = CartProvider();
    await cart.init();

    await cart.addToCart(
      productId: 'p-1',
      name: 'Phone',
      price: 1000,
      imageUrl: 'assets/prod/1.png',
      category: 'Electronics',
      quantity: 2,
    );

    expect(cart.getItemCount(), 2);
    expect(cart.getCartTotal(), 2000);

    await cart.incrementQuantity('p-1');
    expect(cart.getItemCount(), 3);

    await cart.decrementQuantity('p-1');
    expect(cart.getItemCount(), 2);

    await cart.removeFromCart('p-1');
    expect(cart.getItemCount(), 0);
    expect(cart.getCartTotal(), 0);
  });
}
