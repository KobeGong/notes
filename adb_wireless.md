# 通过wifi连接adb的方法

1. root手机

    向/system/build.prop文件中添加service.adb.tcp.port=5555

    重启手机

    `adb connect <YOUR DEVICE IP>`
2. 非root手机

    向/system/build.prop文件中添加
    service.adb.tcp.port=5555

    `adb connect <YOUR DEVICE IP>`
