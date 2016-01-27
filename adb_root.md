adb root命令可以是adb已root权限运行
adbd cannot run as root in production builds的问题解决办法：
手机的root权限不完全，下载 超级adbd.apk 安装后 启用超级adbd
adb kill-server
adb start-server
adb root就可以运行了
adb remount 会出现remount failed: Permission denied
执行adb shell mount -o rw,remount /system
然后adb remount就ok了
system文件夹就可以写入了。
