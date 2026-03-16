import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';

// Import new structured files
import 'package:spyfall/core/theme/app_theme.dart';
import 'package:spyfall/features/home/screens/home_screen.dart';
import 'package:spyfall/data/legacy/photos.dart' as photos;
import 'package:spyfall/core/localization/app_localizations.dart';

// Make these global variables to track if features can be used
bool notificationsAvailable = false;
bool isInitializing = false;

// Global notifier for language changes
final ValueNotifier<Locale> appLocaleNotifier =
    ValueNotifier(const Locale('ar'));

// This function loads the basic data and copies the spy image
// It runs quickly to ensure the app shows UI fast
Future<void> quickInitApp() async {
  try {
    // Try to load from SharedPreferences first - this is fast
    // print('Quick init: Loading saved data from SharedPreferences');
    await photos.initPhotosData();

    // Ensure spy.png exists in local storage - this is critical
    await copySPyImageFromAssets();

    // Make sure the spy image is in the images list
    await photos.ensureSpyImageInList();
  } catch (e) {
    // print('Error in quick initialization: $e');
  }
}

// This function handles slower operations
// It runs in the background after UI is shown
Future<void> backgroundInitApp() async {
  if (isInitializing) return; // Prevent multiple initializations
  isInitializing = true;

  try {
    // We rely on manual content sync from the photo editor.
  } catch (e) {
    // print('Error in background initialization: $e');
  } finally {
    isInitializing = false;
  }
}

void main() async {
  // This is essential to ensure plugin services are initialized
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // print('App starting, initializing...');
    // Only do quick initialization before showing UI
    await quickInitApp();
  } catch (e) {
    // print('Error in quickInitApp: $e');
  }

  // Start the app immediately
  runApp(const MyApp());

  // Start background tasks after UI is shown
  Future.delayed(Duration(milliseconds: 500), () {
    backgroundInitApp();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocaleNotifier,
      builder: (context, locale, child) {
        return MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ar', ''),
            Locale('en', ''),
          ],
          locale: locale,
          title: 'Spyfall',
          theme: AppTheme.currentTheme,
          debugShowCheckedModeBanner: false,
          home: const HomeScreen(),
        );
      },
    );
  }
}

// Copy spy.png from assets to local storage
Future<void> copySPyImageFromAssets() async {
  try {
    // Get the document directory
    Directory directory = await getApplicationDocumentsDirectory();
    String spyFolderPath = '${directory.path}/spyfall_images';

    // Create the folder if it doesn't exist
    Directory(spyFolderPath).createSync(recursive: true);

    // Create the destination file
    String spyFilePath = '$spyFolderPath/spy.png';
    File spyFile = File(spyFilePath);

    // Check if file already exists and has content
    if (await spyFile.exists()) {
      int fileSize = await spyFile.length();
      if (fileSize > 0) {
        // print('Spy image already exists at $spyFilePath with size $fileSize bytes');

        // Make sure it's in the photos data even if it exists
        bool spyImageExists = photos.images.any((img) => img['name'] == 'spy');
        if (!spyImageExists) {
          photos.images.add({
            'icon': spyFilePath,
            'name': 'spy',
            'categoryId': 0, // Special category ID for spy
          });

          // Save the updated photos data
          await photos.savePhotosData();
          // print('Existing spy image added to photos data');
        }

        return;
      }
    }

    // Load the spy image from assets bundle
    ByteData data = await rootBundle.load('assets/images/spy.png');
    List<int> bytes = data.buffer.asUint8List();

    // Write the file
    await spyFile.writeAsBytes(bytes);
    // print('Spy image copied to $spyFilePath');

    // Add this image to the photos data
    bool spyImageExists = photos.images.any((img) => img['name'] == 'spy');
    if (!spyImageExists) {
      photos.images.add({
        'icon': spyFilePath,
        'name': 'spy',
        'categoryId': 0, // Special category ID for spy
      });

      // Save the updated photos data
      await photos.savePhotosData();
      // print('Spy image added to photos data');
    }
  } catch (e) {
    // print('Error copying spy image: $e');
  }
}
