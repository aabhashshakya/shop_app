import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shop_app/model/providers/product_provider.dart';
import 'package:shop_app/utilities/server_response_enum.dart';

class ProductListProvider with ChangeNotifier {
  //that's right we're using Firebase as dummy API//we can do that u didn't know???
  //docs: https://firebase.google.com/docs/reference/rest/database
  //calls to this api, automatically give us access to realtime database
  //base url for our API call
  //CHECK OUT THE PRODUCT CLASS WHERE WE INTRODUCE SOME NEW THINGS SO THAT DECODING/ENCODING IT TO JSON
  //IS EASY

  String url =
      'https://shopapp-c9c97-default-rtdb.asia-southeast1.firebasedatabase.app/';

  String _token; //we need to append token in every http request
  String _userID;

  //WE USED A CONCEPT OF PROXY PROVIDER TO GET THE TOKEN FROM ANOTHER PROVIDER... CHECK OUT main()
  ProductListProvider(this._token, this._loadedProducts, this._userID);

  //don't make the actual data accessible in a provider, make it private
  List<Product> _loadedProducts = [];

  //get products form the server db
  Future<ServerResponse> fetchProducts([bool filterByUser = false]) async {
    //filter by user, we send a query to firebase to only get the products owned by the user, WE NEED TO ADD A NEW RULE IN FIREBASE
    //DB TO ENABLE SUCH FILTERING, CHECK THAT OUT
    try {
      http.Response response = filterByUser
          ? await http.get(Uri.parse(url +
              '/products.json?auth=$_token&orderBy="ownerID"&equalTo="$_userID"'))
          : await http.get(Uri.parse(url + '/products.json?auth=$_token'));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _loadedProducts.clear();
        Map<String, dynamic> decodedJson = jsonDecode(response.body);
        //this is of Map<String , Map> type but we write <String,dynamic for more flexibility
        if (decodedJson != null) {
          //make another request to the favorites node of the db to get favorite status of a product id
          http.Response res = await http
              .get(Uri.parse(url + 'userFavorites/$_userID.json?auth=$_token'));
          var favoritesData = jsonDecode(res.body);
          decodedJson.forEach((key, value) {
            //check out Product Provider for more details how we convert the json to object
            _loadedProducts.add(Product.fromJSON(value, key)
              ..isFavorite = (favoritesData == null)
                  ? false
                  : favoritesData[key] ?? false);
          });
          notifyListeners();
        }
        return ServerResponse.SUCCESS;
      } else
        print(response.statusCode);
      print(response.body);
      print('token: $_token');
      return ServerResponse.ERROR;
    } on SocketException {
      return ServerResponse.NO_INTERNET;
    } catch (e, stacktrace) {
      print('-----------${e.toString()}------------');
      print(stacktrace.toString());
      return ServerResponse.ERROR;
    }
  }

  Product getProductById(String id) {
    return _loadedProducts.firstWhere((element) => element.id == id);
  }

  List<Product> getFavoriteProducts() {
    return _loadedProducts.where((element) => element.isFavorite).toList();
  }

  //always create a GETTER to make the data available
  List<Product> get loadedProducts {
    //Dart 2.3 introduced the spread operator (...) and the null-aware spread operator (...?), which provide a
    //concise way to insert multiple elements into a collection.
    return [..._loadedProducts];
    //we don't return the actual list above, but a list that contains the products of that list, so that the original
    //list si not actually directly accessible
    //WE DO THIS SO THAT THE OTHER PARTS OF THE APP CANNOT MODIFY THE LIST
    //WE WANT TO CREATE SEPARATE METHODS BELOW TO ACTUALLY MODIFY THE LIST BELOW THAT OTHER PARTS OF APP CAN CALL
    //you know this....
  }

  Future<ServerResponse> addProduct(Product product) async {
    //add the product to server db

    try {
      http.Response response = await http.post(
          Uri.parse(url + '/products.json?auth=$_token'),
          body: jsonEncode(
              product.toJSON()..putIfAbsent('ownerID', () => _userID)));
      //add the ownerID to the server db as well so we can identify who uploaded the product
      if (response.statusCode >= 200 && response.statusCode < 300) {
        //response.body contains the child name of the new data specified in the POST request which is unique
        //so we can use it as id
        print(response.body);
        Product newProduct = Product(
            id: jsonDecode(response.body)['name'],
            title: product.title,
            description: product.description,
            price: product.price,
            imageUrl: product.imageUrl);
        _loadedProducts.add(newProduct);
        notifyListeners();
        return ServerResponse.SUCCESS;
      }
    } on SocketException {
      return ServerResponse.NO_INTERNET;
    } catch (e, stacktrace) {
      print('-----------${e.toString()}------------');
      print(stacktrace.toString());
      return ServerResponse.ERROR;
    }
    return ServerResponse.ERROR;
  }

  Future<ServerResponse> updateProduct(String id, Product editedProduct) async {
    try {
      var response =
          await http.patch(Uri.parse(url + 'products/$id.json?auth=$_token'),
              body: jsonEncode({
                'title': editedProduct.title,
                'price': editedProduct.price,
                'description': editedProduct.description,
                'imageUrl': editedProduct.imageUrl
              }));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        //finding the index of the edited product and replacing it so the listeners can listen to this change
        //i.e we don't have to call fetchProducts to see the change
        var index = _loadedProducts.indexWhere((element) => element.id == id);
        if (index >= 0) {
          _loadedProducts[index] = editedProduct;
          notifyListeners();
        }
        return ServerResponse.SUCCESS;
      } else
        return ServerResponse.ERROR;
    } on SocketException {
      return ServerResponse.NO_INTERNET;
    } catch (e, stacktrace) {
      print('-----------${e.toString()}------------');
      print(stacktrace.toString());
      return ServerResponse.ERROR;
    }
  }

  Future<ServerResponse> deleteProduct(String id) async {
    //WE USE THE CONCEPT OF OPTIMISTIC UPDATE HERE//This allows for a more responsive user experience.
    //Example : when clicking the up or downvote arrow, the UI reflects the vote immediately,
    //even if the server hasn't successfully processed it yet. The vote will actually be rolled back with
    //an error message if the server fails

    //so here in our case, clicking delete would delete the product from our local list immediately and
    //from the UI, but if the server fails, it's added back to the list and we show error, so the UI is
    //responsive and user experience is good

    //make a copy of the product
    var productToDeleteIndex =
        _loadedProducts.indexWhere((element) => element.id == id);
    var productToDeleteCopy = _loadedProducts[productToDeleteIndex];
    //remove the product first// if error in the server , we add it back again //so better UI experience
    _loadedProducts.removeAt(productToDeleteIndex);
    notifyListeners();

    try {
      var response =
          await http.delete(Uri.parse(url + 'products/$id.json?auth=$_token'));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('product deleted');
        return ServerResponse.SUCCESS;
      } else {
        //add the product back if there was error
        _loadedProducts.insert(productToDeleteIndex, productToDeleteCopy);
        notifyListeners();
        return ServerResponse.ERROR;
      }
    } on SocketException {
      //add the product back if there was error
      _loadedProducts.insert(productToDeleteIndex, productToDeleteCopy);
      notifyListeners();
      return ServerResponse.NO_INTERNET;
    } catch (e, stacktrace) {
      print('-----------${e.toString()}------------');
      print(stacktrace.toString());
      return ServerResponse.ERROR;
    }
  }
}
