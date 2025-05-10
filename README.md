# Campus Retrace iOS App

Campus Retrace is an iOS application that helps users track and manage lost and found items. It uses a MockAPI for backend services, including CRUD operations on lost items.

## 🚀 Getting Started

To set up the project locally, follow these steps:

### Prerequisites

* Xcode 14+
* Swift 5.7+
* Git (optional but recommended)

### 📂 Project Structure

* **Models/** - Data models for the app
* **Services/** - API and networking code
* **Views/** - SwiftUI views
* **Info.plist** - App configuration file (contains the API base URL)
* **Config/** - Contains environment-specific configuration files
* **ViewModels/** 
* **Utilities/** 

### 🔑 Setting Up the API Base URL

To avoid exposing your API base URL in the source code, you should use a placeholder and external configuration files.

#### **Option 1: Use Info.plist (Simple)**

Update the **Info.plist** file with the placeholder:

```xml
<key>API_BASE_URL</key>
<string>YOUR_API_BASE_URL</string>
```

Replace `YOUR_API_BASE_URL` with your actual API base URL. **Do not** commit the real URL to your repository.

#### **Option 2: Use .xcconfig Files (Recommended)**

1. **Create .xcconfig Files** (if not already present):

   * `Config/Secrets-Debug.xcconfig`
   * `Config/Secrets-Release.xcconfig`

2. **Add the API Base URL**:

   **Secrets-Debug.xcconfig**

   ```plaintext
   API_BASE_URL = https://your-mock-api.com/api/v1/items
   ```

   **Secrets-Release.xcconfig**

   ```plaintext
   API_BASE_URL = https://your-production-api.com/api/v1/items
   ```

3. **Link .xcconfig Files to Build Settings**:

   * Go to the project settings in Xcode.
   * Under the **Info** tab, link the `Secrets-Debug.xcconfig` file to the **Debug** configuration and the `Secrets-Release.xcconfig` file to the **Release** configuration.

4. **Update Info.plist** to Use the Placeholder:

   ```xml
   <key>API_BASE_URL</key>
   <string>$(API_BASE_URL)</string>
   ```

### 📝 Ignoring Sensitive Files

To avoid accidentally exposing sensitive data, make sure your `.gitignore` includes:

```plaintext
# Ignore sensitive config files
*.xcconfig
Info.plist
```

### ✅ Testing Your Setup

After setting up your API URL, make sure to **clean** and **rebuild** the project to pick up the changes:

```bash
Cmd + Shift + K  # Clean Build Folder
Cmd + B          # Rebuild Project
```

### 📚 Documentation

For more details on using the MockAPI, check out the [MockAPI documentation]([https://mockapi.io/docs](https://github.com/mockapi-io/docs/wiki)).

---

Happy coding!
