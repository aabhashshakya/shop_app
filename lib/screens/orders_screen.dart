import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/model/providers/order_provider.dart';
import 'package:shop_app/utilities/server_response_enum.dart';
import 'package:shop_app/widgets/drawer.dart';
import 'package:shop_app/widgets/order_item.dart';

class OrdersScreen extends StatefulWidget {
  static const String routeName = 'OrdersScreen';
  static Route getRoute(RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => OrdersScreen());
  }

  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

//WE USE FUTURE BUILDER HERE
//IT IS HELPFUL TO RENDER THE BODY OF A SCREEN BASED ON A FUTURE OPERATION
//TO ALSO HAS ADDITION FUNCTIONALITY AS ERROR HANDLING, ETC
//WE MOSTLY USE IT WHEN WE NEED TO DISPLAY A LOADING SCREEN WHILE THE ASYNC CALL LOADS THEN SHOW THE
//APPROPRIATE RESULT WHEN IT STOP LOADING
//THIS IS BETTER APPROACH AS WE DON'T NEED TO SET VARIABLES SUCH AS _isLoading=true/false to check loading state

///use this approach of setting the future in the initState() if your app contains other widgets that change
///state of screen like dialogs, etc so that your Future doesn't get called multiple times for every rebuild
///We don't have such widgets here but this is the approach if you do
///IF YOU DON'T HAVE SUCH WIDGETS, THIS WIDGET CAN BE A STATELESS WIDGET, AND JUST SET THE FUTURE OPERATION IN THE
///FUTURE BUILDER'S future: PROPERTY DIRECTLY .this is the advantage of using FutureBuilder as it we don't
///have to make our widget Stateful
class _OrdersScreenState extends State<OrdersScreen> {
  Future _future; //CREATE A FUTURE LIKE THIS
  @override
  void initState() {
    _future = Provider.of<Order>(context, listen: false)
        .fetchOrders(); //ALWAYS BEFORE SUPER() CALL
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MyDrawer(),
      appBar: AppBar(
        title: Text('Your Orders'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _future,
        child: FutureBuilder(
            future: _future,
            builder: (context, dataSnapshot) {
              //if still loading return a Spinner as body
              if (dataSnapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.purple),
                  ),
                );
              } else {
                //if error...
                if (dataSnapshot.hasError ||
                    dataSnapshot.data == ServerResponse.ERROR) {
                  return Center(
                    child: Text('There was an error.'),
                  );
                } else
                  //if done loading and no error, return the widget u want i.e a list view
                  //always Use Consumer as we only want that widget to rebuild
                  return Consumer<Order>(builder: (ctx, orderProvider, child) {
                    return ListView.builder(
                        itemBuilder: (context, index) {
                          //reverse the list to put the latest order on top
                          return OrderItemWidget(
                              orderProvider.orders.reversed.toList()[index]);
                        },
                        itemCount: orderProvider.orders.length);
                  });
              }
            }),
      ),
    );
  }
}
