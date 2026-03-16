import 'package:flutter/material.dart';
import 'package:spyfall/data/legacy/photos.dart'
    as photos; // Import with alias to avoid conflicts
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
// Import main.dart to access global variables
// import 'package:spyfall/main.dart' as main_app;
// Import AppTheme
import 'package:spyfall/core/theme/app_theme.dart';
import 'package:spyfall/core/localization/app_localizations.dart';

// Import GithubService
import 'package:spyfall/data/services/github_service.dart';

class PhotosEditor extends StatefulWidget {
  const PhotosEditor({super.key});

  @override
  State<PhotosEditor> createState() => _PhotosEditorState();
}

class _PhotosEditorState extends State<PhotosEditor> {
  // Generate the list of items based on the number of categories.
  List<Item> _data = [];
  bool isLoading = false;
  double downloadProgress = 0.0;

  // Initialize based on the categories state.
  bool allSelected = true;

  @override
  void initState() {
    super.initState();

    try {
      // Initialize photos data if needed
      photos.initPhotosData();

      // Initialize _data without forcing all categories to be enabled
      _data = generateItems(photos.categories.length);

      // Set allSelected based on the current state of categories
      // (only true if all categories are already enabled)
      allSelected = photos.categories.isNotEmpty &&
          photos.categories.every((cat) => cat['enabled'] == true);

      _photoEditorStateInstance = this; // Keep a reference to this instance
    } catch (e) {
      // print('Error in PhotosEditor initState: $e');
    }
  }

  @override
  void dispose() {
    // Clear global instance when disposed
    if (_photoEditorStateInstance == this) {
      _photoEditorStateInstance = null;
    }
    super.dispose();
  }

