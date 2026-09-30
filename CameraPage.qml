import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material
import QtMultimedia
import NatureVision 1.0   // 导入模块，这样就能访问 PlantAPI 单例

Page {
    id: cameraPage

    signal backClicked()

    property bool capturedMode: false
    property bool cameraReady: false
    property string savedImagePath: ""

    background: Rectangle {
        color: "black"
    }

    Component.onCompleted: {
        console.log("CameraPage 已加载")
        startCameraTimer.start()
    }

    Component.onDestruction: {
        camera.active = false
    }

    Timer {
        id: startCameraTimer
        interval: 500
        repeat: false
        onTriggered: {
            console.log("启动相机...")
            camera.active = true
        }
    }

    // ========== 连接 PlantAPI 单例的信号 ==========
    Connections {
        target: PlantAPI  // 使用注册的单例名称

        function onIdentifyResult(name, detail, score) {
            console.log("识别成功:", name)
            resultText.text = name

            if (score > 0.5) {
                confidenceBadge.badgeColor = "#4CAF50"
                confidenceBadge.badgeText = "高置信度"
            } else if (score > 0.2) {
                confidenceBadge.badgeColor = "#FF9800"
                confidenceBadge.badgeText = "中置信度"
            } else {
                confidenceBadge.badgeColor = "#F44336"
                confidenceBadge.badgeText = "低置信度"
            }
            confidenceBadge.visible = true
            resultDetail.text = detail
            loadingIndicator.visible = false
        }

        function onIdentifyError(errorMessage) {
            console.log("识别失败:", errorMessage)
            resultText.text = "识别失败"
            resultDetail.text = errorMessage
            confidenceBadge.visible = false
            loadingIndicator.visible = false
        }
    }

    // ========== 摄像头会话 ==========
    CaptureSession {
        id: captureSession

        camera: Camera {
            id: camera
            active: false

            onActiveChanged: {
                console.log("相机 active:", active)
            }

            onErrorOccurred: function(error, errorString) {
                console.log("相机错误:", error, errorString)
            }
        }

        imageCapture: ImageCapture {
            id: imageCapture

            onReadyForCaptureChanged: {
                console.log("readyForCapture:", readyForCapture)
                if (readyForCapture) {
                    cameraReady = true
                }
            }

            onImageCaptured: function(requestId, preview) {

                // 用 C++ 辅助方法将 QImage 保存为临时文件
                // ========================================
                console.log("图片已捕获, requestId:", requestId)

                var previewUrl = PlantAPI.saveImageToTemp(preview)
                if (previewUrl !== "") {
                    capturedImage.source = previewUrl
                }

                capturedMode = true
                camera.active = false

                resultText.text = "正在识别..."
                resultDetail.text = "正在上传图片到 Pl@ntNet 进行分析..."
                loadingIndicator.visible = true
                confidenceBadge.visible = false
            }

            onImageSaved: function(requestId, path) {
                // ========================================
                // 图片保存成功，调用 Pl@ntNet API
                // ========================================
                console.log("图片已保存:", path)
                savedImagePath = path
                console.log("调用 Pl@ntNet API...")
                PlantAPI.identifyImage(path)   // 使用单例名称
            }

            onErrorOccurred: function(requestId, error, message) {
                console.log("拍照错误:", error, message)
                resultText.text = "拍照失败"
                resultDetail.text = message
                loadingIndicator.visible = false
            }
        }

        videoOutput: viewfinder
    }

    // ========== 顶部工具栏 ==========
    header: ToolBar {
        Material.background: "#1B5E20"
        height: 56

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8

            Button {
                flat: true
                text: "< 返回"
                font.pixelSize: 16
                Material.foreground: "white"
                onClicked: {
                    camera.active = false
                    cameraPage.backClicked()
                }
            }

            Label {
                text: "拍照识别"
                font.pixelSize: 20
                font.bold: true
                color: "white"
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }

            // 状态灯
            Rectangle {
                width: 12
                height: 12
                radius: 6
                color: {
                    if (PlantAPI.busy) return "#FFEB3B"
                    if (cameraReady) return "#76FF03"
                    if (camera.active) return "#FFEB3B"
                    return "#F44336"
                }
            }

            Item { width: 8 }
        }
    }

    // ========== 主内容 ==========
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ---------- 取景器 / 已拍摄图片 ----------
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // 相机实时预览
            VideoOutput {
                id: viewfinder
                anchors.fill: parent
                visible: !capturedMode
                fillMode: VideoOutput.PreserveAspectCrop
            }

            // 拍摄后的图片
            Image {
                id: capturedImage
                anchors.fill: parent
                visible: capturedMode
                fillMode: Image.PreserveAspectFit
                cache: false  // 禁用缓存，确保每次都加载最新图片
            }

            // 相机未启动时的提示
            Rectangle {
                anchors.fill: parent
                visible: !camera.active && !capturedMode
                color: "#263238"

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 20

                    Text {
                        text: "正在初始化相机..."
                        color: "white"
                        font.pixelSize: 20
                        Layout.alignment: Qt.AlignHCenter
                    }

                    BusyIndicator {
                        Layout.alignment: Qt.AlignHCenter
                        running: !camera.active && !capturedMode
                        Material.accent: "#76FF03"
                    }

                    Text {
                        text: "如果长时间无响应，请检查摄像头权限"
                        color: "#90A4AE"
                        font.pixelSize: 13
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Button {
                        text: "重试"
                        Layout.alignment: Qt.AlignHCenter
                        Material.background: "#43A047"
                        Material.foreground: "white"
                        onClicked: {
                            camera.active = false
                            startCameraTimer.start()
                        }
                    }
                }
            }

            // 扫描线动画
            Rectangle {
                width: parent.width
                height: 3
                color: "#76FF03"
                opacity: 0.8
                visible: scanAnim.running

                SequentialAnimation on y {
                    id: scanAnim
                    running: PlantAPI.busy
                    loops: Animation.Infinite
                    NumberAnimation {
                        from: 0
                        to: 400
                        duration: 1200
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        from: 400
                        to: 0
                        duration: 1200
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            // 拍摄提示
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 16
                anchors.horizontalCenter: parent.horizontalCenter
                width: hintText.implicitWidth + 24
                height: hintText.implicitHeight + 12
                radius: 16
                color: "#88000000"
                visible: !capturedMode && cameraReady

                Text {
                    id: hintText
                    anchors.centerIn: parent
                    text: "对准植物拍照识别"
                    color: "white"
                    font.pixelSize: 13
                }
            }
        }

        // ---------- 识别结果区域 ----------
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: resultArea.implicitHeight + 32
            Layout.minimumHeight: capturedMode ? 100 : 0
            color: "#1B5E20"
            visible: capturedMode

            Flickable {
                anchors.fill: parent
                anchors.margins: 16
                contentHeight: resultArea.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: resultArea
                    width: parent.width
                    spacing: 8

                    // 加载指示器
                    Row {
                        id: loadingIndicator
                        visible: false
                        spacing: 12
                        Layout.alignment: Qt.AlignHCenter

                        BusyIndicator {
                            width: 24
                            height: 24
                            running: loadingIndicator.visible
                            Material.accent: "white"
                        }

                        Text {
                            text: "正在识别中..."
                            color: "white"
                            font.pixelSize: 14
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // 植物名称
                    Text {
                        id: resultText
                        text: "等待识别..."
                        color: "white"
                        font.pixelSize: 18
                        font.bold: true
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    // 置信度标签
                    Rectangle {
                        id: confidenceBadge
                        visible: false
                        Layout.alignment: Qt.AlignHCenter
                        width: badgeLabel.implicitWidth + 20
                        height: 26
                        radius: 13

                        property string badgeText: ""
                        property color badgeColor: "#4CAF50"

                        color: badgeColor

                        Text {
                            id: badgeLabel
                            anchors.centerIn: parent
                            text: confidenceBadge.badgeText
                            color: "white"
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }

                    // 详细信息
                    Text {
                        id: resultDetail
                        text: ""
                        color: "#C8E6C9"
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        lineHeight: 1.4
                    }
                }
            }
        }

        // ---------- 底部操作栏 ----------
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            color: "#263238"

            Row {
                anchors.centerIn: parent
                spacing: 50

                // 重拍
                Column {
                    visible: capturedMode
                    spacing: 6

                    RoundButton {
                        width: 56
                        height: 56
                        anchors.horizontalCenter: parent.horizontalCenter
                        Material.background: "#546E7A"
                        enabled: !PlantAPI.busy

                        Text {
                            anchors.centerIn: parent
                            text: "重拍"
                            color: "white"
                            font.pixelSize: 13
                        }

                        onClicked: {
                            capturedMode = false
                            cameraReady = false
                            savedImagePath = ""
                            resultText.text = "等待识别..."
                            resultDetail.text = ""
                            confidenceBadge.visible = false
                            loadingIndicator.visible = false
                            capturedImage.source = ""
                            camera.active = true
                        }
                    }
                }

                // 拍照
                Column {
                    visible: !capturedMode
                    spacing: 6

                    RoundButton {
                        id: captureButton
                        width: 72
                        height: 72
                        anchors.horizontalCenter: parent.horizontalCenter
                        enabled: imageCapture.readyForCapture

                        background: Rectangle {
                            radius: 36
                            color: "white"
                            border.color: captureButton.enabled ? "#43A047" : "#757575"
                            border.width: 4
                            opacity: captureButton.enabled ? 1.0 : 0.5

                            Rectangle {
                                anchors.centerIn: parent
                                width: 56
                                height: 56
                                radius: 28
                                color: captureButton.pressed ? "#C8E6C9" : "white"
                            }
                        }

                        onClicked: {
                            console.log("拍照！")
                            imageCapture.captureToFile()
                        }
                    }

                    Text {
                        text: captureButton.enabled ? "拍照" : "准备中..."
                        color: "#B0BEC5"
                        font.pixelSize: 12
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                // 重新识别
                Column {
                    visible: capturedMode && savedImagePath !== ""
                    spacing: 6

                    RoundButton {
                        width: 56
                        height: 56
                        anchors.horizontalCenter: parent.horizontalCenter
                        Material.background: "#43A047"
                        enabled: !PlantAPI.busy

                        Text {
                            anchors.centerIn: parent
                            text: "重新\n识别"
                            color: "white"
                            font.pixelSize: 11
                            horizontalAlignment: Text.AlignHCenter
                        }

                        onClicked: {
                            resultText.text = "正在重新识别..."
                            resultDetail.text = ""
                            loadingIndicator.visible = true
                            confidenceBadge.visible = false
                            PlantAPI.identifyImage(savedImagePath)
                        }
                    }
                }
            }
        }
    }
}