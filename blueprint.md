# TindahanCE Blueprint

## Overview

TindahanCE is a comprehensive point-of-sale (POS) and inventory management application designed for small retail businesses. It streamlines sales, tracks inventory, and provides valuable insights through sales reports, all within a user-friendly interface.

## Style, Design, and Features

### Authentication
- **Login/Signup:** Secure user authentication with email and password, including a "Remember Me" option.
- **Modern UI:** A clean and modern interface with a teal-based color scheme, Poppins font, and intuitive form fields.

### Core Features
- **Dashboard:** A central hub providing an overview of key business metrics.
- **Sales:** A dedicated screen for processing sales transactions.
- **Product Management:** A screen to view, add, and manage products. Products are stored in and retrieved from Cloud Firestore.
- **Credit Management:** A screen for tracking customer credit.
- **Transaction History:** A detailed log of all sales and transactions.
- **Reporting:** A section for generating sales and inventory reports.
- **Settings:** A screen for configuring application settings.

### Navigation
- **Shell-based Architecture:** The app now uses a persistent "shell" that houses the main content, providing a smoother and more efficient navigation experience.
- **App Drawer:** A consistent navigation drawer allows users to switch between different views within the main shell.
- **Routing:** A simplified `go_router`-based navigation system directs users to the main shell after login.

## Current Task: Refactor Navigation

### Plan
1. **Identify the Issue:** The previous navigation model felt disjointed, with each tab acting as a separate, top-level destination.
2. **Implement a Shell-based Architecture:** Create a new `MainScreen` to act as a persistent shell for the app's main content.
3. **Refactor the App Drawer:** Modify the `AppDrawer` to work with the new `MainScreen`, allowing users to switch between views within the shell.
4. **Update the Router:** Simplify the router to use the `MainScreen` as the primary route after login.
5. **Update the Login Screen:** Change the login screen to navigate to the new `/main` route instead of `/dashboard`.
