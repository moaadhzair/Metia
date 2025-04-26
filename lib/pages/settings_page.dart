import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:metia/constants/Colors.dart';
import 'package:metia/data/setting.dart';
import 'package:metia/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _posterUrlController = TextEditingController(
    text: Setting.posterUrl,
  );
  final TextEditingController _UserIdController = TextEditingController(
    text: "",
  );

  late bool _initialSwitchValue; // Store the initial value of the switch
  late String _initialUserId; // Store the initial value of the user ID

  @override
  void initState() {
    super.initState();

    // Load the custom_user_id from SharedPreferences if it exists
    SharedPreferences.getInstance().then((prefs) {
      if (prefs.containsKey("custom_user_id")) {
        final userId = prefs.getInt("custom_user_id").toString();
        setState(() {
          _UserIdController.text = userId; // Set the value in the TextFormField
          _initialUserId = userId; // Store the initial value
        });
      } else {
        _initialUserId = ""; // Default to an empty string if no value exists
      }
    });

    // Load the useSettingsUserId value
    Setting.getuseSettingsUserId().then((_) {
      //Setting.getuseSettingsUserId();
      setState(() {
        
        _initialSwitchValue = Setting.useSettingsUserId; // Store the initial value
      });
    });
  }

  void _handleBackNavigation() async {
    final currentSwitchValue = Setting.useSettingsUserId;
    
    String currentUserId = "";

    await SharedPreferences.getInstance().then((pref){
      currentUserId = pref.getInt("custom_user_id").toString();
    });

    // Check if either the switch value or the user ID has changed
    if (currentSwitchValue != _initialSwitchValue || currentUserId != _initialUserId) {
      // If changes are detected, navigate back to the HomePage
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      // If no changes are detected, just pop the navigation
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: MyColors.appbarTextColor),
        leading: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: MyColors.appbarTextColor),
              onPressed: _handleBackNavigation, // Handle back navigation
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
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelStyle: TextStyle(color: MyColors.unselectedColor),
                        hintStyle: TextStyle(color: MyColors.appbarTextColor),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: MyColors.unselectedColor,
                          ),
                        ),
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
                        Setting.savePosterUrl(context, posterUrl);
                      },
                      icon: Icon(Icons.save, color: MyColors.appbarTextColor),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 9,
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      controller: _UserIdController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelStyle: TextStyle(color: MyColors.unselectedColor),
                        hintStyle: TextStyle(color: MyColors.appbarTextColor),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: MyColors.unselectedColor,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: MyColors.appbarTextColor,
                            width: 3,
                          ),
                        ),
                        border: OutlineInputBorder(),
                        labelText: "Enter the user Id for testing",
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: IconButton(
                      onPressed: () {
                        final userId = _UserIdController.text;
                        Setting.saveUserId(userId);
                      },
                      icon: Icon(Icons.save, color: MyColors.appbarTextColor),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Enable ID testing?",
                    style: TextStyle(
                      color: MyColors.appbarTextColor,
                      fontSize: 16,
                    ),
                  ),
                  Switch.adaptive(
                    value: Setting.useSettingsUserId,
                    onChanged: (bool value) {
                      setState(() {
                        Setting.useSettingsUserId = value;
                        Setting.setuseSettingsUserId();
                      });
                    },
                    activeColor: MyColors.appbarTextColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
