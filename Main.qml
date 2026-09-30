import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material
import NatureVision 1.0

ApplicationWindow {
    id: window
    visible: true
    width: 400
    height: 800
    title: "自然视界"

    Material.theme: Material.Light
    Material.accent: Material.Green

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: homePage
    }

    // ========== 主页 ==========
    Component {
        id: homePage

        Page {
            // 修改背景为图片（原为渐变色矩形）
            background: Image {
                source: "images/background.jpg"
                fillMode: Image.PreserveAspectCrop
                anchors.fill: parent
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 30
                width: parent.width * 0.8

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 120
                    height: 120
                    radius: 60
                    color: "white"
                    opacity: 0.9

                    Text {
                        anchors.centerIn: parent
                        text: "N"
                        font.pixelSize: 56
                        font.bold: true
                        color: "#1B5E20"
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "自然视界"
                    font.pixelSize: 36
                    font.bold: true
                    color: "white"
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "基于AR技术的沉浸式自然教育平台"
                    font.pixelSize: 14
                    color: "#E8F5E9"
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    Layout.preferredWidth: parent.width
                }

                Item { Layout.preferredHeight: 40 }

                Button {
                    id: cameraBtn
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 260
                    Layout.preferredHeight: 70

                    background: Rectangle {
                        radius: 35
                        color: cameraBtn.pressed ? "#2E7D32" : "#43A047"
                    }

                    contentItem: Row {
                        spacing: 12
                        anchors.centerIn: parent

                        Text {
                            text: "拍照识别"
                            color: "white"
                            font.pixelSize: 22
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    onClicked: {
                        console.log("打开拍照识别")
                        stackView.push(cameraPageComponent)
                    }
                }

                Button {
                    id: overviewBtn
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 260
                    Layout.preferredHeight: 70

                    background: Rectangle {
                        radius: 35
                        color: overviewBtn.pressed ? "#00695C" : "#00897B"
                    }

                    contentItem: Row {
                        spacing: 12
                        anchors.centerIn: parent

                        Text {
                            text: "项目概括"
                            color: "white"
                            font.pixelSize: 22
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    onClicked: {
                        console.log("打开项目概括")
                        stackView.push(projectOverviewComponent)
                    }
                }

                Item { Layout.preferredHeight: 20 }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "让自然成为最好的课堂"
                    font.pixelSize: 12
                    color: "#C8E6C9"
                    font.italic: true
                }
            }
        }
    }

    Component {
        id: cameraPageComponent
        CameraPage {
            onBackClicked: stackView.pop()
        }
    }

    Component {
        id: projectOverviewComponent
        ProjectOverviewPage {
            onBackClicked: stackView.pop()
        }
    }
}