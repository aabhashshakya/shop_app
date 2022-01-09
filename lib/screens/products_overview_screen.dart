import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/model/providers/cart_provider.dart';
import 'package:shop_app/model/providers/product_list_provider.dart';
import 'package:shop_app/screens/cart_screen.dart';
import 'package:shop_app/utilities/server_response_enum.dart';
import 'package:shop_app/widgets/drawer.dart';
import 'package:shop_app/widgets/products_grid.dart';

class ProductsOverviewScreen extends StatefulWidget {
  static const String routeName = 'ProductsOverviewScreen';
  static Route getRoute(RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => ProductsOverviewScreen());
  }

  @override
  _ProductsOverviewScreenState createState() => _ProductsOverviewScreenState();
}

enum ProductFilter { ShowFavorites, ShowAll }

class _ProductsOverviewScreenState extends State<ProductsOverviewScreen> {
  bool _isFavoritesSelected = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    setState(() {
      _isLoading = true;
    });
    //listen =false is NEED if we use provider in initState()
    Provider.of<ProductListProvider>(context, listen: false)
        .fetchProducts()
        .then((serverResponse) {
      setState(() {
        _isLoading = false;
      });

      switch (serverResponse) {
        case ServerResponse.ERROR:
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('There was some error displaying the products')));
          break;
        case ServerResponse.NO_INTERNET:
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Please check your internet connection.')));
          break;
        default:
          break;
      }
    });
  }

  Widget build(BuildContext context) {
    return ModalProgressHUD(
      opacity: 0.8,
      color: Colors.black,
      inAsyncCall: _isLoading,
      child: Scaffold(
          drawer: MyDrawer(),
          appBar: AppBar(
            title: Text('My Shop'),
            actions: [
              //DOWNLOAD THE BADGES PACKAGE FROM PUB.DEV TO USE BADGES
              //BADGES HERE IS USED TO DISPLAY A COUNT OF HOW MANY CART ITEMS
              InkWell(
                onTap: () {
                  //goto Cart Screen
                  Navigator.pushNamed(context, CartScreen.routeName);
                },
                child: Consumer<Cart>(
                  //consumer provides us wit this noRebuildChild argument that doesn't rebuild upon data changes
                  //this argument is the child property of the Consumer<Cart> i.e the Icon
                  //this method is used for efficiency purposes and is good practice
                  builder: (context, cart, noRebuildChild) => Badge(
                    child:
                        noRebuildChild, //set the child of the Consumer<Cart> to the child of Badge
                    //display the number of cart times in the cart
                    badgeContent: Text(
                      cart.getTotalCartItemsCount.toString(),
                      style: TextStyle(color: Colors.white),
                    ),
                    animationType: BadgeAnimationType.scale,
                    position: BadgePosition.topEnd(top: 2, end: -5),
                  ),
                  child: Icon(
                    //widget that doesn't need to rebuild is child: of Consumer<Cart>
                    Icons.shopping_cart,
                    color: Colors.white,
                  ),
                ),
              ),
              //setting a menu in the AppBar
              PopupMenuButton(
                itemBuilder: (context) {
                  return [
                    PopupMenuItem(
                      child: ListTile(
                        title: Text('Show All'),
                        trailing: _isFavoritesSelected
                            ? null
                            : Icon(
                                Icons.check_box_rounded,
                                color: Colors.green,
                              ),
                      ),
                      value: ProductFilter
                          .ShowAll, //alwasys set value to know which item was selected
                    ),
                    PopupMenuItem(
                      child: ListTile(
                          title: Text('Show Favorites'),
                          trailing: _isFavoritesSelected
                              ? Icon(
                                  Icons.check_box_rounded,
                                  color: Colors.green,
                                )
                              : null),
                      value: ProductFilter.ShowFavorites,
                    )
                  ];
                },
                elevation: 20,
                icon: Icon(Icons.more_vert_outlined),
                onSelected: (selectedValue) {
                  //checking if favorites was selected
                  setState(() {
                    if (selectedValue == ProductFilter.ShowFavorites) {
                      _isFavoritesSelected = true;
                    } else
                      _isFavoritesSelected = false;
                  });
                },
              ),
            ],
          ),
          //REFRESH INDICATOR ALLOWS SWIPE TO REFRESH
          body: RefreshIndicator(
              //this method should returns Future<void> i.e we should return the call or just use async await as
              //using async also returns a Future<void> even if we don't specify the return
              onRefresh: () async {
                await Provider.of<ProductListProvider>(context, listen: false)
                    .fetchProducts();
              },
              child: ProductsGrid(_isFavoritesSelected))),
    );
  }
}
