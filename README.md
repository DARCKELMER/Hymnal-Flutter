# Adventist Hymnal
> New version of the adventist hymnal multi-platform.

## Créditos

Basado en [Hymnal-Flutter](https://github.com/GoGoShift/Hymnal-Flutter) de Isaac R. (GoGoShift).
Rediseño Liquid Glass por Elmer Calla Huayhua.

Este repositorio parte del commit `42e1263` del proyecto original. El plan del rediseño
está en [`PLAN_LIQUID_GLASS.md`](PLAN_LIQUID_GLASS.md). El proyecto original no incluye
un archivo de licencia; su autor conserva los derechos sobre el código base.

If you like this app, help me supporting this project:
* [<img src="https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif" alt="Paypal" />](https://www.paypal.me/isax5)

A multi-language hymnal app supporting Spanish, English, Russian and Portuguese. Built with Flutter using Clean Architecture.

## Table of contents
<!--ts-->
   * [Features](#features)
   * [Presence in stores](#presence-in-stores)
   * [Architecture](#architecture)
   * [Getting Started](#getting-started)
   * [Build for Release](#build-for-release)
   * [Main Packages](#main-packages)
   * [Contributing](#contributing)
   * [Support](#support)
   * [License](#license)
<!--te-->

## Features

- **Advanced Search**: Find hymns by title, lyrics, or number with text normalization (stripping accents and special characters).
- **Multiple Hymnals**: Support for different language versions:
  - **English**: 1985 & 1941 versions
  - **Español**: 2009 & 1962 versions
  - **Português**: 1996 version
  - **Русский**: 1997 version
- **Audio Playback**: Listen to instrumental and/or sung versions.
- **Sheet Music**: View piano sheet music for hymns with zoom support.
- **Favorites & History**: Save and reorder favorites, and view your recently opened hymns.
- **Customization**: Adjust font size, toggle theme mode, and enable/disable background images.

---

## Presence in stores
<a title="AppStore" href="https://apps.apple.com/us/app/adventist-hymnal/id1153114394" target="_blank"><img width="150" alt="AppStore" src="http://devimages.apple.com.edgekey.net/app-store/marketing/guidelines/images/badge-download-on-the-app-store.svg"></a>
<a title="Google Play" href="https://play.google.com/store/apps/details?id=net.ddns.HimnarioAdventistaSPA" target="_blank"><img width="150" alt="Google Play" src="https://upload.wikimedia.org/wikipedia/commons/thumb/7/78/Google_Play_Store_badge_EN.svg/256px-Google_Play_Store_badge_EN.svg.png"></a>

**Other platforms / Alternative (Android):**
- [GitHub Releases](https://github.com/isax5/Hymnal-Flutter/releases) (Direct APK download)

---

## Architecture

This app follows Clean Architecture with a focus on reusability and maintainability:

```
lib/
├── constants/          # App-wide constants
├── core/               # Core utilities and shared logic (e.g., StringUtils)
├── services/           # Global services (DI, audio, settings, favorites)
├── styles/             # Theme, fonts, and common styles
├── widgets/            # Reusable UI components (AppScaffold, HymnListTile)
└── layers/             # Clean architecture layers
    ├── data/           # Repositories and data sources
    ├── domain/         # Domain models
    └── screens/        # Feature-based UI screens and controllers
```

---

## Getting Started

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK

### Installation
1. Clone the repository:
```bash
git clone https://github.com/isax5/Hymnal-Flutter.git
cd Hymnal-Flutter
```
2. Install dependencies:
```bash
flutter pub get
```
3. Run the app:
```bash
flutter run
```

---

## Build for Release

**Android:**
```bash
flutter build apk --release
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

---

## Main Packages

| Package | Purpose |
|---------|---------|
| `get_it` | Dependency injection |
| `just_audio` | Audio playback engine |
| `just_audio_background` | Background audio support |
| `shared_preferences` | Local storage |
| `flutter_svg` | SVG support |
| `photo_view` | Zoomable images for sheet music |
| `share_plus` | Share functionality |
| `equatable` | Value-based equality for models |

---

## Contributing
Contributions are welcome! Please visit our [GitHub Repository](https://github.com/isax5/Hymnal-Flutter) for more information.
You can also support by [donating on Paypal](https://www.paypal.me/isax5).

## Support
Reach out to me at one of the following places:
- **Twitter**: [@IsaacRebolledo](https://twitter.com/IsaacRebolledo)
- **LinkedIn**: [Isaac Rebolledo](https://www.linkedin.com/in/isaac-rebolledo-leal-47387698/)

## License
This project is open source. See the repository for license details.
