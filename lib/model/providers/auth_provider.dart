import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_app/utilities/server_response_enum.dart';

const String API_KEY = 'AIzaSyBQ06PqnQsu1Lx0m9d8b3CVBiiKBkD4OkA';

//API KEY is in firebase console
//logging in using API, not using Firebase services like FirebaseAuth
class AuthProvider with ChangeNotifier {
  String _token; //TOKEN EXPIRES AFTER 1 HOUR//it is how it is using API
  DateTime _expiryDate;
  String _userId;

  bool get isAuth {
    return _token != null; //if null, isAuth=false, if not null, isAuth = true
  }

  String get userId => _userId;

  String get token {
    //checking if token exists and is still valid
    if (_expiryDate != null &&
        _expiryDate.isAfter(DateTime.now()) &&
        _token != null) {
      return _token;
    }
    return null;
  }

  Future<ServerResponse> signup(String email, String password) async {
    var url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$API_KEY');
    return await _authenticate(url, email, password);
  }

  Future<ServerResponse> login(String email, String password) async {
    var url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$API_KEY');
    return await _authenticate(url, email, password);
  }

  Future<ServerResponse> _authenticate(
      Uri url, String email, String password) async {
    try {
      final response = await http.post(url,
          body: jsonEncode({
            'email': email,
            'password': password,
            'returnSecureToken': true //needed always
          }));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        var data = jsonDecode(response.body);
        _token = data['idToken'];
        _userId = data['localId'];
        _expiryDate = DateTime.now().add(Duration(
            seconds: int.parse(data[
                'expiresIn']))); //expiresIn is in seconds(but in string, so parse it), adding it gives expiry date time

        autoLogOut(); //WHEN USER IS LOGGED IN, CALL THIS SO THE TIMER IS STARTED//user is logged out automatically when the timer
        //expires
        notifyListeners();

        //STORE THE TOKEN IN SHARED PREFERENCES FOR AUTO LOGIN AFTER QUITTING APP//it is async
        final prefs = await SharedPreferences.getInstance();
        //if you want to store complex data in SharedPrefereneces, you can use jsonEncode as JSON data is always a String
        var userData = jsonEncode({
          'token': _token,
          'userID': _userId,
          'expiryDate': _expiryDate
              .toIso8601String() //cant store objects remember (it was a DateTime object)
        });
        prefs.setString('userData', userData);
        print(prefs.getString('userData'));
        return ServerResponse.SUCCESS;
      } else {
        return ServerResponse.ERROR;
      }
    } on SocketException {
      return ServerResponse.NO_INTERNET;
    } catch (e, stacktrace) {
      print(e.toString());
      print(stacktrace.toString());
      return ServerResponse.ERROR;
    }
  }

  //call this in main
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      print('AutoLogin failed. Doesnt have user data');
      return false;
    }
    final extractedUserData = jsonDecode(prefs.getString('userData'));
    if (DateTime.parse(extractedUserData['expiryDate'])
        .isBefore(DateTime.now())) {
      print('AutoLogin failed. token has expired');
      return false;
    } else {
      print('AutoLogin succeeded.');
      //auto log in user //just set the userData and it works as login even if offline
      _token = extractedUserData['token'];
      _userId = extractedUserData['userID'];
      _expiryDate = DateTime.parse(extractedUserData['expiryDate']);
      autoLogOut();
      notifyListeners();
      return true;
    }
  }

  //lol this stupid, but works, using FirebaseAuth SDK is much convenient here, lol y did I even use the API to handle auth??? XD XD
  Future<void> logOut() async {
    _token = null;
    _userId = null;
    _expiryDate = null;
    _timer
        ?.cancel(); //cancel the timer// when user logs out manually timer is still set, so we need to cancel it
    final prefs = await SharedPreferences.getInstance();
    prefs
        .clear(); //CLEAR THE SHARED PREFERENCES TO REMOVE THE AUTOLOGIN FEATURE WHEN USER LOGS OUT
    notifyListeners();
  }

  Timer _timer;
  void autoLogOut() {
    //log users out when the user expires
    //timer allows us to execute a function when the timer expires
    if (_timer != null) {
      _timer.cancel(); //cancel current timer if exists
    }
    _timer = Timer(
        Duration(seconds: _expiryDate.difference(DateTime.now()).inSeconds),
        () => logOut());
  }
}
