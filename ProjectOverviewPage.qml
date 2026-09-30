import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

Page {
    id: overviewPage

    signal backClicked()

    background: Rectangle {
        color: "#F1F8E9"
    }

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
                onClicked: overviewPage.backClicked()
            }

            Label {
                text: "项目概括"
                font.pixelSize: 20
                font.bold: true
                color: "white"
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }

            Item { width: 72 }
        }
    }

    Flickable {
        anchors.fill: parent
        contentHeight: contentColumn.implicitHeight + 40
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: contentColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            anchors.topMargin: 20
            spacing: 16

            // ===== 项目名称卡片 =====
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: titleCol.implicitHeight + 40
                radius: 16
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#2E7D32" }
                    GradientStop { position: 1.0; color: "#1B5E20" }
                }

                ColumnLayout {
                    id: titleCol
                    anchors.centerIn: parent
                    width: parent.width - 40
                    spacing: 8

                    Text {
                        text: "自然视界"
                        font.pixelSize: 28
                        font.bold: true
                        color: "white"
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: "基于AR技术的沉浸式自然教育与文化创意平台"
                        font.pixelSize: 13
                        color: "#C8E6C9"
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            // ===== 各段内容卡片 =====
            InfoCard {
                title: "项目背景"
                content: "随着城市化进程不断加快，青少年与自然环境之间的联系逐渐减弱。自然教育对于培养生态意识、科学思维和实践能力具有重要意义。\n\n增强现实（AR）技术能够将虚拟信息叠加到现实环境中，为自然教育和文化创意产业提供了新的发展机遇。"
            }

            InfoCard {
                title: "项目定位"
                content: "AR自然教育 + 乡村文旅 + 数字研学平台\n\n核心理念：\n- 让自然成为最好的课堂\n- 让乡村成为最大的教育空间\n- 用AR技术把乡村变成可以探索的自然课堂"
            }

            InfoCard {
                title: "核心功能"
                content: "1. AR自然识别系统\n通过手机摄像头扫描植物、动物、昆虫、地貌等，自动识别并展示三维模型和科普讲解。\n\n2. 自然探索任务系统\n游戏化引导用户探索自然，提供任务挑战和奖励。\n\n3. 知识互动模块\n科普卡片、语音讲解、互动问答。\n\n4. 文化创意内容\n结合农耕文化、传统植物知识进行AR展示。"
            }

            InfoCard {
                title: "目标用户"
                content: "- 亲子家庭\n- 青少年学生\n- 自然教育机构\n- 文旅景区与乡村旅游基地"
            }

            InfoCard {
                title: "社会价值"
                content: "- 推动自然教育普及，降低学习门槛\n- 促进文化创意与科技融合\n- 助力乡村振兴与文旅发展\n- 培养公众生态保护意识"
            }

            InfoCard {
                title: "商业模式"
                content: "收入来源：\n- 会员订阅模式\n- 研学课程合作\n- 景区AR导览系统\n- 自然主题文创产品\n\n形成 教育+文旅+数字内容 的多元盈利模式。"
            }

            InfoCard {
                title: "乡村应用场景"
                content: "- 农耕文化AR体验：扫描稻田展示水稻生长过程\n- 乡村自然科普路线：识别植物、观察昆虫、记录生态\n- 乡村研学教育基地：数字化自然课堂\n\n示范案例：在生态乡村部署自然探索路线、AR识别系统和研学课程。"
            }

            InfoCard {
                title: "发展前景"
                content: "未来平台可拓展到：\n- 国家公园\n- 城市公园\n- 自然博物馆\n- 乡村研学基地\n\n通过技术创新与模式创新，推动自然教育发展，促进科技与文化深度融合。"
            }

            Item { Layout.preferredHeight: 20 }
        }
    }

    // ===== 内容卡片组件 =====
    component InfoCard: Rectangle {
        property string title: ""
        property string content: ""

        Layout.fillWidth: true
        Layout.preferredHeight: cardContent.implicitHeight + 32
        radius: 12
        color: "white"
        border.color: "#E0E0E0"
        border.width: 1

        ColumnLayout {
            id: cardContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            spacing: 8

            Text {
                text: title
                font.pixelSize: 18
                font.bold: true
                color: "#1B5E20"
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#E8F5E9"
            }

            Text {
                text: content
                font.pixelSize: 14
                color: "#424242"
                wrapMode: Text.WordWrap
                lineHeight: 1.4
                Layout.fillWidth: true
            }
        }
    }
}