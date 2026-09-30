cmake_minimum_required(VERSION 3.16)

project(NatureVision VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)
 set(ANDROID_OPENSSL_ROOT "D:/QT/Tools/openssl/android_openssl-master/ssl_3/arm64-v8a")
find_package(Qt6 6.5 REQUIRED COMPONENTS
    Quick
    QuickControls2
    Multimedia
    Core
    Network
)

qt_standard_project_setup(REQUIRES 6.5)

# ========================================
# 关键：设置 OpenSSL 路径
# Qt 6 安装目录中自带了 Android OpenSSL 预编译库
# 通常在：<Qt安装路径>/android_arm64_v8a/lib/cmake/Qt6/
# 或者可以通过 ANDROID_OPENSSL_ROOT 变量指定
# ========================================

# 方法1：如果 Qt 安装时已包含 OpenSSL（推荐检查这个路径）
# find_package(OpenSSL)

# 方法2：指定 Qt 自带的 Android OpenSSL 路径
# 这个路径需要根据你的实际 Qt 安装目录调整
if(ANDROID)
    # Qt Online Installer 在安装 Android 组件时，会在以下目录放置 OpenSSL：
    # <Qt根目录>/Tools/OpenSSL/3.x.x/arm64-v8a/
    # 或者通过 Maintenance Tool 安装 "OpenSSL Toolkit"
    #
    # 如果你知道确切路径，取消下面的注释并修改路径：D:\QT\Tools\openssl\android_openssl-master
    #set(ANDROID_OPENSSL_ROOT "/path/to/Qt/Tools/OpenSSL/android_openssl-master/ssl_1.1/arm64-v8a")
#"D:\Android\openssl\android_openssl-master\ssl_1.1\arm64-v8a"
    # 使用 Qt 提供的 OpenSSL 查找模块
    if(DEFINED ENV{ANDROID_OPENSSL_ROOT})
        set(ANDROID_OPENSSL_ROOT $ENV{ANDROID_OPENSSL_ROOT})
    endif()

        if(ANDROID_OPENSSL_ROOT)
            message(STATUS "使用 OpenSSL 路径: ${ANDROID_OPENSSL_ROOT}")
            include_directories(${ANDROID_OPENSSL_ROOT}/include)   # 假设 include 子目录存在
            set(OPENSSL_ROOT_DIR ${ANDROID_OPENSSL_ROOT})
        endif()
endif()

qt_add_executable(appNatureVision
    main.cpp
    PlantIdentifier.h
    PlantIdentifier.cpp
)

qt_add_qml_module(appNatureVision
    URI NatureVision
    VERSION 1.0
    QML_FILES
        Main.qml
        CameraPage.qml
        ProjectOverviewPage.qml
        RESOURCES images/background.jpg
)

set_target_properties(appNatureVision PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER com.naturevision.app
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
    QT_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android"
 QT_ANDROID_APP_ICON "@mipmap/ic_launcher"
)

target_link_libraries(appNatureVision PRIVATE
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Multimedia
    Qt6::Core
    Qt6::Network
)

if(ANDROID)
    set_target_properties(appNatureVision PROPERTIES
        QT_ANDROID_ABIS "arm64-v8a"
        QT_ANDROID_MIN_SDK_VERSION 26
        QT_ANDROID_TARGET_SDK_VERSION 34
    )

    # ========================================
    # 将 OpenSSL 库打包到 APK 中
    # Qt Creator 通常会自动处理，但如果没有，
    # 需要手动指定 extra libs
    # ========================================
    if(ANDROID_OPENSSL_ROOT)
        set_target_properties(appNatureVision PROPERTIES
            QT_ANDROID_EXTRA_LIBS
                "${ANDROID_OPENSSL_ROOT}/libcrypto_3.so;${ANDROID_OPENSSL_ROOT}/libssl_3.so"
        )
    endif()
endif()

install(TARGETS appNatureVision
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)