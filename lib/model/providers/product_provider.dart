import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shop_app/utilities/server_response_enum.dart';

//We can set a ChangeNotifier in a model class like this to monitor changes in this specific product
//The product_list_provider monitors changes in the products lists but we need to monitor change in the
//isFavorite property of an individual product, so we need to setup Provider for this class as well
class Product with ChangeNotifier {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  bool isFavorite; //this is a local property

  String url =
      'https://shopapp-c9c97-default-rtdb.asia-southeast1.firebasedatabase.app/';
  Product(
      {@required this.id,
      @required this.title,
      @required this.description,
      @required this.price,
      @required this.imageUrl,
      this.isFavorite = false});

  //tp change the favorite status of an individual product
  //need to append token to every http request
  Future<ServerResponse> toggleFavorite(String token, String userID) async {
    //using concept of OPTIMISTIC UPDATING HERE AGAIN
    //where we update the UI first even b4 getting a response from server, then revert the changes if error
    isFavorite = !isFavorite;
    notifyListeners();

    try {
      var response = await http.put(
          Uri.parse(url + '/userFavorites/$userID/$id.json?auth=$token'),
          body: jsonEncode(isFavorite));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ServerResponse.SUCCESS;
      } else {
        //revert changes
        isFavorite = !isFavorite;
        notifyListeners();
        return ServerResponse.ERROR;
      }
    } on SocketException {
      //revert changes
      isFavorite = !isFavorite;
      notifyListeners();
      return ServerResponse.NO_INTERNET;
    }
  }

  //for making JsonConversion easy... this prevents typo and prevents boilerplate when actually encoding/
  //decoding this object to/from json

  ///JUST CONVERT OBJECTS(ENCODING) TO MAP AND MAPS TO OBJECTS(DECODING)

  //FOR DECODING, return a Product Object from the decoded JSON(i.e Map)
  //Product product = Product.fromJSON(jsonDecode(response.body));
  //if you didn't know: jsonDecode(response.body) returns a map, that is the argument for this
  //HERE we set THE PRODUCT ID IS THE UNIQUE KEY THAT FIREBASE CREATES AUTOMATICALLY WHEN INSERTING DATA IN DB
  Product.fromJSON(Map<String, dynamic> jsonDecoded, String keyForID)
      : id = keyForID,
        title = jsonDecoded['title'],
        description = jsonDecoded['description'],
        price = jsonDecoded['price'],
        imageUrl = jsonDecoded['imageUrl'];

  //FOR ENCODING, convert this object to Map which can be used in encodeJSON(....)
  //i.e jsonEncode(product.toJSON());
  Map<String, dynamic> toJSON() => {
        'title': title,
        'description': description,
        'price': price,
        'imageUrl': imageUrl,
      };
}
