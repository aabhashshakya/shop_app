import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/model/providers/product_list_provider.dart';
import 'package:shop_app/model/providers/product_provider.dart';
import 'package:shop_app/widgets/product_item.dart';

class ProductsGrid extends StatelessWidget {
  final bool _isFavoritesSelected;
  ProductsGrid(this._isFavoritesSelected);
  @override
  Widget build(BuildContext context) {
    //filtering for favorite products
    var loadedProducts = _isFavoritesSelected
        ? Provider.of<ProductListProvider>(context).getFavoriteProducts()
        : Provider.of<ProductListProvider>(context).loadedProducts;
    return GridView.builder(
        itemCount: loadedProducts.length,
        padding: const EdgeInsets.all(10),
        //fixedCrossAxisExtent means we can define that we can have certain amounts of columns
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1 / 1, //it is basically width/height
            crossAxisSpacing: 10, //spacing between columns
            mainAxisSpacing: 10), //spacing between rows
        itemBuilder: (ctx, index) {
          //SETTING UP PROVIDER FOR EACH PRODUCT in the list TO MONITOR ITS isFavorite STATUS
          //ALWAYS USE .value when using providers inside of ListViews/GridViews as they recycle the widgets when
          //scrolling and if we not use the value: property, we get errors as the provider is bound to the widget
          //and not the value
          //of course this Provider.value syntax can be use elsewhere as well if we don't want to use the create:
          //property or have no use for context i.e create: (context) => Example().. we can skip this boilerplate
          return ChangeNotifierProvider<Product>.value(
            //we return the product form the product list
            value: loadedProducts[index],
            child:
                ProductItemWidget(), //each ProductItemWidgets gets its own product provider// no need to pass
            //index as argument
          );
        });
  }
}
