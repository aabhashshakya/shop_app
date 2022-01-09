import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/model/providers/cart_provider.dart';

class CartItemWidget extends StatelessWidget {
  final String id;
  final String title;
  final double price;
  final int quantity;
  final String imageUrl;
  //we use productID to remove that product from cart as we have used that as key in our CartProvider
  final String productID;
  //function that can re-add the item to the cart if the user dismisses it i.e removes it from cart

  CartItemWidget({
    this.id,
    this.title,
    this.price,
    this.quantity,
    this.imageUrl,
    this.productID,
  });

  @override
  Widget build(BuildContext context) {
    ///we stored the Provider here so that it knows which context it needs
    ///in other cases, we can just call Provider whereever we like and so is the case here except for one
    ///issue, we need to have access to Provider after the widget's been dismissed i.e in UNDO event of Snackbar
    ///this wouldn't be a problem as the context is still there as demonstrated by ScaffoldMessenger.of(context)
    ///still shows even after this widget is dismissed, but onPressed(...) within it is an event as can be
    ///triggered at anytime AND IS ERROR PRONE. so if we call Provider.of(context) there there's an error
    ///as Flutter doesn't know which context so we concretely define what the context is here by setting the
    ///Provider. the error prone code is commented in Green like this below
    var cartProvider = Provider.of<Cart>(context, listen: false);

    //Dismissible removes the widget on swipe. It needs Key to work correctly when used with Lists/Grids
    return Dismissible(
      key: ValueKey(
          id), //give a unique ValueKey, here id is unique as it is cart number
      //background is the widget that sits on the background and is visible only when the card is swiped
      background: DismissibleBackground(),
      //making only swipeable from endToStart
      direction: DismissDirection.endToStart,
      //confirmDismiss to show a dialog. we need to return a Future<bool> to confirm/revert dismissal
      confirmDismiss: (direction) {
        //showDialog returns a Future//we need to return true/false for confirmDismiss
        return showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Remove Item?'),
                //use RichText to apply different TextStyle to words in a sentence
                content: RichText(
                  text: TextSpan(
                    text: 'Are you sure want to remove ',
                    //this style will be applied to children but can be overridden
                    style: TextStyle(color: Colors.black, fontSize: 16),
                    children: [
                      TextSpan(
                          text: title,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.red)),
                      TextSpan(
                        text: ' from the cart?',
                      ),
                    ],
                  ),
                ),
                actions: [
                  ElevatedButton(
                      //pop the dialog and return true to confirm Dismiss
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text('Yes')),
                  TextButton(
                      //pop the dialog and return false to revert Dismiss
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('No'))
                ],
              );
            });
      },
      onDismissed: (direction) {
        ///dismisses the widget
        cartProvider.removeFromCart(productID);
        //show snackbar
        ///the context is still there, so we can still see the snackbar
        ///the problem lies only within the event calls such as onTap, onPressed, etc.
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title removed from cart'),
            duration: Duration(seconds: 3),
            //snackbar action to undo adding the product to card, it removes single quantity of the
            //item from cart
            action: SnackBarAction(
              textColor: Colors.white,
              label: 'UNDO',
              //call the function that re-adds the product to the cart/list
              onPressed: () {
                ///ERROR PRONE code that we discussed above
                cartProvider.addToCart(productID, title, price, imageUrl,
                    quantity: quantity);
              },
            ),
          ),
        );
      },

      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 15, vertical: 4),
        child: Padding(
          padding: EdgeInsets.all(5),
          child: ListTile(
            leading: CircleAvatar(
              radius: 30,
              //use FittedBox to make sure the child fits in the parent
              backgroundImage: NetworkImage(imageUrl),
              backgroundColor: Colors.transparent,
            ),
            title: Text(
              title,
              style: Theme.of(context).textTheme.headline6,
            ),
            subtitle: Text('\$$price x $quantity = \$${price * quantity}'),
            trailing: Text('Quantity: $quantity'),
          ),
        ),
      ),
    );
  }
}

//background for our dismissable widget
class DismissibleBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      padding: EdgeInsets.all(20),
      //we align right as our card is dismissible from end to start and the only the right side will be visible
      alignment: Alignment.centerRight,
      color: Colors.red,
      child: Text(
        'REMOVE ITEM',
        style: TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}
