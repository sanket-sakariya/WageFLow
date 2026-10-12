# Contributing to WageFlow

First off, thank you for considering contributing to **WageFlow**! 🎉 Projects like this thrive because of community contributions, whether it's fixing bugs, adding new features, improving documentation, or suggesting UX enhancements.

---

## 🛠️ Getting Started

### 1. Prerequisites
- **Flutter SDK** (3.11.3 or higher recommended): [Install Flutter](https://flutter.dev/docs/get-started/install)
- **Dart SDK** (included with Flutter)
- An Android device/emulator, iOS simulator, or desktop environment for testing.

### 2. Fork and Clone
1. Fork the repository on GitHub: [https://github.com/sanket-sakariya/WageFLow](https://github.com/sanket-sakariya/WageFLow)
2. Clone your fork locally:
   ```bash
   git clone https://github.com/<your-username>/WageFLow.git
   cd WageFLow
   ```
3. Set upstream remote:
   ```bash
   git remote add upstream https://github.com/sanket-sakariya/WageFLow.git
   ```

### 3. Install Dependencies
Run:
```bash
flutter pub get
```

### 4. Run the Project
```bash
flutter run
```

---

## 🧪 Testing

Before submitting a PR, make sure all tests pass and code analyzer is clean:

```bash
# Run tests
flutter test

# Run linter
flutter analyze
```

---

## 🌿 Branching & Development Workflow

1. Create a branch for your feature or fix from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/issue-description
   ```
2. Write clean, idiomatic Dart code following Flutter style guidelines.
3. Keep changes focused and atomic.
4. Add unit or widget tests for any new business logic or calculations (especially in salary/wage computation).
5. Commit with descriptive commit messages:
   ```bash
   git commit -m "feat: add monthly salary export summary"
   # or
   git commit -m "fix: correct overtime rate calculation edge-case"
   ```
6. Push to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```
7. Open a **Pull Request** against the `main` branch of `sanket-sakariya/WageFLow`.

---

## 💡 Ways to Contribute

- **Bug Reports**: Open an issue detailing steps to reproduce, device details, and expected vs actual behavior.
- **Feature Requests**: Suggest ideas (e.g. multi-currency support, PDF slip generation, biometric login, multi-language support).
- **UI/UX Enhancements**: Help polish themes, animations, accessibility, and responsiveness.
- **Documentation**: Improve guides, inline doc comments, or translate the app into more languages.

---

## 📜 Code of Conduct

Please be respectful, kind, and collaborative in all discussions and code reviews. We want WageFlow to be an inclusive and welcoming environment for everyone!

---

Thank you for helping make WageFlow better for businesses, workers, and developers around the world!
