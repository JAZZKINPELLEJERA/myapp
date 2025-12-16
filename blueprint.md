
# Tindahance Blueprint

## Overview

Tindahance is a comprehensive point-of-sale (POS) and inventory management application designed for small retail businesses ("tindahan"). It helps owners track sales, manage product inventory, handle customer credit ("utang"), and view reports on business performance. The app is built with Flutter and Firebase, providing a real-time, cloud-based solution.

## Style, Design, and Features

### Architecture & Tech Stack
- **Framework**: Flutter
- **Backend & Database**: Firebase (Firestore, Firebase Auth)
- **Routing**: `go_router` for declarative navigation.
- **State Management**: Using `StatefulWidget` for local state and `provider` will be added for app-wide state like theme management.
- **UI Design**: Material Design, with a plan to upgrade to Material 3 for a modern look and feel.
- **Asynchronous Operations**: Uses `FutureBuilder` and `StreamBuilder` for interacting with Firebase services.

### Core Features Implemented
- **Authentication**: User can sign up and log in using Firebase Authentication.
- **Main Dashboard**: Displays a summary of the day's sales, total transactions, and top-selling products. It also includes a low-stock alert.
- **Navigation**: A side drawer (`AppDrawer`) provides navigation to all major screens.
- **Make a Sale**: A dedicated screen to search for products and add them to a shopping cart. It supports cash and credit ("utang") payments.
- **Product Management**: A screen to view, add, edit, and delete products. Product details include name, price, and stock quantity.
- **Credit (Utang) Management**: A screen to view and manage customer credit balances.
- **Transaction History**: A screen that lists all past sales transactions.
- **Reporting**: A screen to view daily and monthly sales reports.

### Design Elements
- **Color Scheme**: Primary color is a shade of teal (`#1ABC9C`).
- **Typography**: Uses the 'Poppins' font via the `google_fonts` package for a clean and modern look.
- **Icons**: Uses standard Material Design icons.

## Current Plan

The immediate goal is to refactor and enhance the application's foundation by improving the theming and state management structure.

### Steps:
1.  **Add `provider` package**: Introduce the `provider` package for state management, which is essential for managing the app's theme.
2.  **Implement Material 3 Theming**:
    -   Create a `ThemeProvider` class to manage the app's theme (light, dark, system).
    -   Update `main.dart` to use `ChangeNotifierProvider` to make the `ThemeProvider` available throughout the app.
    -   Define separate `lightTheme` and `darkTheme` using `ThemeData` with `useMaterial3: true` and `ColorScheme.fromSeed` for a modern, cohesive look.
    -   Update the `MaterialApp` to use the themes from the `ThemeProvider`.
3.  **Add Theme Toggle**: Add UI controls to the `SettingsScreen` to allow the user to toggle between light and dark themes.
