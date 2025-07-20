🐟 RRJ Aquatique: Aquarium Monitoring and Feeding App

A Flutter-based mobile application for monitoring water quality and controlling feeding in fish aquariums. Built for **RRJ Watch** as part of our capstone project.

---
📱 Features
```plaintext
- Real-Time Water Quality Monitoring
  - Displays live temperature, turbidity, and pH readings from Firestore
  - Automatically updates without refreshing the app

- Feeding Control System
  - Adjustable feeding schedules 

-  Analytics 
  - Shows water quality status every hour
  - Tooltips for user-friendly guidance

-  Smart Water Quality Status
  - Color-coded status: Good, Warning, or Critical
  - Based on thresholds defined for each parameter

---

🧰 Tech Stack

- Flutter (Dart)
- Firebase Firestore** (Cloud NoSQL database)
- Firebase Core
- Provider (State management)
- Google Fonts, Flutter Vector Icons
- Material Design UI
```
---

Installation
```plaintext
Prerequisites

- Flutter SDK (`>=3.8.0`)
- Firebase project with Firestore enabled
- `google-services.json` (Android) in `android/app/`

Setup Instructions
1. Clone the Repository

   ```bash
   git clone https://github.com/yourusername/rrj-aquatique.git
   cd rrj-aquatique
2. Install Dependencies
    flutter pub get
   
3. Add Firebase Configuration
     Place your google-services.json file in: android/app/google-services.json

4. Run the App
```
---

📁 Folder Structure
```plaintext
RRJ_Watch/
│
├── android/                    
├── assets/                     
│   ├── fonts/
│   └── icons/
├── ios/                        
├── lib/
│   ├── main.dart               
│   ├── src/
│   │   ├── config/
│   │   │   └── (theme.dart)
│   │   ├── models/
│   │   │   ├── (container_levels.dart)
│   │   │   ├── (history_log.dart)
│   │   │   └── (water_data_point.dart)
│   │   ├── services/
│   │   │   └── firestore_service.dart
│   │   ├── ui/
│   │   │   ├── components/
│   │   │   ├── screens/
│   │   │   │   ├── dashboard_screen.dart
│   │   │   │   ├── main_navigation.dart
│   │   │   │   ├── splash_screen.dart
│   │   │   │   ├── system_status_screen.dart
│   │   │   │   └── trends_screen.dart
│   │   │   └── widgets/
│   │   │       ├── ai_insight_dialog.dart
│   │   │       ├── automation_control_card.dart
│   │   │       ├── container_levels.dart
│   │   │       ├── history_insights_dialog.dart
│   │   │       ├── hourly_water_quality_chart.dart
│   │   │       ├── water_quality_status_card.dart
├── pubspec.yaml                # Flutter dependencies & project metadata
└── README.md                   # Project documentation
```
---

👥 Authors
De Arroz, Anghelo 
Alano, Renze 
Berana, Dyalah
