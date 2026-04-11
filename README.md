# 🌿 Vaagai App (வாகை)

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Firebase-%23039BE5.svg?style=for-the-badge&logo=firebase" alt="Firebase">
  <img src="https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Status-Premium_Architecture-green?style=for-the-badge" alt="Status">
</div>

---

### 🔥 **Overview**
**Vaagai** is a premium, state-of-the-art educational application designed to bridge the gap between quality content creation and immersive student learning. Built with a focus on high-performance architecture and modern design aesthetics, Vaagai provides a seamless platform for both course administrators and eager learners.

---

### 🎨 **Key Features**

#### 👨‍🏫 **For Staff (Admin Module)**
- **Dynamic Course Management**: Real-time updates for titles, descriptions, and instructors.
- **Video Strategy**: Effortlessly add YouTube content with a single link.
- **Content Gating**: Toggle between **Demo (Free)** and **Premium (Full)** versions with one tap.
- **Image-First Design**: Hero image previews to ensure students see the best version of your content.

#### 🎓 **For Students**
- **In-App Theater**: Watch YouTube lessons natively without ever leaving the application.
- **Native PDF Rendering**: High-fidelity PDF document viewer built directly into the dashboard.
- **Progressive Discovery**: Browse professional course cards with clear status indicators (Free vs. Premium).
- **Unified Hub**: Access all materials, videos, and instructor info in one centralized view.

---

### 🛠️ **Technology Stack**
- **UI/UX**: Flutter (Material 3) with custom Glassmorphism and specialized cards.
- **Backend Service**: Firebase (Firestore, Authentication, Storage).
- **Video Engine**: `youtube_player_flutter` for native in-app integration.
- **Document Engine**: `syncfusion_flutter_pdfviewer`.
- **Cloud Storage**: Google Drive API integration for scalable document management.

---

### 📐 **Application Flow**

```mermaid
graph TD
    A[Splash Screen] --> B{Account Authentication}
    B -->|Staff Login| C[Staff Dashboard]
    B -->|Student Login| D[Student Dashboard]
    
    C --> C1[Course Management]
    C1 --> C2[Update Metadata]
    C1 --> C3[Add YouTube Content]
    C3 --> C4{Set Demo/Premium}
    
    D --> D1[Course Catalog]
    D1 --> D2[Course Details Page]
    D2 --> D3[Native PDF Viewer]
    D2 --> D4{Watch Video}
    D4 -->|Demo| D5[In-App YouTube Player]
    D4 -->|Premium| D6[Payment Unlock Modal]
```

---

### 🚀 **Installation & Setup**

1. **Clone the repository**
   ```bash
   git clone https://github.com/Vinothkumar0311/Vaagai_app.git
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   Ensure your `google-services.json` is placed in the `android/app/` directory and configure your Firebase project.

4. **Run the App**
   ```bash
   flutter run
   ```

---

<div align="center">
  <p>Built with ❤️ by Vinoth for the Vaagai Community</p>
  <sub>Premium Learning. Simplified.</sub>
</div>
