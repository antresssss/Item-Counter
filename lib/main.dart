import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();//for the hive.init and hive.openbox to be initialised

  await Hive.initFlutter();
  await Hive.openBox('shopping_box');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'hive_crud',
      theme: ThemeData(
        colorScheme:const ColorScheme.light().copyWith(
              background:const Color(0xFFF9CFC8)),
       appBarTheme:const AppBarTheme(backgroundColor:Color(0xFF1A7482)),),

       home:const HomePage(),
    );
  }
}

//the home page
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //text editing controllers so we have two boxes for typing in
  final TextEditingController _namecontroller =TextEditingController();
  final TextEditingController _quantitycontroller =TextEditingController();

  List<Map<String,dynamic>> _items =[];
  //reference to the shopping_box
  final _shoppingBox =Hive.box('shopping_box');
  @override
  void initState(){
    super.initState();
    //load data when app starts
    refresh_items();
  }

  //adding into the hive box
  void refresh_items(){ //retrieve data from hive and transforms it into a list of maps
    final data=_shoppingBox.keys.map((key){
      //.map method is called on the iterable of keys. It iterates over each key and performs a transformation on it.
      //here the _shoppingBox keys are 0,1,2..
     // For each key in the _shoppingBox, the corresponding value is retrieved using the get method. The value is assigned to the item variable.
     // variable data stores the list of maps
      final item=_shoppingBox.get(key);
      return{"key":key,"name":item["name"],"quantity":item["quantity"]};
    }).toList();  //becomes [{0:{key: , item: , quantity:},{1:   }]

    setState(() { //let ui know that new data
      _items=data.reversed.toList();
      //to sort data from latest to the oldest
    });

      }
  Future<void> _createItem(Map<String,dynamic> newItem ) async{
    await _shoppingBox.add(newItem) ;//.add method gives the key generally as 0,1
    refresh_items();

  }
 Future<void>_updateItem(int itemKey, Map<String,dynamic> item) async{
    await _shoppingBox.put(itemKey,item);
    refresh_items(); //update the UI
 }
  Future<void>_deleteItem(int itemKey) async{
    await _shoppingBox.delete(itemKey);
    refresh_items(); //delete

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An item has been deleted')));
  }

  void _showForm (BuildContext ctx,int? itemKey) async{
    //cus creating there is no key and it is null
    //for update there is key so we use the key
    if(itemKey!=null){
      final existingItem=
          _items.firstWhere((element) => element['key']==itemKey); //from the items list we search for any `element`,if true it will return us the object{k: , n: ,q:}
      _namecontroller.text=existingItem['name'];
      _quantitycontroller.text=existingItem['quantity'];
    }
    showModalBottomSheet(context: ctx,
      backgroundColor:Colors.white,
      elevation:5,
      isScrollControlled: true,
      builder: (_)=> Container(
      padding: EdgeInsets.only(
        bottom:MediaQuery.of(ctx).viewInsets.bottom, // gets contexts about  the app and makes sure that the open keyboard is below it
        top:15,
        left:15,
        right:15),
      child:Column(
        mainAxisSize:MainAxisSize.min,
        crossAxisAlignment:CrossAxisAlignment.end,
        children: [
          TextField(
            controller: _namecontroller,
            decoration: const InputDecoration(hintText: 'Enter item name'),
          ),
          const SizedBox(
            height:10,
          ),
          TextField(
            controller: _quantitycontroller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Enter quantity'),
          ),
          const SizedBox(
            height:20,
          ),
          ElevatedButton(
            style:ButtonStyle(
              backgroundColor: MaterialStateProperty.all(const Color(0xFF1A7482)), // Set the desired background color
            ),
            onPressed: () async{
            if (itemKey==null){
            _createItem({  //to call new function,taking as a map
              "name":_namecontroller.text,
              "quantity":_quantitycontroller.text
            });
            }
            //to call the update function
            if (itemKey!=null){
              _updateItem(itemKey,{
                'name':_namecontroller.text.trim(),'quantity':_quantitycontroller.text.trim()});
            }
            //to clear the text fields
            _namecontroller.text='';
            _quantitycontroller.text='';
            Navigator.of(context).pop(); //close the bottom sheet or go to homepage again
          },
            child:Text(itemKey==null?'Create New':'Update'),),
          const SizedBox(
            height:15,
          ),


        ],
      ),

      ),

    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(
        title: const Text('Item Counter'),
        centerTitle: true,) ,
      body: ListView.builder(
          itemCount: _items.length, // eg item=[{0:{key: , name: , quantity:},{1:   }] ,_=0 and index={ }
          itemBuilder: (_,index){ //
            final currentItem=_items[index];// currentItem={key: , name: , quantity:}
            return Card(
              margin: const EdgeInsets.all(10),
              elevation: 3,
              child: ListTile(
                title: Text(currentItem['name']),
                subtitle: Text(currentItem['quantity'].toString()),
                trailing: Row(
                  mainAxisSize:MainAxisSize.min,
                  children: [
                    IconButton(
                      focusColor:const Color(0xFFF9CFC8),
                      icon:const Icon(Icons.edit_outlined),
                      onPressed: ()=> _showForm(context, currentItem['key']),),
                    IconButton(
                      focusColor:const Color(0xFFF9CFC8),
                      icon:const Icon(Icons.delete),
                      onPressed: ()=> _deleteItem(currentItem['key'])),
                  ],
                ),
                hoverColor:const Color(0xFFF9E9A0),
                tileColor:const Color(0xFFD1E0F3),
              ),
            );
          }
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor:const Color(0xFF138492),
        onPressed: ()=> _showForm(context,null),
        child: const Icon(Icons.add,color:Colors.white,),
                                  ), );
  }
}
