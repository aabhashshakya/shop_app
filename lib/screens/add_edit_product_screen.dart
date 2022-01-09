import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/model/providers/product_list_provider.dart';
import 'package:shop_app/model/providers/product_provider.dart';
import 'package:shop_app/utilities/server_response_enum.dart';

//HERE WE USE FORMS TO HANDLE USER INPUT WHICH IS THE BEST WAY TO INPUT AND VALIDATE INPUT
class AddOrEditProductScreen extends StatefulWidget {
  static const String routeName = 'AddOrEditProductScreen';
  static Route getRoute(RouteSettings settings) {
    return MaterialPageRoute(
        builder: (_) => AddOrEditProductScreen(settings.arguments));
  }

  final String productIDToEdit;

  AddOrEditProductScreen(this.productIDToEdit);

  @override
  _AddOrEditProductScreenState createState() => _AddOrEditProductScreenState();
}

class _AddOrEditProductScreenState extends State<AddOrEditProductScreen> {
  //We need focus node for our text fields to switch focus to them
  //for eg. when the user presses the next button on keyboard from one textfield then to go to the next textfield
  //ALWAYS DISPOSE FOCUSNODE() IN dispose()
  final _priceFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  String imageUrl;
  //to get the value in the imageUrl textfield and use it to preview image when the focus changes away from it
  final _imageUrlTextController = TextEditingController();

  final _imageUrlFocusNode = FocusNode();

  //we need to create a Global key for the Form() widget so we can access it outside the code as well
  //GlobalKeys have two uses: they allow widgets to change parents anywhere in your app without losing state,
  //or they can be used to access information about another widget in a completely different part of the widget
  //tree.
  var _formKey = GlobalKey<FormState>();

  //Initial values for the form text fields
  /// these initial values will be change in the initState() methods to be replaced by the existing product's values
  /// if we're passed an productID, meaning we're editing a product, not adding one **/
  Map<String, String> initValues = {
    'title': '',
    'description': '',
    'price': ''
  };

  //Product to add/edit. the form data will be updated in this product
  Product _productToAddOrEdit;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //we also want to load the image when the focus changes from the imageUrl textfield so...
    _imageUrlFocusNode.addListener(previewImageWhenFocusChange);
    //ALWAYS DISPOSE THE LISTENER AS WELL

