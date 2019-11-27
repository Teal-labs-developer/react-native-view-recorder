
# react-native-view-recorder

## Getting started

`$ npm install react-native-view-recorder --save`

### Mostly automatic installation

`$ react-native link react-native-view-recorder`

### Manual installation


#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-view-recorder` and add `RNViewRecorder.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libRNViewRecorder.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)<

#### Android

1. Open up `android/app/src/main/java/[...]/MainActivity.java`
  - Add `import com.reactlibrary.RNViewRecorderPackage;` to the imports at the top of the file
  - Add `new RNViewRecorderPackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':react-native-view-recorder'
  	project(':react-native-view-recorder').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-view-recorder/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
      compile project(':react-native-view-recorder')
  	```

#### Windows
[Read it! :D](https://github.com/ReactWindows/react-native)

1. In Visual Studio add the `RNViewRecorder.sln` in `node_modules/react-native-view-recorder/windows/RNViewRecorder.sln` folder to their solution, reference from their app.
2. Open up your `MainPage.cs` app
  - Add `using View.Recorder.RNViewRecorder;` to the usings at the top of the file
  - Add `new RNViewRecorderPackage()` to the `List<IReactPackage>` returned by the `Packages` method


## Usage
```javascript
import RNViewRecorder from 'react-native-view-recorder';

// TODO: What to do with the module?
RNViewRecorder;
```
  