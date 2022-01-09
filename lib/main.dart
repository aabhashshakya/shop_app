import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/model/providers/auth_provider.dart';
import 'package:shop_app/model/providers/product_list_provider.dart';
import 'package:shop_app/screens/auth_screen.dart';
import 'package:shop_app/screens/products_overview_screen.dart';
import 'package:shop_app/utilities/my_routes.dart';

import 'model/providers/cart_provider.dart';
import 'model/providers/order_provider.dart';

void main() {
  runApp(ShopApp());
}

class ShopApp extends StatelessWidget {
  const ShopApp({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
          //a proxy provider is a provider that depends on another provider
          //used in situation when change in one provider should yield a change in another provider or when we need to access one
          //provider in another provider
          //we can have access to the super provider within the update() method
          //update() is called whenever there is a change in the AuthProvider
          //update() method gives a previous state of our ProductListProvider if we want to keep some things constant i.e in this case
          //the list of products everytime update() occurs//use the provider's CONSTRUCTOR to do so
          ChangeNotifierProxyProvider<AuthProvider, ProductListProvider>(
            create: (context) =>
                ProductListProvider('', [], ''), //create() using empty values
            update: (context, authProvider, previousProductListProvider) {
              return ProductListProvider(
                  authProvider.token,
                  previousProductListProvider.loadedProducts == null
                      ? []
                      : previousProductListProvider.loadedProducts,
                  authProvider.userId);
              //we don't want our list to be updated everytime, so we assign the list that was in the previous state
            },
          ),
          ChangeNotifierProvider<Cart>(create: (_) => Cart()),
          ChangeNotifierProxyProvider<AuthProvider, Order>(
              create: (context) =>
                  Order('', [], ''), //create() using empty values
              update: (context, authProvider, previousOrderProvider) {
                return Order(
                    authProvider.token,
                    previousOrderProvider.orders == null
                        ? []
                        : previousOrderProvider.orders,
                    authProvider.userId);
              }),
        ],
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) => MaterialApp(
            key: UniqueKey(),
            theme: ThemeData(
              primaryColor: Colors.purple,
              accentColor: Colors.red,
              fontFamily: 'Lato',
              snackBarTheme: SnackBarThemeData(
                  backgroundColor: Colors.teal, elevation: 20),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.purple),
                  overlayColor:
                      MaterialStateProperty.all(Colors.black.withOpacity(0.2)),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: ButtonStyle(
                    overlayColor: MaterialStateProperty.all(
                        Colors.purple.withOpacity(0.4)),
                    foregroundColor: MaterialStateProperty.all(Colors.purple)),
              ),
            ),
            //use a Key for MaterialApp for this to work while the app is running, i.e calling logOut
            //should trigger this again and switch to home to AuthScreen//without Key, this condition is only tested for the
            //1st time the app runs
            //NORMALLY DON'T DO THIS JUST NAVIGATE WHEN LOGGING OUT, but here we do it anyways
            home: (authProvider.isAuth)
                ? ProductsOverviewScreen()
                //below method tries auto login, it is async so we show a spinner
                //that method modifies the isAuth value if it was successful and this builder runs again and the isAuth is true so
                //we log in, if that method fails, we show the AuthScreen
                : FutureBuilder(
                    future: authProvider.tryAutoLogin(),
                    builder: (context, dataSnapshot) {
                      if (dataSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      return AuthScreen();
                    }),
            onGenerateRoute: MyRoutes.onGenerateRoute,
          ),
        ));
  }
}
