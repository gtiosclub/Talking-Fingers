### Firebase Setup (EVERYONE MUST DO!!)
Go to the firebase console, select our project, click the gear icon and scroll down to the bottom of general, download the info.plist into the top most level of your talking fingers directory.

### Git Rules
- Every time you work on the repository, pull from main
- Before making a pr, pull from main and push to the branch again
- Make a branch for every issue/task

### Figma
Access the Figma [here](https://www.figma.com/design/53KeLSMLHKRXHLfHG4y1h5/Talking-Fingers-Designs?node-id=40-68&p=f)

### Coding Practices
- Any common Views, ViewModels, or Models used across subteams will be stored in [/Common](https://github.com/gtiosclub/Talking-Fingers/tree/main/Talking%20Fingers/Common)
- End all of your model files with the word “Model”, end all view models with “VM” and end all views with “View”
- When doing asynchronous operations (firebase retrieval & stuff), use Swift Concurrency (async/await)
- Use .toolbar instead of .navigationbar modifiers (since MacOS doesn't support .navigationbar)
- Don't use NavigationStack/NavigationView in your code that stuff will be setup in root views and only officers need to worry about that
  ```Swift
  struct EntryView: View {
    @State private var isLogin: Bool = true
    @Environment(AuthenticationVM.self) var authVM
  }
  ```
- Every view should have an environment attribute called authVM at the top, this is how we'll manage the same user throughout the app. Example:
- Similarly whenever you are displaying a view from another view pass in authVM through the environment. Example:
  ```Swift
  var body: some View {
    if authVM.currentUser != nil {
      MainNavigationView()
        .environment(authVM)
    } else {
      EntryView()
        .environment(authVM)
    }
  }
  ```

### Developing for iOS/macOS
- Backend functions in the viewmodels and models should be able to remain exactly the same among iOS and mac
- Ensure your code builds for both iOS and macOS
  - Most of these issues will come from views because UIKit is only for iOS
  - We can create our own functions/modifiers to replace these and make them work for both mac and iOS
  - All of these replacements will be placed in the “PlatformHelpers.swift” file
  - Look at the first function in the file to see an example of how it works
- If a view is drastically different for iOS and mac, make two separate files like “View_iOS.swift” and “View_macOS.swift”
  - Put all of the code in the files either within and “#if os(ios)” or “#if os(macos)” macro
  - This way the file will only run/be used if the target is on the correct os
 
Most of this stuff will be handled and mentioned by officers in tickets where this is necessary, so don't really worry about remembering this stuff right now.



