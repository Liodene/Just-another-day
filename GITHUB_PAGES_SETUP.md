# GitHub Pages Setup Instructions

To enable deployment to GitHub Pages, the repository owner needs to complete the following steps:

## Enable GitHub Pages

1. Go to the repository on GitHub: https://github.com/Liodene/Just-another-day
2. Click on **Settings** (gear icon)
3. In the left sidebar, click on **Pages**
4. Under **Build and deployment**:
   - **Source**: Select **GitHub Actions**
   - This allows the workflow to deploy to GitHub Pages
5. Save the settings

## After Enabling

Once GitHub Pages is enabled:
- The workflow will automatically deploy when changes are pushed to the `main` or `copilot/create-flutter-app-workflow` branch
- The workflow will also trigger on pull requests targeting the `main` branch, allowing PR preview deployments
- The app will be available at: https://liodene.github.io/Just-another-day/

## Workflow Details

The `.github/workflows/deploy.yml` workflow:
1. Checks out the code
2. Sets up Flutter SDK (version 3.27.1)
3. Gets dependencies with `flutter pub get`
4. Analyzes code with `flutter analyze`
5. Runs tests with `flutter test`
6. Builds the web app with `flutter build web`
7. Uploads the build artifact
8. Deploys to GitHub Pages

## Local Development

To run the app locally:
```bash
flutter pub get
flutter run -d chrome
```

To build for production:
```bash
flutter build web --release --base-href "/Just-another-day/"
```
