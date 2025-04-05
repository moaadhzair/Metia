import 'package:flutter/material.dart';
import 'package:metia/constants/Colors.dart';
import 'package:metia/data/setting.dart';
import 'package:metia/pages/login_page.dart';

class SettingsPage extends StatelessWidget {
  final TextEditingController _posterUrlController = TextEditingController(
    text: Setting.posterUrl,
  );
  final TextEditingController _defaultSearchController = TextEditingController(
    text: "",
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: MyColors.appbarTextColor),
        leading: Row(
          children: [
            //SizedBox(width: 10),
            IconButton(
              icon: Icon(Icons.arrow_back, color: MyColors.appbarTextColor),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: MyColors.appbarTextColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: MyColors.appbarColor,
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        color: Colors.black,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 9,
                    child: TextFormField(
                      controller: _posterUrlController,
                      //controller: TextEditingController(text: Setting.posterUrl),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelStyle: TextStyle(color: MyColors.unselectedColor),
                        hintStyle: TextStyle(color: MyColors.appbarTextColor),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: MyColors.unselectedColor,
                          ),
                        ),
                        //hintText: "Enter text here",
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: MyColors.appbarTextColor,
                            width: 3,
                          ),
                        ),
                        border: OutlineInputBorder(),
                        labelText: "Enter the url of the anime poster",
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: IconButton(
                      onPressed: () {
                        final posterUrl = _posterUrlController.text;
                        //final posterUrl = (TextEditingController(text: Setting.posterUrl)).text;
                        Setting.savePosterUrl(context, posterUrl);
                      },
                      icon: Icon(Icons.save, color: MyColors.appbarTextColor),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10,),
              Row(
                children: [
                  Expanded(
                    flex: 9,
                    child: TextFormField(
                      controller: _defaultSearchController,
                      //controller: TextEditingController(text: Setting.posterUrl),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelStyle: TextStyle(color: MyColors.unselectedColor),
                        hintStyle: TextStyle(color: MyColors.appbarTextColor),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: MyColors.unselectedColor,
                          ),
                        ),
                        //hintText: "Enter text here",
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: MyColors.appbarTextColor,
                            width: 3,
                          ),
                        ),
                        border: OutlineInputBorder(),
                        labelText: "Enter the name of anime you wnat the mock data of",
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: IconButton(
                      onPressed: () {
                        final defaultSearch = _defaultSearchController.text;
                        //final posterUrl = (TextEditingController(text: Setting.posterUrl)).text;
                        Setting.savedefaultSearch(context, defaultSearch);
                      },
                      icon: Icon(Icons.save, color: MyColors.appbarTextColor),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10,),
              Align(
                alignment: Alignment.topCenter,
                child: ElevatedButton(onPressed: (){
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                }, child: Text("Login"))
              )
            ],
          ),
        ),
      ),
    );
  }
}
