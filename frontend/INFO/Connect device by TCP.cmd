--adb usb
cd C:\Users\Admin\Documents\Embarcadero\Studio\20.0\PlatformSDKs\android-sdk-windows\platform-tools
adb tcpip 5555
adb reconnect offline
adb connect 192.168.1.95:5555
--adb shell netcfg
adb devices

ping 192.168.1.95 
 