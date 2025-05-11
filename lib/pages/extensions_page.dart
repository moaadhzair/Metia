import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:metia/api/extension.dart';
import 'package:metia/constants/Colors.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:metia/tools.dart';
import 'package:metia/managers/extension_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ExtensionsPage extends StatefulWidget {
  const ExtensionsPage({super.key});

  @override
  State<ExtensionsPage> createState() => _ExtensionsPageState();
}

class _ExtensionsPageState extends State<ExtensionsPage> {
  final ExtensionManager _extensionManager = ExtensionManager();
  List<Extension> availableExtensions = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _extensionManager.init();
    availableExtensions = _extensionManager.getExtensions();
    setState(() {});
  }

  

  void _removeExtension(int index) {
    final removedItem = availableExtensions[index];
    setState(() {
      availableExtensions.removeAt(index);
    });
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ExtensionTile(
          extension: Extension(
            searchApi: removedItem.searchApi,
            episodeListApi: removedItem.episodeListApi,
            title: removedItem.title,
            iconUrl: removedItem.iconUrl,
            dub: removedItem.dub,
            sub: removedItem.sub,
            language: removedItem.language,
            id: removedItem.id,
          ),
          onDeleted: (_) {}, // Empty function since this is just for animation
        ),
      ),
      duration: Duration.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExtensionDialog(context),
        backgroundColor: MyColors.coolPurple,
        child: const Icon(Icons.add, size: 30, color: MyColors.coolPurple2),
      ),
      backgroundColor: MyColors.backgroundColor,
      appBar: AppBar(
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color.fromARGB(255, 69, 69, 70),
            height: 1.0,
          ),
        ),
        foregroundColor: MyColors.appbarTextColor,
        backgroundColor: MyColors.appbarColor,
        title: const Row(
          children: [
            SizedBox(width: 20),
            Text(
              "Installed Extensions",
              style: TextStyle(
                color: MyColors.appbarTextColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child:
            availableExtensions.isEmpty
                ? const Center(
                  child: Text(
                    "No extensions installed",
                    style: TextStyle(
                      color: MyColors.appbarTextColor,
                      fontSize: 16,
                    ),
                  ),
                )
                : AnimatedList(
                  key: _listKey,
                  initialItemCount: availableExtensions.length,
                  itemBuilder: (context, index, animation) {
                    final ext = availableExtensions[index];
                    return FadeTransition(
                      opacity: animation.drive(
                        Tween(
                          begin: 0.0,
                          end: 1.0,
                        ).chain(CurveTween(curve: Curves.easeIn)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ExtensionTile(
                          extension: Extension(
                            searchApi: ext.searchApi,
                            episodeListApi: ext.episodeListApi,
                            title: ext.title,
                            iconUrl: ext.iconUrl,
                            dub: ext.dub,
                            sub: ext.sub,
                            language: ext.language,
                            id: ext.id,
                          ),
                          onDeleted: (context) async {
                            // Get the current list before deletion
                            final currentList =
                                _extensionManager.getExtensions();
                            // Find the index of the extension to delete
                            final indexToDelete = currentList.indexWhere(
                              (e) =>
                                  e.title == ext.title &&
                                  e.iconUrl == ext.iconUrl,
                            );

                            if (indexToDelete != -1) {
                              await _extensionManager.removeExtension(
                                indexToDelete,
                              );
                              if (mounted) {
                                _removeExtension(index);
                              }
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }

  Future<void> _showAddExtensionDialog(BuildContext context) async {
    
    await ExtensionManager().init();

    String extensionUrl = '';
    String? errorText;

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: MyColors.backgroundColor,
              title: const Text(
                'Add Extension',
                style: TextStyle(color: MyColors.appbarTextColor),
              ),
              content: TextField(
                enabled: true,
                style: const TextStyle(color: MyColors.appbarTextColor),
                controller: _textController,
                onChanged: (value) {
                  extensionUrl = value;
                },
                decoration: InputDecoration(
                  hintText: 'Enter extension URL',
                  hintStyle: TextStyle(color: MyColors.appbarTextColor.withOpacity(0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: MyColors.coolPurple),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: MyColors.coolPurple, width: 2),
                  ),
                  errorText: errorText,
                ),
              ),
              actions: [
                TextButton(
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: MyColors.coolPurple),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: const Text(
                    'Add',
                    style: TextStyle(color: MyColors.coolPurple),
                  ),
                  onPressed: () async {
                    if (extensionUrl.isEmpty) {
                      setState(() {
                        errorText = "Please enter a link";
                      });
                    } else if (!extensionUrl.endsWith(".json")) {
                      setState(() {
                        errorText = "The file must be a JSON file";
                      });
                    } else {
                      try {
                        final response = await http.get(
                          Uri.parse(extensionUrl),
                        );
                        if (response.statusCode == 200) {
                          final jsonData = jsonDecode(response.body);

                          // Validate required fields
                          if (!_isValidExtensionJson(jsonData)) {
                            setState(() {
                              errorText = "Invalid extension format";
                            });
                            return;
                          }

                          // Add the extension
                          await _extensionManager.addExtension(
                            Extension(
                              searchApi: jsonData["searchApi"],
                              episodeListApi: jsonData["episodeListApi"],
                              id: 0,
                              title: jsonData['title'],
                              iconUrl: jsonData['iconUrl'],
                              dub: jsonData['dub'],
                              sub: jsonData['sub'],
                              language: jsonData['language'],
                            ),
                          );

                          Navigator.of(context).pop(true);
                        } else {
                          setState(() {
                            errorText = "Failed to fetch extension file";
                          });
                        }
                      } catch (e) {
                        setState(() {
                          errorText = "Error: ${e.toString()}";
                        });
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      final newExtensions = _extensionManager.getExtensions();
      final newItem = newExtensions.last;

      setState(() {
        availableExtensions = newExtensions;
      });

      if (availableExtensions.length > 1) {
        _listKey.currentState?.insertItem(
          availableExtensions.length - 1,
          duration: const Duration(milliseconds: 300),
        );
      }

      Tools.Toast(context, "Extension added");
    }
  }

  /// Validates if the JSON has the required fields for an extension
  bool _isValidExtensionJson(Map<String, dynamic> json) {
    // Check for required fields
    if (!json.containsKey('title')) return false;
    if (!json.containsKey('iconUrl')) return false;
    if (!json.containsKey('dub')) return false;
    if (!json.containsKey('sub')) return false;
    if (!json.containsKey('language')) return false;

    return true;
  }
}

class ExtensionTile extends StatelessWidget {
  final Extension extension;
  final void Function(BuildContext) onDeleted;

  const ExtensionTile({
    super.key,
    required this.extension,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              autoClose: true,
              foregroundColor: MyColors.appbarTextColor,
              backgroundColor: Colors.transparent,
              label: "Delete",
              icon: Icons.delete,
              onPressed: (context) => onDeleted(context),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: MyColors.coolPurple2,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              SizedBox(
                height: 70,
                child: AspectRatio(
                  aspectRatio: 1 / 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CachedNetworkImage(
                      fit: BoxFit.cover,
                      imageUrl: extension.iconUrl,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      extension.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "${extension.language} - ${extension.dub & extension.sub
                          ? "Dub | Sub"
                          : extension.sub
                          ? "Sub"
                          : extension.dub
                          ? "Dub"
                          : "not specified"}",
                      style: const TextStyle(
                        color: MyColors.unselectedColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerRight,
                  child:
                      ExtensionManager().isMainExtension(
                            Extension(
                              searchApi: extension.searchApi,
                              episodeListApi: extension.episodeListApi,
                              id: extension.id,
                              title: extension.title,
                              iconUrl: extension.iconUrl,
                              dub: extension.dub,
                              sub: extension.sub,
                              language: extension.language,
                            ),
                          )
                          ? const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.check,
                              color: MyColors.coolPurple,
                              size: 27,
                            ),
                          )
                          : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