  void _showAddCategoryDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceBg,
          title: Text(
            AppLocalizations.of(context)!.translate('addCategory'),
            style: TextStyle(
              color: AppTheme.textPrimary,
            ),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.translate('categoryName'),
              hintStyle: TextStyle(
                color: AppTheme.textPrimary.withValues(alpha: 0.5),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: AppTheme.textSecondary.withValues(alpha: 0.3),
                ),
              ),
            ),
            style: TextStyle(
              color: AppTheme.textPrimary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppLocalizations.of(context)!.translate('cancel'),
                style: TextStyle(
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  await photos.addCategory(controller.text);
                  setState(() {
                    _data = generateItems(photos.categories.length);
                  });
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
              child: Text(
                AppLocalizations.of(context)!.translate('add'),
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addImageToCategory(int categoryId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // Get the category name for the folder
      final String categoryName = photos.categories
          .firstWhere((cat) => cat['id'] == categoryId)['name'];

      // Copy image to app directory with a unique name based on timestamp
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileExtension = image.path.split('.').last;
      final String imageName = 'image_$timestamp.$fileExtension';
      final String imagePath = '${appDir.path}/spyfall_images/$categoryName';

      // Create the directory if it doesn't exist
      await Directory(imagePath).create(recursive: true);

      // Copy the image
      final File newImage =
          await File(image.path).copy('$imagePath/$imageName');

      // Open dialog to input image name
      final TextEditingController controller = TextEditingController();

      // Try to extract a meaningful name from the original file
      final String originalFileName =
          image.path.split('/').last.split('.').first;
      // Set initial value only if it's not a generic camera name
      if (!originalFileName.toLowerCase().contains('img_') &&
          !originalFileName.toLowerCase().contains('image_') &&
          !originalFileName.toLowerCase().contains('photo_')) {
        controller.text = originalFileName;
      }

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppTheme.surfaceBg,
            title: Text(AppLocalizations.of(context)!.translate('imageName')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Preview the selected image
                Container(
                  height: 150,
                  width: 150,
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(image.path),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.broken_image, color: Colors.red);
                      },
                    ),
                  ),
                ),

                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText:
                        AppLocalizations.of(context)!.translate('imageName'),
                    hintText: AppLocalizations.of(context)!
                        .translate('enterImageName'),
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Delete the copied image if canceled
                  newImage.delete();
                },
                child: Text(AppLocalizations.of(context)!.translate('cancel')),
              ),
              TextButton(
                onPressed: () async {
                  // Use a descriptive name or default to the timestamp if empty
                  final String displayName = controller.text.isNotEmpty
                      ? controller.text
                      : 'صورة_$timestamp';

                  // Add the image with its custom name to the category
                  await photos.addImageToCategory(
                      newImage.path, displayName, categoryId);

                  setState(() {
                    _data = generateItems(photos.categories.length);
                  });

                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }

                  if (!context.mounted) return;
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!
                          .translate('imageAddedSuccess')),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate('addImage'),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.add_photo_alternate, color: Colors.white),
                  ],
                ),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _updateImagesFromGithub() async {
    if (!mounted) return;

    try {
      setState(() {
        isLoading = true;
        downloadProgress = 0.0;
      });

      try {
        // Use GithubService to sync content
        await GithubService().syncContent(onProgress: (progress) {
          setState(() {
            downloadProgress = progress;
          });
        });

        // Reload photos data
        await photos.initPhotosData();
      } catch (e) {
        // print('Error calling GithubService: $e');
        rethrow;
      }

      setState(() {
        isLoading = false;
        _data = generateItems(photos.categories.length);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.translate('syncSuccess')),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // print('Error updating images: $e');
      setState(() {
        isLoading = false;
      });
      if (!mounted) return;
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.translate('syncError')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('photoEditor')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddCategoryDialog,
            tooltip: AppLocalizations.of(context)!.translate('addCategory'),
          ),
          IconButton(
            icon: Icon(Icons.cloud_download),
            onPressed: isLoading ? null : _updateImagesFromGithub,
            tooltip: AppLocalizations.of(context)!.translate('cloudDownload'),
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: downloadProgress,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                  SizedBox(height: 20),
                  Text(
                    '${AppLocalizations.of(context)!.translate('downloading')} ${(downloadProgress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: AppTheme.backgroundGradient,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    CheckboxListTile(
                      value: allSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          allSelected = value ?? false;
                          // Update each category's enabled status to match the "select all" value.
                          for (var cat in photos.categories) {
                            cat['enabled'] = allSelected;
                          }
                          photos.savePhotosData(); // Save changes
                        });
                      },
                      title: Text(
                        AppLocalizations.of(context)!.translate('all'),
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      activeColor: AppTheme.primaryColor,
                    ),
                    // Only show individual category panels when "select all" is not active.
                    if (!allSelected) buildCustomExpansionList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget buildCustomExpansionList() {
    return Column(
      children: _data.map((item) {
        return Card(
          color: AppTheme.surfaceBg,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            children: [
              ListTile(
                title: Text(item.headerValue),
                // Make the entire tile clickable
                onTap: () {
                  setState(() {
                    item.isExpanded = !item.isExpanded;
                  });
                },
                // Only show switch in the trailing
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: photos.categories[item.ind]['enabled'],
                      onChanged: (bool value) {
                        setState(() {
                          photos.categories[item.ind]['enabled'] = value;
                          photos.savePhotosData(); // Save changes
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        item.isExpanded ? Icons.expand_less : Icons.expand_more,
                      ),
                      onPressed: () {
                        setState(() {
                          item.isExpanded = !item.isExpanded;
                        });
                      },
                    ),
                  ],
                ),
              ),
              // Only show expanded content if the item is expanded.
              if (item.isExpanded)
                Column(
                  children: [
                    Container(
                      height: 200,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: item.expandedValue,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () => _addImageToCategory(
                                photos.categories[item.ind]['id']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              minimumSize: Size(140, 40),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!
                                      .translate('addImage'),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.add_photo_alternate,
                                    color: Colors.white),
                              ],
                            ),
                          ),
                          SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () => _showDeleteCategoryDialog(
                                photos.categories[item.ind]),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              minimumSize: Size(140, 40),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!
                                      .translate('deleteCategory'),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.delete, color: Colors.white),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showImageOptionsDialog(
      Map<String, dynamic> imageItem, int currentCategoryId) {
    // Controller for the rename text field
    final TextEditingController nameController =
        TextEditingController(text: imageItem['name']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceBg,
          title: Text(AppLocalizations.of(context)!.translate('imageOptions')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image preview
              Container(
                height: 100,
                width: 100,
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageItem['icon'].toString().startsWith('assets/')
                      ? Image.asset(
                          imageItem['icon'],
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(imageItem['icon']),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.broken_image, color: Colors.red);
                          },
                        ),
                ),
              ),

              // Name text field for renaming
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText:
                      AppLocalizations.of(context)!.translate('imageName'),
                  border: OutlineInputBorder(),
                ),
              ),

              SizedBox(height: 20),
              Text(AppLocalizations.of(context)!.translate('selectCategory')),
              SizedBox(
                height: 200,
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: photos.categories.length,
                  itemBuilder: (context, index) {
                    final category = photos.categories[index];
                    final bool isCurrentCategory =
                        category['id'] == currentCategoryId;

                    return ListTile(
                      title: Text(category['name']),
                      trailing: isCurrentCategory
                          ? Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      onTap: () {
                        if (!isCurrentCategory) {
                          // Find image index in the global images list
                          final int imageIndex = photos.images.indexWhere(
                              (img) =>
                                  img['icon'] == imageItem['icon'] &&
                                  img['name'] == imageItem['name'] &&
                                  img['categoryId'] == currentCategoryId);

                          if (imageIndex >= 0) {
                            setState(() {
                              // Update the name if it was changed
                              if (nameController.text.isNotEmpty &&
                                  nameController.text != imageItem['name']) {
                                photos.images[imageIndex]['name'] =
                                    nameController.text;
                              }

                              // Update the category ID
                              photos.images[imageIndex]['categoryId'] =
                                  category['id'];

                              // Save changes
                              photos.savePhotosData();

                              // Regenerate items
                              _data = generateItems(photos.categories.length);
                            });

                            if (!context.mounted) return;

                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '${AppLocalizations.of(context)!.translate('imageMovedSuccess')} ${category['name']}'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [
            // Save renamed image button
            TextButton(
              onPressed: () {
                // Find image index in the global images list
                final int imageIndex = photos.images.indexWhere((img) =>
                    img['icon'] == imageItem['icon'] &&
                    img['name'] == imageItem['name'] &&
                    img['categoryId'] == currentCategoryId);

                if (imageIndex >= 0 &&
                    nameController.text.isNotEmpty &&
                    nameController.text != imageItem['name']) {
                  setState(() {
                    // Update the name
                    photos.images[imageIndex]['name'] = nameController.text;

                    // Save changes
                    photos.savePhotosData();

                    // Regenerate items
                    _data = generateItems(photos.categories.length);
                  });

                  // Show success message
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!
                          .translate('imageRenamedSuccess')),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.translate('saveName')),
            ),

            // Delete button
            TextButton(
              onPressed: () {
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      backgroundColor: AppTheme.surfaceBg,
                      title: Text(AppLocalizations.of(context)!
                          .translate('confirmDelete')),
                      content: Text(AppLocalizations.of(context)!
                          .translate('confirmDeleteImage')),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context)
                                .pop(); // Close confirmation dialog
                          },
                          child: Text(AppLocalizations.of(context)!
                              .translate('cancel')),
                        ),
                        TextButton(
                          onPressed: () {
                            // Find image index in the global images list
                            final int imageIndex = photos.images.indexWhere(
                                (img) =>
                                    img['icon'] == imageItem['icon'] &&
                                    img['name'] == imageItem['name'] &&
                                    img['categoryId'] == currentCategoryId);

                            if (imageIndex >= 0) {
                              // Get the image path before removing from the list
                              final String imagePath =
                                  photos.images[imageIndex]['icon'].toString();

                              // Delete the actual file if it's not an asset
                              if (!imagePath.startsWith('assets/')) {
                                try {
                                  final file = File(imagePath);
                                  if (file.existsSync()) {
                                    file.deleteSync();
                                    // print('Deleted image file: $imagePath');
                                  }
                                } catch (e) {
                                  // print('Error deleting image file: $e');
                                }
                              }

                              setState(() {
                                // Remove image from list
                                photos.images.removeAt(imageIndex);

                                // Save changes
                                photos.savePhotosData();

                                // Regenerate items
                                _data = generateItems(photos.categories.length);
                              });

                              if (!context.mounted) return;
                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.of(context)!
                                      .translate('imageDeletedSuccess')),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }

                            if (!context.mounted) return;
                            Navigator.of(context)
                                .pop(); // Close confirmation dialog
                            if (context.mounted) {
                              Navigator.of(context)
                                  .pop(); // Close options dialog
                            }
                          },
                          child: Text(
                              AppLocalizations.of(context)!.translate('delete'),
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text(AppLocalizations.of(context)!.translate('delete'),
                  style: TextStyle(color: Colors.red)),
            ),

            // Cancel button
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.translate('cancel')),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteCategoryDialog(Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceBg,
          title: Text(AppLocalizations.of(context)!.translate('confirmDelete')),
          content: Text(
              AppLocalizations.of(context)!.translate('confirmDeleteCategory')),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close confirmation dialog
              },
              child: Text(AppLocalizations.of(context)!.translate('cancel')),
            ),
            TextButton(
              onPressed: () async {
                // Use the proper deleteCategory method which properly cleans up files
                await photos.deleteCategory(category['id']);

                // Regenerate items
                setState(() {
                  _data = generateItems(photos.categories.length);
                });

                if (!context.mounted) return;
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم حذف الفئة'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );

                if (context.mounted) {
                  Navigator.of(context).pop(); // Close confirmation dialog
                }
              },
              child: Text('حذف', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

// Global instance for access from generateItems
_PhotosEditorState? _photoEditorStateInstance;

class Item {
  Item({
    required this.expandedValue,
    required this.headerValue,
    this.isExpanded = false,
    required this.ind,
  });

  Widget expandedValue;
  String headerValue;
  bool isExpanded;
  int ind;
}

List<Item> generateItems(int numberOfItems) {
  try {
    return List<Item>.generate(numberOfItems, (int index) {
      try {
        final category = photos.categories[index];
        if (category == null) {
          throw Exception('Category at index $index is null');
        }

        final categoryId = category['id'];
        if (categoryId == null) {
          throw Exception('Category ID is null for index $index');
        }

        final categoryImages = photos.images
            .where((i) => i != null && i['categoryId'] == categoryId)
            .toList();

        return Item(
          ind: index,
          headerValue: '${category['name'] ?? 'Category $index'}',
          expandedValue: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: categoryImages.length,
            itemBuilder: (BuildContext context, int index2) {
              try {
                final imageItem = categoryImages[index2];
                if (imageItem == null) {
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(border: Border.all(width: 1)),
                    child: Icon(Icons.error, color: Colors.red),
                  );
                }

                final icon = imageItem['icon'];
                if (icon == null) {
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(border: Border.all(width: 1)),
                    child:
                        Icon(Icons.image_not_supported, color: Colors.orange),
                  );
                }

                return GestureDetector(
                  onLongPress: () {
                    if (_photoEditorStateInstance != null) {
                      _photoEditorStateInstance!
                          ._showImageOptionsDialog(imageItem, category['id']);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: icon is String
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: icon.toString().startsWith('assets/')
                                      ? Image.asset(
                                          icon,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Icon(Icons.broken_image,
                                                color: Colors.red);
                                          },
                                        )
                                      : Image.file(
                                          File(icon),
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Icon(Icons.broken_image,
                                                color: Colors.red);
                                          },
                                        ),
                                )
                              : Icon(
                                  Icons.image,
                                  size: 50,
                                ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(2),
                            color: Colors.black.withValues(alpha: 0.5),
                            child: Text(
                              imageItem['name'] ?? '',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 10),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } catch (e) {
                // print('Error rendering image at index $index2: $e');
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(border: Border.all(width: 1)),
                  child: Icon(Icons.error, color: Colors.red),
                );
              }
            },
          ),
        );
      } catch (e) {
        // print('Error generating item at index $index: $e');
        return Item(
          ind: index,
          headerValue: 'Error in category $index',
          expandedValue: Center(
            child: Text('Error loading category data'),
          ),
        );
      }
    });
  } catch (e) {
    // print('Error in generateItems: $e');
    return [];
  }
}
