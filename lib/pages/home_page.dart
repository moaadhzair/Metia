import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DefaultTabController( // Add DefaultTabController here
        length: 3, // Number of tabs
        child: Scaffold(
          backgroundColor: Colors.black,
          drawer: Drawer(
            child: Container(
              color: Colors.black87,
            ),
          ),
          appBar: AppBar(
            title: Text("home page"),
            actions: [
              Icon(Icons.search),
              SizedBox(width: 20),
              Icon(Icons.notifications),
              SizedBox(width: 20),
            ],
            backgroundColor: Colors.deepPurple,
            bottom: TabBar(
              physics: const BouncingScrollPhysics(),
              //tabAlignment: TabAlignment.start,
              isScrollable: true,
              tabs: [
                Tab(child: Text("Tab 148484848", style: TextStyle(color: Colors.white),)),
                Tab(child: Text("Tab 2", style: TextStyle(color: Colors.white),)),
                Tab(child: Text("Tab 44848", style: TextStyle(color: Colors.white),)),
                Tab(child: Text("Tab 488", style: TextStyle(color: Colors.white),)),
                Tab(child: Text("Tab 587484489489484564", style: TextStyle(color: Colors.white),)),
                Tab(child: Text("Tab 6", style: TextStyle(color: Colors.white),)),
                Tab(child: Text("Tab 7", style: TextStyle(color: Colors.white),)),
                Tab(child: Text("Tab 8", style: TextStyle(color: Colors.white),)),
                Tab(child: Text("Tab 9", style: TextStyle(color: Colors.white),)),
                Tab(child: Text("Tab 10", style: TextStyle(color: Colors.white),)),
              ],
            ),
          ),
          body: Container(
            child: Center(
              child: Text(
                "Hello World",
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}