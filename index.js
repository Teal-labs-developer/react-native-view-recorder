import { NativeModules, requireNativeComponent } from "react-native";

const { RNViewRecorder } = NativeModules;

// export default {
//   RecorderView: requireNativeComponent("RNViewRecorder"),
//   DrawView: requireNativeComponent("RNDrawView")
// };

exports.DrawView = requireNativeComponent("RNDrawView");
exports.RecorderView = requireNativeComponent("RNViewRecorder");

console.log("#######", NativeModules.DrawHelperManager);

exports.isDeviceCompatible = NativeModules.DrawHelperManager
  ? NativeModules.DrawHelperManager.isDeviceCompatible
  : null;
