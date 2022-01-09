import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/model/providers/auth_provider.dart';
import 'package:shop_app/model/providers/cart_provider.dart';
import 'package:shop_app/model/providers/product_provider.dart';
import 'package:shop_app/screens/product_detail_screen.dart';
import 'package:shop_app/utilities/server_response_enum.dart';

class ProductItemWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //we get the product object from the Product Provider
    //we use listen false as we don't need to listen for changes except for one widget i.e favorites button
    //for which we have used a Consumer
    var product = Provider.of<Product>(context, listen: false);
    //cliprrect is easy way to set rounded corners
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: GridTile(
        //Grid tile can be used anywhere but mostly used in grids// Has a header and footer
        child: InkWell(
          onTap: () => Navigator.pushNamed(
              context, ProductDetailScreen.routeName,
              arguments: product.id),
          child: Image.network(
            product.imageUrl,
            fit: BoxFit.cover,
          ),
        ),
        //gridtilebar is versatile with title, leading, trailing, etc.
        footer: GridTileBar(
          backgroundColor: Colors.black.withOpacity(0.6),
          title: Text(
            product.title,
            textAlign: TextAlign.center,
          ),

          //Here only the favorite button needs to listen for changes so we wrap it with a Consumer
          //CONSUMER THIS WAY CAN BE USED TO FINE TUNE ONLY THE WIDGET THAT NEEDS TO REBUILD NOT THE WHOLE WIDGET
          //TREE. IT IS MORE EFFICIENT IF USED THIS WAY
          leading: Consumer<Product>(builder: (context, product, child) {
            return Material(
              color: Colors.transparent,
              //wrap button with Material if animations/splash doesnt work
              child: IconButton(
                splashRadius: 20,
                splashColor: Colors.white,
                icon: Icon(product.isFavorite
                    ? Icons.favorite
                    : Icons.favorite_border),
                color: Theme.of(context).accentColor,
                onPressed: () async {
                  //toggling the favorite property of the product, passing in the auth token
                  var response = await product.toggleFavorite(
                      Provider.of<AuthProvider>(context, listen: false).token,
                      Provider.of<AuthProvider>(context, listen: false).userId);
                  if (response != ServerResponse.SUCCESS) {
                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            'There was an error adding the product to favorites.'),
                        duration: Duration(seconds: 3)));
                  }
                },
              ),
            );
          }),
          trailing: Material(
            color: Colors.transparent,
            //wrap button with Material if animations/splash doesnt work

            child: IconButton(
              splashRadius: 20,
              splashColor: Colors.white,
              icon: Icon(Icons.shopping_cart),
              color: Theme.of(context).accentColor,
              onPressed: () {
                //adding to cart
                Provider.of<Cart>(context, listen: false).addToCart(
                    product.id, product.title, product.price, product.imageUrl);
                //show a SnackBar that it was added to the cart
                //but first remove the current snack bar if showing
                ScaffoldMessenger.of(context).removeCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.title} added to cart'),
                    duration: Duration(seconds: 3),
                    //snackbar action to undo adding the product to card, it removes single quantity of the
                    //item from cart
                    action: SnackBarAction(
                      textColor: Colors.white,
                      label: 'UNDO',
                      onPressed: () => Provider.of<Cart>(context, listen: false)
                          .removeSingleQuantityFromCart(product.id),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  //action when the user clicks UNDO from the snackbar

}
