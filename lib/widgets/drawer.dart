import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/model/providers/auth_provider.dart';
import 'package:shop_app/screens/orders_screen.dart';
import 'package:shop_app/screens/products_overview_screen.dart';
import 'package:shop_app/screens/user_products_screen.dart';

class MyDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 20,
      child: Column(
        children: [
          //lol u can add an appBar to anywhere to save time if u lazy to style your own widgets
          AppBar(
            title: Text('Hello fren'),
            centerTitle: true,

            automaticallyImplyLeading:
                false, //means it will never display a back button or hamburger button of AppBar
          ),
          Divider(),
          ListTile(
            onTap: () => Navigator.pushReplacementNamed(
                context, ProductsOverviewScreen.routeName),
            leading: Icon(Icons.shop),
            title: Text(
              'Shop',
              style: Theme.of(context).textTheme.headline6,
            ),
          ),
          ListTile(
            onTap: () =>
                Navigator.pushReplacementNamed(context, OrdersScreen.routeName),
            leading: Icon(Icons.payment),
            title: Text(
              'Orders',
              style: Theme.of(context).textTheme.headline6,
            ),
          ),
          ListTile(
            onTap: () => Navigator.pushReplacementNamed(
                context, UserProductsScreen.routeName),
            leading: Icon(Icons.edit),
            title: Text(
              'Manage Products',
              style: Theme.of(context).textTheme.headline6,
            ),
          ),
          Divider(),
          ListTile(
            onTap: () {
              Navigator.of(context).pop(); //to pop the drawer
              Provider.of<AuthProvider>(context, listen: false).logOut();
            },
            leading: Icon(Icons.exit_to_app),
            title: Text(
              'Log Out',
              style: Theme.of(context).textTheme.headline6,
            ),
          ),
        ],
      ),
    );
  }
}
