# DocReminder - Document Management App

A Flutter application for managing important documents with expiry date tracking and smart reminders.

## Features

- **Document Management**: Add, edit, and delete documents with ease
- **Multiple Input Methods**: 
  - Capture documents using the device camera
  - Select from photo gallery
  - Pick files from device storage
- **Local File Storage**: All documents are stored locally within the app, ensuring accessibility even if original files are deleted
- **Expiry Tracking**: Track document expiry dates with visual indicators
- **Smart Reminders**: Set custom reminders before document expiry with configurable timing
- **Document Preview**: Preview documents before opening with tap-to-open functionality
- **Search & Filter**: Search documents and filter by status (Valid, Expiring Soon, Expired)
- **Dark Mode Support**: Full dark mode support with system theme detection
- **Responsive UI**: Material 3 design with smooth animations and intuitive navigation

## Installation

### Prerequisites
- Flutter SDK (3.10.7 or higher)
- Dart SDK
- iOS 11.0+ or Android 5.0+

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd document_reminder
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   ├── document_model.dart   # Document data model
│   └── reminder_offset.dart  # Reminder offset configuration
├── screens/
│   ├── home_screen.dart      # Main document list screen
│   ├── add_edit_screen.dart  # Add/edit document screen
│   └── splash_screen.dart    # Splash screen
├── services/
│   ├── file_service.dart     # File handling and storage
│   └── notification_service.dart # Notification management
├── providers/
│   └── document_provider.dart # Riverpod state management
└── widgets/
    ├── document_card.dart    # Document list item widget
    ├── document_preview.dart # Document preview widget
    └── reminder_offset_dropdown.dart # Reminder offset selector
```

## Key Technologies

- **State Management**: Riverpod
- **Local Database**: Hive
- **Notifications**: flutter_local_notifications
- **File Handling**: file_picker, image_picker, open_file
- **UI Framework**: Flutter Material 3
- **Permissions**: permission_handler

## Usage

### Adding a Document

1. Tap the "+" button on the home screen
2. Enter the document name
3. Select a document source:
   - **Camera**: Capture a photo of the document
   - **Gallery**: Select an image from your photo library
   - **Files**: Pick a file from device storage
4. Set the expiry date
5. Configure reminders (optional)
6. Tap "Add Document"

### Editing a Document

1. Tap on a document in the list
2. Modify the details as needed
3. Tap "Update Document"

### Viewing Document Preview

1. After selecting a document, a preview appears
2. Tap the preview to open the document with the default app
3. Tap again while opening to cancel the operation

### Managing Reminders

1. Enable reminders in the document settings
2. Set the reminder offset (days before expiry)
3. Choose the notification time
4. Reminders will be sent daily until the expiry date

## Permissions

The app requires the following permissions:

- **Camera**: To capture documents using the device camera
- **Photo Library**: To select images from the gallery
- **File Storage**: To access and store documents
- **Notifications**: To send expiry reminders

## Data Storage

All documents and their associated files are stored locally in the app's documents directory. This ensures:
- Documents remain accessible even if original files are deleted
- Complete privacy - no data is sent to external servers
- Fast access to documents without internet connection

## Troubleshooting

### Camera not working
- Ensure camera permission is granted in app settings
- Check device camera availability

### Gallery not showing images
- Verify photo library permission is granted
- Ensure device has photos available

### Notifications not appearing
- Check notification permissions in device settings
- Verify reminders are enabled for the document
- Ensure notification time is set correctly

### File not found error
- The file may have been deleted from the original location
- The app stores a copy locally, so the document should still be accessible
- Try re-adding the document if issues persist

## License

This project is licensed under the MIT License.

## Support

For issues or feature requests, please contact the development team.
