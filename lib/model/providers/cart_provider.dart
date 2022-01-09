import 'package:flutter/material.dart';
//WE WANNA MANAGE THE CART SEPARATELY INSTEAD OF JUST CREATING LIST OF PRODUCTS IN CART
//HENCE WE HAVE THIS CLASS

//This is how each cart item should look like
class CartItem {
  String cartItemID; //unique id,  NOT THE PRODUCT ID
  //the cartItemID is not the same as the productID as the CartItem is an object of its own with different
  //properties eg. quantity
  String title;
  double price;
  int quantity;
  String imageUrl;

  CartItem(
      {@required this.cartItemID,
      @required this.title,
      @required this.price,
      @required this.quantity,
      @required this.imageUrl});

  CartItem.fromJSON(Map<String, dynamic> decodedJSON)
      : cartItemID = decodedJSON['cartItemID'],
        title = decodedJSON['title'],
        price = decodedJSON['price'],
        quantity = decodedJSON['quantity'],
        imageUrl = decodedJSON['imageUrl'];

  Map<String, dynamic> toJSON() => {
        'cartItemID': cartItemID,
        'title': title,
        'price': price,
        'quantity': quantity,
        'imageUrl': imageUrl,
      };
}

//Our Cart with Provider
class Cart with ChangeNotifier {
  Map<String, CartItem> _cart = {};
  //HERE WE MAP THE CARTITEM TO THE PRODUCT ID THAT IT BELONGS TO I.E the key = productID
  //therefore we can identify which product the cart item belongs to

  Map<String, CartItem> get cart {
    return {..._cart};
  }

  int get getTotalCartItemsCount {
    int count = 0;
    _cart.forEach((key, value) {
      count = count + value.quantity;
    });
    return count;
  }

  int get getCartSize {
    return _cart.length;
  }

  double get totalAmount {
    double total = 0.0;
    _cart.forEach((key, value) {
      total = total + (value.quantity * value.price);
    });
    return total;
  }

  void removeFromCart(String productID) {
    _cart.remove(
        productID); //using product's productID as key makes it easy to remove item from Map
    notifyListeners();
  }

  void removeSingleQuantityFromCart(String productID) {
    if (!_cart.containsKey(productID)) {
      return;
    }
    //if there are many quantities of the CartItem in the cart, delete 1 quantity
    if (_cart[productID].quantity > 1) {
      _cart.update(
          productID,
          (existingValue) => CartItem(
              cartItemID: existingValue.cartItemID,
              title: existingValue.title,
              price: existingValue.price,
              quantity: existingValue.quantity - 1,
              imageUrl: existingValue.imageUrl));
    } else {
      //if there's only 1 quantity of the CartItem in the cart, delete the cartItem altogether from the cart
      removeFromCart(productID);
    }
    notifyListeners();
  }

  //for when order placed, clear the cart
  void clearCart() {
    _cart = {};
    notifyListeners();
  }

  void addToCart(String productID, String title, double price, String imageUrl,
      {int quantity = 1}) {
    //we know the key = productID
    //if that key already exists i.e already in cart, we just increment the quantity i.e update it
    if (_cart.containsKey(productID)) {
      _cart.update(
          productID,
          (existingObject) => CartItem(
              //we only update the property we want to, other properties are the same as before
              //we obtain this existingObject as parameter in the Map.update() method making the above easy to do so
              cartItemID: existingObject.cartItemID,
              title: existingObject.title,
              price: existingObject.price,
              quantity: existingObject.quantity + 1,
              imageUrl: existingObject.imageUrl));
    } else {
      //if the product isn't in the cart, we add it to the map with the productID as the key and then CartItem as
      //the value
      _cart.putIfAbsent(
          productID,
          () => CartItem(
              cartItemID: DateTime.now().toString(), //unique cartItemID
              title: title,
              imageUrl: imageUrl,
              price: price,
              quantity: quantity));
    }
    notifyListeners();
  }
}
