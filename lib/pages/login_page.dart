import 'package:flutter/material.dart';
import 'package:uni_links/uni_links.dart';

class LoginPage extends StatefulWidget {
  LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? _repoName;
  String? _repoUrl;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // Get the initial link if the app was opened via a deep link
    try {
      String? initialLink = await getInitialLink();
      if (initialLink != null) {
        _handleLink(initialLink);
      }
    } catch (e) {
      print('Error getting initial deep link: $e');
    }

    // Listen for subsequent deep links while the app is running
    linkStream.listen((String? link) {
      if (link != null) {
        _handleLink(link);
      }
    });
  }

  void _handleLink(String link) {
    // Parse the deep link and extract data
    Uri uri = Uri.parse(link);
    setState(() {
      _repoName = uri.queryParameters['repo_name'];
      _repoUrl = uri.queryParameters['repo_url'];
    });

    // For demonstration, navigate to another screen or show data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RepoDetailsPage(
          repoName: _repoName,
          repoUrl: _repoUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login Page')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_repoName != null && _repoUrl != null) ...[
              Text('Repo Name: $_repoName'),
              Text('Repo URL: $_repoUrl'),
            ] else ...[
              Text('Waiting for deep link...'),
            ],
          ],
        ),
      ),
    );
  }
}

class RepoDetailsPage extends StatelessWidget {
  final String? repoName;
  final String? repoUrl;

  RepoDetailsPage({required this.repoName, required this.repoUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Repo Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Repo Name: $repoName'),
            Text('Repo URL: $repoUrl'),
          ],
        ),
      ),
    );
  }
}