    /** IMPORTANT */
    //CHECK IF AN PRODUCT ID WAS PASSED.
    if (widget.productIDToEdit != null) {
      //IF YES, WE ARE EDITING THE PRODUCT
      _productToAddOrEdit =
          Provider.of<ProductListProvider>(context, listen: false)
              .getProductById(widget.productIDToEdit);
      //SETTING THE INITIAL VALUES OF THE TEXT FIELDS TO THE EXISTING VALUES OF THE PRODUCT
      initValues['title'] = _productToAddOrEdit.title;
      initValues['description'] = _productToAddOrEdit.description;
      initValues['price'] = _productToAddOrEdit.price.toString();
      //you cant use both a controller and an initialValue in a TextField
      //so initialize the initial value in the controller itself like this
      _imageUrlTextController.text = _productToAddOrEdit.imageUrl;
      //for image preview
      imageUrl = _productToAddOrEdit.imageUrl;
    } else
    //IF NO, WE'RE ADDING A NEW PRODUCT
    {
      _productToAddOrEdit =
          Product(id: null, title: '', description: '', price: 0, imageUrl: '');
    }
  }

  void previewImageWhenFocusChange() {
    setState(() {
      imageUrl = _imageUrlTextController.text;
    });
  }

  bool isLoading = false;
  void saveForm() async {
    //VERY IMPORTANT TO VALIDATE FORM INPUT BEFORE CALLING save()
    //don't be confused with auto validate we have used in form fields,it just shows an error msg on every
    //keystrokes on the from field
    //HERE WE ARE ACTUALLY CHECKING IF THERE'S ANY ERRORS. SO THAT WE CAN SAVE THE FORM DATA//VERY IMPORTANT
    ServerResponse response;
    String successScaffoldText;
    if (_formKey.currentState.validate()) {
      setState(() {
        isLoading = true;
      });
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      _formKey.currentState
          .save(); //save calls onSaved: property of each form children
      //add the product to the product list or edited product
      if (widget.productIDToEdit != null) {
        //EDIT PRODUCT
        response =
            await Provider.of<ProductListProvider>(context, listen: false)
                .updateProduct(widget.productIDToEdit, _productToAddOrEdit);
        successScaffoldText = 'The product was successfully edited';
      } else {
        //ADD PRODUCT
        response =
            await Provider.of<ProductListProvider>(context, listen: false)
                .addProduct(_productToAddOrEdit);
        successScaffoldText = 'The product was successfully added.';
      }
      setState(() {
        isLoading = false;
      });
      //show snackbar
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text((response == ServerResponse.SUCCESS)
            ? successScaffoldText
            : (response == ServerResponse.NO_INTERNET)
                ? 'Please check your internet connection.'
                : 'There was some error in adding the product.'),
        duration: Duration(seconds: 3),
      ));
      Navigator.of(context).pop();
    } else {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => AlertDialog(
          contentPadding: const EdgeInsets.all(10),
          title: Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 40,
          ),
          content: Text(
            'Please make sure there are no errors in the form.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(), child: Text('OK'))
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
    _priceFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _imageUrlFocusNode.removeListener(previewImageWhenFocusChange);
    _imageUrlFocusNode.dispose();
    _imageUrlTextController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add or Edit Product'),
          actions: [
            IconButton(
                icon: Icon(Icons.save),
                //we know a null onPressed() disables the button
                onPressed: () {
                  FocusScope.of(context).unfocus(); //to hide the keyboard
                  saveForm();
                }),
          ],
        ),
        //FORM ITSELF IS INVISIBLE, WE BUILD WIDGET TREE INSIDE OF IT WITH SPECIAL FORM WIDGETS INSTEAD
        //for example, instead of TextField, we have to use TextFormField
        //WHAT IS DOES IS THAT IT HELPS WITH USER INPUT AND VALIDATION
        body: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    initialValue: initValues[
                        'title'], //initial value if exists, i.e we're editing a product
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                        labelText: 'Title', hintText: 'My Product'),
                    textInputAction: TextInputAction
                        .next, //shows what button is shown in the soft Keyboard eg. ok, tick, next, etc.
                    //we need to handle this event ourselves and it is shown below
                    onFieldSubmitted: (text) {
                      //when user presses the above soft key in keyboard
                      //we switch the focus to the next textfield
                      FocusScope.of(context).requestFocus(_priceFocusNode);
                    },
                    validator: (value) {
                      if (value.length < 3) {
                        return 'Invalid title'; //error with this message
                      }

                      return null; //no errors
                    },
                    //onSaved we add the appropriate value of the product
                    onSaved: (value) => _productToAddOrEdit = Product(
                        id: _productToAddOrEdit.id,
                        description: _productToAddOrEdit.description,
                        price: _productToAddOrEdit.price,
                        imageUrl: _productToAddOrEdit.imageUrl,
                        isFavorite: _productToAddOrEdit.isFavorite,
                        title: value),
                  ),
                  TextFormField(
                    initialValue: initValues[
                        'price'], //initial value if exists, i.e we're editing a product
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    keyboardType:
                        TextInputType.number, //shows a number keyboard
                    decoration: InputDecoration(
                        labelText: 'Price',
                        hintText: '100.00',
                        prefixText: '\$'),
                    textInputAction: TextInputAction.next,
                    focusNode: _priceFocusNode, //setting the focus node
                    onFieldSubmitted: (value) {
                      FocusScope.of(context)
                          .requestFocus(_descriptionFocusNode);
                    },
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Please enter a price for your product';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      if (double.parse(value) <= 0) {
                        return 'PLease price your item greater than \$0';
                      }

                      return null;
                    },

                    onSaved: (value) => _productToAddOrEdit = Product(
                        id: _productToAddOrEdit.id,
                        description: _productToAddOrEdit.description,
                        price: double.parse(value),
                        imageUrl: _productToAddOrEdit.imageUrl,
                        title: _productToAddOrEdit.title,
                        isFavorite: _productToAddOrEdit.isFavorite),
                  ),
                  TextFormField(
                    initialValue: initValues[
                        'description'], //initial value if exists, i.e we're editing a product
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    maxLines: 3,
                    decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Describe how great your product is!'),
                    keyboardType: TextInputType
                        .multiline, //keyboard with goto next line button//we dont have to use
                    //textInput action
                    focusNode: _descriptionFocusNode,
                    validator: (value) {
                      if (value.length < 10) {
                        return 'Please enter a description that is at least 10 characters long';
                      }

                      return null;
                    },
                    onSaved: (value) => _productToAddOrEdit = Product(
                        id: _productToAddOrEdit.id,
                        description: value,
                        price: _productToAddOrEdit.price,
                        imageUrl: _productToAddOrEdit.imageUrl,
                        title: _productToAddOrEdit.title,
                        isFavorite: _productToAddOrEdit.isFavorite),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      //to display an image preview
                      Container(
                          width: 100,
                          height: 100,
                          margin: EdgeInsets.only(top: 8, right: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey, width: 1),
                            borderRadius: BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          child: (imageUrl == null || imageUrl == '')
                              ? Center(child: Text('Enter an URL'))
                              : ImagePreview(imageUrl)),
                      Expanded(
                        //wrap textfield with Expanded if it is in a row/column
                        child: TextFormField(
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          keyboardType:
                              TextInputType.url, //shows a url friendly keyboard
                          decoration: InputDecoration(
                              labelText: 'Image URL',
                              hintText: 'https://www.myimages.com/image.png'),
                          textInputAction: TextInputAction.done,
                          controller: _imageUrlTextController,
                          focusNode: _imageUrlFocusNode,
                          validator: (value) {
                            if (value.isEmpty) {
                              return 'Please provide an image URL';
                            }
                            var urlPattern =
                                r"(https?|ftp)://([-A-Z0-9.]+)(/[-A-Z0-9+&@#/%=~_|!:,.;]*)?(\?[A-Z0-9+&@#/%=~_|!:‌​,.;]*)?";
                            RegExpMatch result =
                                RegExp(urlPattern, caseSensitive: false)
                                    .firstMatch(value);
                            if (result == null) {
                              return 'Please enter a valid URL';
                            }

                            return null;
                          },
                          onFieldSubmitted: (value) {
                            //when soft button clicked, change imageUrl so that it can be viewed
                            setState(() {
                              imageUrl = value;
                            });
                          },

                          onSaved: (value) => _productToAddOrEdit = Product(
                              id: _productToAddOrEdit.id,
                              description: _productToAddOrEdit.description,
                              price: _productToAddOrEdit.price,
                              imageUrl: value,
                              title: _productToAddOrEdit.title,
                              isFavorite: _productToAddOrEdit.isFavorite),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

//to preview image in the container
class ImagePreview extends StatelessWidget {
  final String imageUrl;

  ImagePreview(this.imageUrl);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        //until the image is loaded this displays
        loadingBuilder: (BuildContext context, Widget child,
            ImageChunkEvent loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes
                  : null,
            ),
          );
        },
        errorBuilder: (_, exception, stacktrace) {
          print(stacktrace.toString());
          return Center(
            child: Text(
              'Error: Make sure your URL is correct.',
              softWrap: true,
              maxLines: 4,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ),
    );
  }
}
