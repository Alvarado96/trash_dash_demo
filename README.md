# TrashDash

Trash Dash, an app that allows users to post their trash and other people can come pick it up. It's all free.

## Features

- Interactive Google Maps with real-time item locations
- Color-coded markers (green for available, orange for claimed)
- One-item-at-a-time claiming to prevent hoarding
- Automatic info windows when zoomed in
- Direct integration with Google Maps for navigation
- Item categories: Furniture, Electronics, Clothing, Books, Toys, Appliances, Decorations, and more

## Getting Started

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Add your Google Maps API key to:
   - `android/app/src/main/AndroidManifest.xml`
   - `ios/Runner/AppDelegate.swift`
4. Run the app with `flutter run`

## Technologies

- Flutter SDK ^3.5.2
- Google Maps Flutter ^2.10.0
- Location Services ^7.0.0
- URL Launcher ^6.3.0
