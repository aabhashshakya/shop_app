import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shop_app/model/providers/order_provider.dart';

class OrderItemWidget extends StatefulWidget {
  final OrderItem orderItem;

  OrderItemWidget(this.orderItem);

  @override
  _OrderItemWidgetState createState() => _OrderItemWidgetState();
}

class _OrderItemWidgetState extends State<OrderItemWidget> {
  var _cardIsExpanded = false;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            child: Text(
              'Order# ${widget.orderItem.id}',
              style: Theme.of(context).textTheme.headline6,
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            title: Text(
              '\$${widget.orderItem.totalAmount}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            //Intl package helps to format date/time, locale , etc.
            subtitle: Text(intl.DateFormat('dd-MM-yyyy')
                .add_jm() //add_jm() adds am/pm to time
                .format(widget.orderItem.dateTime)),

            //We have a expand button which when pressed, expands this order item card so we can view more info
            trailing: IconButton(
              icon: Icon(
                  !_cardIsExpanded ? Icons.expand_more : Icons.expand_less),
              onPressed: () {
                setState(() {
                  _cardIsExpanded = !_cardIsExpanded;
                });
              },
            ),
          ),
          //WE CAN ADD THIS IF(..) INSIDE OF A LIST TO ADD ITEMS(WIDGET) TO THE LIST IF THAT CONDITION IS TRUE
          //SO HERE CONTAINER IS ADDED/REMOVED UPON THE ABOVE BUTTON PRESS
          //THIS CONTAINER IS GOING TO HAVE SHOW INFO ABOUT THE ORDER like items in the order
          if (_cardIsExpanded)
            Container(
              height: min(widget.orderItem.allItems.length * 20.0 + 30, 180),
              //we do this mumbo-jumbo above for height, as we don't want our container to be too big if less
              //items in the cart//the max height is 180 for this container
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              child: ListView.builder(
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.orderItem.allItems[index].title,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${widget.orderItem.allItems[index].quantity} x \$${widget.orderItem.allItems[index].price}',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        )
                      ],
                    ),
                  );
                },
                itemCount: widget.orderItem.allItems.length,
              ),
            )
        ],
      ),
    );
  }
}
