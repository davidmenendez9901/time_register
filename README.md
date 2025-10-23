# Time Register

A Flutter application for tracking daily work hours and calculating earnings. Perfect for freelancers, consultants, and hourly workers who need to keep accurate records of their time and income.

## 🎯 Features

### ⏰ Time Tracking
- **Easy Entry Creation**: Simple form to log work hours with start/end times
- **Lunch Break Control**: Toggle to automatically deduct 0.5 hours for lunch
- **Automatic Calculations**: Real-time calculation of total hours and earnings
- **Edit & Delete**: Full CRUD operations for work entries

### 💰 Payment Management
- **Payment Status**: Mark entries as paid or unpaid
- **Visual Indicators**: Clear icons and colors to identify payment status
- **Filtering**: View all, paid only, or unpaid entries

### 📊 Weekly Summary
- **Weekly Grouping**: Entries organized by work weeks
- **Statistics**: Total hours and earnings per week
- **Expandable Details**: Drill down into individual entries within each week
- **Advanced Filters**: Filter by payment status

### ⚙️ Customization
- **Hourly Rate**: Configurable default rate (starts at $14.00/hour)
- **Theme Support**: Light, dark, and system theme modes
- **Persistent Settings**: All configurations saved locally

## 🏗️ Architecture

This app follows **Clean Architecture** principles with clear separation of concerns:

- **Presentation Layer**: BLoC pattern for state management
- **Domain Layer**: Entities, use cases, and repository interfaces
- **Data Layer**: Local data sources and repository implementations
- **Database**: SQLite with automatic migrations

## 📱 Screenshots

### Home Screen
- Daily summary with today's hours and earnings
- List of all work entries with visual indicators
- Quick access to add new entries

### Weekly Summary
- Weekly breakdown with expandable entries
- Total statistics and filtering options
- Payment status tracking

### Settings
- Hourly rate configuration
- Theme selection (Light/Dark/System)
- App information and help

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (^3.9.2)
- Dart SDK
- Android Studio / VS Code
- Android device or emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd time_register
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

## 📦 Dependencies

### Core Dependencies
- **flutter_bloc**: State management
- **sqflite**: Local database
- **path_provider**: File system access
- **intl**: Date and time formatting
- **font_awesome_flutter**: Icons
- **flutter_local_notifications**: Local notifications
- **csv**: Data export functionality

### Development Dependencies
- **flutter_lints**: Code quality and best practices

## 🗄️ Database Schema

### Work Entries Table
```sql
CREATE TABLE work_entries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL,
  start_time TEXT NOT NULL,
  end_time TEXT NOT NULL,
  lunch_taken INTEGER NOT NULL DEFAULT 0,
  total_hours REAL NOT NULL,
  hourly_rate REAL NOT NULL,
  earnings REAL NOT NULL,
  is_paid INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL
)
```

### Settings Table
```sql
CREATE TABLE settings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  hourly_rate REAL NOT NULL DEFAULT 0.0,
  theme_mode TEXT NOT NULL DEFAULT 'system'
)
```

## 🎨 UI/UX Features

- **Material Design 3**: Modern, adaptive design
- **Custom Themes**: Light and dark mode support
- **Responsive Layout**: Adapts to different screen sizes
- **Intuitive Navigation**: Bottom navigation with clear sections
- **Visual Feedback**: Loading states, error handling, and success messages

## 🔧 Technical Features

- **Local Storage**: No internet connection required
- **Data Persistence**: SQLite database with migrations
- **State Management**: BLoC pattern for reactive UI
- **Form Validation**: Real-time input validation
- **Error Handling**: Comprehensive error states and recovery

## 📊 Use Cases

- **Freelancers**: Track hours for different clients
- **Hourly Workers**: Record work shifts and calculate pay
- **Consultants**: Monitor project time investment
- **Students**: Track study hours or part-time work

## 🔒 Privacy & Security

- **Local Data**: All information stored on device
- **No Cloud**: No external services or data transmission
- **User Control**: Complete ownership of personal data

## 🛠️ Development

### Project Structure
```
lib/
├── core/           # Domain layer
│   ├── entities/   # Business entities
│   ├── usecases/   # Business logic
│   └── database/   # Database helper
├── data/           # Data layer
│   ├── datasources/ # Data sources
│   └── repositories/ # Repository implementations
└── presentation/   # UI layer
    ├── blocs/     # State management
    ├── pages/     # Screen widgets
    └── widgets/   # Reusable components
```

### Code Quality
- **Clean Architecture**: Separation of concerns
- **SOLID Principles**: Maintainable and testable code
- **Flutter Lints**: Enforced code quality standards
- **Type Safety**: Full Dart type safety

## 📱 Platform Support

- ✅ Android
- ✅ iOS  
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

## 🚀 Future Enhancements

- [ ] Data export (CSV/PDF)
- [ ] Backup and restore
- [ ] Multiple projects support
- [ ] Time tracking with timers
- [ ] Reports and analytics
- [ ] Cloud synchronization

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📞 Support

For support, feature requests, or bug reports, please open an issue in the repository.

---

**Time Register** - Track your time, calculate your earnings, stay organized.
