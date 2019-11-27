import { NativeModules, requireNativeComponent } from "react-native";

const { RNViewRecorder } = NativeModules;

export default requireNativeComponent("RNViewRecorder");
