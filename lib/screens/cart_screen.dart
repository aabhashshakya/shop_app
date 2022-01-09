import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/model/providers/cart_provider.dart';
import 'package:shop_app/model/providers/order_provider.dart';
import 'package:shop_app/utilities/server_response_enum.dart';
import 'package:shop_app/widgets/cart_item.dart';

class CartScreen extends StatefulWidget {
  static const String routeName = 'CartScreen';
  static Route getRoute(RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => CartScreen());
  }

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  var isLoading = false;

  @override
  Widget build(BuildContext context) {
    var cartProvider = Provider.of<Cart>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('My Cart'),
      ),
      body: Column(
        children: [
          Card(
            margin: EdgeInsets.all(15),
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  //since we have used spaceBetween, every widget has equal space in between
                  //but what if we wanted Chip and TExtButton to be on the right and there be more space between the
                  //Text and Chip
                  //That's why we use Spacer() it is invisible but takes all the available space so it pushed the Chip
                  //and the TextBottom to the rightest corner here, and we get our desired result
                  Spacer(),
                  //chip is a compact, VERY rounded corner rectangle that can have avatar, label and background color
                  //used commonly in To: Cc: when sending an email in Gmail, etc
                  Chip(
                    labelPadding: EdgeInsets.only(top: 5, right: 10, bottom: 5),
                    avatar: Icon(
                      Icons.attach_money,
                      color: Colors.green[400],
                      size: 35,
                    ),
                    label: Text(
                      cartProvider.totalAmount.toStringAsFixed(2),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize:
                              Theme.of(context).textTheme.headline6.fontSize),
                    ),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 5.0),
                    child: (isLoading)
                        ? CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.purple,
                          ))
                        : ElevatedButton(
                            //create an order
                            onPressed: (cartProvider.getCartSize > 0)
                                ? () async {
                                    setState(() {
                                      isLoading = true;
                                    });
                                    var scaffoldText;
                                    var response = await Provider.of<Order>(
                                            context,
                                            listen: false)
                                        .addOrder(
                                            cartProvider.cart.values
                                                .toList(), //provide all the cartItems
                                            cartProvider
                                                .totalAmount); // provide the total amount
                                    if (response == ServerResponse.SUCCESS) {
                                      cartProvider
                                          .clearCart(); //clear cart when placing order
                                      scaffoldText =
                                          'Your order has been successfully placed!';
                                    } else if (response ==
                                        ServerResponse.NO_INTERNET) {
                                      scaffoldText =
                                          'Please check your internet connection';
                                    } else {
                                      scaffoldText =
                                          'There was an error placing the order';
                                    }
                                    setState(() {
                                      isLoading = false;
                                    });
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text(scaffoldText),
                                      duration: Duration(seconds: 3),
                                    ));
                                    return;
                                  }
                                : null,
                            child: Text(
                              'ORDER NOW',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            )),
                  )
                ],
              ),
            ),
          ),
          SizedBox(
            height: 20,
          ),
          Expanded(
            child: ListView.builder(
              itemBuilder: (context, index) {
                String cartItemId =
                    cartProvider.cart.values.toList()[index].cartItemID;
                String title = cartProvider.cart.values.toList()[index].title;
                double price = cartProvider.cart.values.toList()[index].price;
                int quantity =
                    cartProvider.cart.values.toList()[index].quantity;
                String imageUrl =
                    cartProvider.cart.values.toList()[index].imageUrl;
                String productID = cartProvider.cart.keys.toList()[index];

                return CartItemWidget(
                  //.values.toList() as cart is a Map
                  id: cartItemId,
                  title: title,
                  price: price,
                  quantity: quantity,
                  imageUrl: imageUrl,
                  productID: productID,
                );
              },
              itemCount: cartProvider.getCartSize,
            ),
          )
        ],
      ),
    );
  }
}
