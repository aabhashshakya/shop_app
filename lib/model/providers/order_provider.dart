import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shop_app/utilities/server_response_enum.dart';

import 'cart_provider.dart';

class OrderItem {
  //an order item needs to have these things
  String id; //id is unique
  double totalAmount;
  List<CartItem> allItems;
  final DateTime dateTime;

  OrderItem(
      {@required this.id,
      @required this.totalAmount,
      @required this.allItems,
      @required this.dateTime});

  OrderItem.fromJSON(Map<String, dynamic> decodedJson, String key)
      : id = key,
        totalAmount = decodedJson['totalAmount'],
        //we get a list of Map, the Map can be converted to object, and we get a list of objects like we need
        //EVEN IF WE KNOW IT'S GOING TO BE A LIST OF MAP, PUT <dynamic> EVERYTIME FOR LISTS OTHERWISE
        //U GET ERROR
        allItems = (decodedJson['allItems'] as List<dynamic>)
            .map((item) => CartItem.fromJSON(item))
            .toList(),
        //as the datetime we get from jSON is string , we can parse it to DateTime object when we get it
        dateTime = DateTime.parse(decodedJson['dateTime']);

  Map<String, dynamic> toJSON() => {
        'totalAmount': totalAmount,
        //converting the objects to map so it can be encoded to JSON
        //so we send a list of Maps
        'allItems': allItems.map((cartItem) => cartItem.toJSON()).toList(),
        //convert to Iso8601String as we cant store a DateTime object as JSON, DONT use toString() as it is difficult
        //to parse when receiving it
        'dateTime': dateTime.toIso8601String(),
      };
}

class Order with ChangeNotifier {
  String url =
      'https://shopapp-c9c97-default-rtdb.asia-southeast1.firebasedatabase.app/';
  List<OrderItem> _orders = [];

  String _token; //we need to append token in every http request
  String _userID;

  //WE USED A CONCEPT OF PROXY PROVIDER TO GET THE TOKEN FROM ANOTHER PROVIDER... CHECK OUT main()
  Order(this._token, this._orders, this._userID);

  List<OrderItem> get orders {
    return [..._orders];
  }

  Future<ServerResponse> addOrder(List<CartItem> allItems, double total) async {
    var orderItem = OrderItem(
        id: null,
        totalAmount: total,
        allItems: allItems,
        dateTime: DateTime.now());
    try {
      var response = await http.post(
          Uri.parse(url + '/orders/$_userID.json?auth=$_token'),
          body: jsonEncode(orderItem.toJSON()));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        //inserting at index 0 means, the latest order will be at the first with other orders pushed back
        orderItem.id = jsonDecode(response.body)['name'];
        _orders.insert(0, orderItem);
        notifyListeners();

        return ServerResponse.SUCCESS;
      } else {
        return ServerResponse.ERROR;
      }
    } on SocketException {
      return ServerResponse.NO_INTERNET;
    } catch (e, stacktrace) {
      print('-----------${e.toString()}------------');
      print(stacktrace.toString());
      return ServerResponse.ERROR;
    }
  }

  //WE DON'T USE TRY..CATCH HERE AS WE CALL THIS METHOD IN A DIFFERENT WAY USING A FUTUREBUILDER AS IT ALREADY
  //HAS THAT FUNCTIONALITY AND MUCH MORE
  //CHECK OUT ORDER_SCREEN TO SEE HOW
  Future<ServerResponse> fetchOrders() async {
    var response = await http.get(
      Uri.parse(url + '/orders/$_userID.json?auth=$_token'),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      Map<String, dynamic> decodedOrders = jsonDecode(response.body);

      if (decodedOrders != null) {
        _orders.clear();
      }
      print(decodedOrders);
      decodedOrders?.forEach((key, value) {
        _orders.add(OrderItem.fromJSON(value, key));
      });
      notifyListeners();

      return ServerResponse.SUCCESS;
    } else {
      return ServerResponse.ERROR;
    }
  }
}
