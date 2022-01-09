import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/model/providers/product_list_provider.dart';
import 'package:shop_app/screens/add_edit_product_screen.dart';
import 'package:shop_app/screens/product_detail_screen.dart';
import 'package:shop_app/utilities/server_response_enum.dart';

class UserProductItemWidget extends StatelessWidget {
  final String id;
  final String title;
  final String imageUrl;

  UserProductItemWidget(this.id, this.title, this.imageUrl);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: () {
            Navigator.of(context)
                .pushNamed(ProductDetailScreen.routeName, arguments: id);
          },
          title: Text(title),
          leading: CircleAvatar(
            backgroundImage: NetworkImage(imageUrl),
          ),
          trailing: Container(
            width: 100,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: Colors.purple,
                  ),
                  onPressed: () {
                    //pass id argument, so we know we're editing a product
                    Navigator.of(context).pushNamed(
                        AddOrEditProductScreen.routeName,
                        arguments: id);
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  onPressed: () async {
                    showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (context) => AlertDialog(
                              contentPadding: const EdgeInsets.all(10),
                              title: Icon(
                                Icons.delete_forever_sharp,
                                color: Colors.red,
                                size: 40,
                              ),
                              content: Text(
                                'Are you sure you want to permanently delete this item?',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16),
                              ),
                              actions: [
                                ElevatedButton(
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                      await deleteProduct(context);
                                    },
                                    child: Text('Yes')),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: Text('No'))
                              ],
                            ));
                  },
                ),
              ],
            ),
          ),
        ),
        Divider()
      ],
    );
  }

  Future<void> deleteProduct(BuildContext context) async {
    ///we stored the ScaffoldMessenger before calling the Provider method as the deletes the product and also
    ///the widget tree is updated as this ListItem is deleted. so if we call .of(context) after this
    ///Provider method we get an error as Flutter doesn't know which context
    ///SO ALWAYS STORE WIDGETS/ANYTHING THAT USE CONTEXT LIKE THIS BEFORE CALLING ANY METHOD THAT AFFECTS THE
    ///WIDGET TREE, ESPECIALLY WHEN THE CODE IN INSIDE AN EVENT i.e as this method is inside onPressed()
    var scaffoldMessenger = ScaffoldMessenger.of(context);
    //delete product
    var response =
        await Provider.of<ProductListProvider>(context, listen: false)
            .deleteProduct(id);
    scaffoldMessenger.removeCurrentSnackBar();

    scaffoldMessenger.showSnackBar(SnackBar(
      content: Text((response == ServerResponse.SUCCESS)
          ? 'The product was successfully deleted'
          : (response == ServerResponse.NO_INTERNET)
              ? 'Please check your internet connection.'
              : 'There was some error in deleting the product.'),
      duration: Duration(seconds: 3),
    ));
  }
}
