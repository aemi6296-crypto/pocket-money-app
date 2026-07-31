<table> <tr> <td><img src="./frontend/assets/image/app_icon.png" width="50" alt="App Icon" /></td> <td><h1>Pocket Money App</h1></td> </tr> </table>

A full-stack pocket money management application that helps families track allowances, expenses, and wishlists in one place. Parents and children each have their own accounts, making it easy to manage pocket money, monitor spending, and plan for wishlist items from a single app.
---

## Demo Videos

### Sign Up / Sign In & Kid Portal

[Watch the Kid Portal demo](./frontend/assets/image/demo.gif)

### Parent Portal

[Watch the Parent Portal demo](./frontend/assets/image/demo-parent.gif)

---

## Features

- **Parent-Child Accounts** — separate roles and views for parents and children
- **Wishlist System** — children can add items they want; parents can review and approve them
- **Expense Tracker** — log and monitor how pocket money is being spent
- **Secure Authentication** — powered by Firebase Auth
- **Real-time Data Sync** — powered by Firebase Firestore

---

## Tech Stack

| Layer      | Technology                  |
|------------|------------------------------|
| Frontend   | Flutter (Dart)               |
| Backend    | Node.js, Express             |
| Database   | Firebase Firestore           |
| Auth       | Firebase Authentication      |

---

## Project Structure

```
complete_app/
├── backend/          # Node.js + Express API server
│   ├── config/        # Firebase service account config (not committed)
│   ├── routes/        # API route handlers
│   ├── server.js       # Entry point
│   └── package.json
│
└── frontend/         # Flutter mobile app
    ├── lib/           # Dart source code
    ├── android/
    ├── ios/
    └── pubspec.yaml
```

---

## How It Works

1. **Authentication** — Parents and children sign in through Firebase Authentication, with roles determining what each account can see and do.
2. **Account Linking** — A parent account can be linked to one or more child accounts to manage their pocket money.
3. **Allowance & Expense Tracking** — Every transaction (allowance added, money spent) is recorded and synced in real time via Firestore, so balances stay up to date across devices.
4. **Wishlist Flow** — Children add items to their wishlist; parents can view these requests and approve or decline them based on the child's available balance.
5. **Backend API** — The Node.js/Express backend handles secure server-side operations (such as Firebase Admin actions) that shouldn't be run directly from the client app.

---

## How to Run the Project

### Prerequisites

- [Node.js](https://nodejs.org/) (v18 or higher)
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- A Firebase project with Firestore and Authentication enabled

### 1. Clone the Repository

```bash
git clone https://github.com/aemi6296-crypto/pocket-money-app.git
cd pocket-money-app
```

### 2. Run the Backend

```bash
cd backend
npm install
```

Create a `.env` file in the `backend` folder with the required environment variables.

Add your Firebase service account key:
1. Go to Firebase Console → Project Settings → Service Accounts
2. Generate a new private key
3. Save it as `backend/config/serviceAccountKey.json`

> `.env` and `serviceAccountKey.json` are excluded from version control via `.gitignore`. You must create these files yourself with your own Firebase credentials.

Start the server:

```bash
npm start
```

### 3. Run the Frontend

```bash
cd frontend
flutter pub get
flutter run
```

Ensure Firebase is configured for Flutter (via `flutterfire configure`, or by manually adding `google-services.json` / `GoogleService-Info.plist`).

---

## Environment Variables 

The following files contain sensitive credentials and are intentionally excluded from this repository via `.gitignore`:

- `backend/.env`
- `backend/config/serviceAccountKey.json`

To run this project locally, you need to create these files yourself using your own Firebase project. Any student or contributor can set up their own credentials by following the steps below — no need to use the original developer's keys.

### Getting Your Own Firebase Service Account Key

1. Go to the [Firebase Console](https://console.firebase.google.com/) and open (or create) a project.
2. Navigate to **Project Settings → Service Accounts**.
3. Click **Generate New Private Key**. This downloads a JSON file.
4. Rename the downloaded file to `serviceAccountKey.json` and place it inside `backend/config/`.
5. This file is already listed in `.gitignore`, so it will never be committed or pushed to GitHub.

### Getting Your Own `.env` Variables

1. Inside the `backend` folder, create a file named `.env`.
2. Add the variables your backend expects, for example:

```
PORT=5000
FIREBASE_PROJECT_ID=your-firebase-project-id
```

3. Adjust the variable names/values to match what `server.js` and other backend files expect.

> Each student/developer should use their **own** Firebase project and keys. Never share your `serviceAccountKey.json` or `.env` file publicly, and never commit them to version control.

---

## Hosting 

### Backend (Node.js + Express)

The backend is hosted using **Railway**, a platform that makes it easy to deploy Node.js/Express apps directly from GitHub.

Steps to deploy on Railway:
1. Go to [Railway](https://railway.app/) and sign in with your GitHub account.
2. Click **New Project → Deploy from GitHub Repo**, then select this repository.
3. When prompted, set the **Root Directory** to `backend` (since the backend lives in a subfolder).
4. Railway will auto-detect the Node.js project. Set the **Start Command** to `npm start` if it isn't detected automatically.
5. Go to the **Variables** tab and add your environment variables (the same ones from your local `.env` file), such as `PORT`, `FIREBASE_PROJECT_ID`, etc.
6. For the Firebase service account key, add its full JSON contents as a single environment variable (e.g. `FIREBASE_SERVICE_ACCOUNT`), then parse it with `JSON.parse()` in your code instead of reading it from a local file.
7. Click **Deploy**. Railway will build and start the server, and provide a public URL you can use to access the API.
8. Every time you push new changes to the `main` branch on GitHub, Railway will automatically redeploy the backend.

### Frontend (Flutter)

- **Android**: Build a release APK/App Bundle with `flutter build apk` or `flutter build appbundle`, then distribute via the Play Store or direct APK download.
- **iOS**: Build with `flutter build ios`, then distribute via TestFlight or the App Store (requires an Apple Developer account).
- **Web**: Build with `flutter build web`, then host the output on services like Firebase Hosting, Netlify, or Vercel.

---

## Purpose

This project was built as an educational, full-stack learning project to demonstrate how a Flutter frontend and a Node.js/Express backend can work together with Firebase for authentication and real-time data storage. It showcases practical concepts such as parent-child account management, real-time syncing, and secure API design — intended for learning, portfolio building, and personal use rather than commercial deployment.

---
## Contributors

This project was built collaboratively by two contributors, each focused on a different part of the stack:

<table> <tr> <td align="center" width="200"> <a href="https://github.com/aemi6296-crypto"> <img src="https://github.com/aemi6296-crypto.png" width="100" style="border-radius: 50%;" alt="Frontend Developer" /><br /> <b>Frontend Developer</b> </a> <br /> Flutter (Dart) UI & app development </td> <td align="center" width="200"> <a href="https://github.com/imtisal-zainab-hashmi"> <img src="https://github.com/imtisal-zainab-hashmi.png" width="100" style="border-radius: 50%;" alt="Backend Developer" /><br /> <b>Backend Developer</b> </a> <br /> (Node.js, Express, Firebase) development </td> </tr> </table>


---
## License

This project is licensed for **educational and personal use only**.

- Users are free to **view, modify, and add to the code** for learning or personal projects.
- **Commercial use is strictly prohibited**: you may **not sell, distribute, or use this code** in any commercial product or for-profit purpose.
- Any modifications or additions must also comply with this license and cannot be used commercially.

The underlying source code is additionally provided under the **Apache License 2.0** (see the `LICENSE` file in the root of this repository), subject to the educational/personal-use restriction above.

By using this project, you agree to these terms.
