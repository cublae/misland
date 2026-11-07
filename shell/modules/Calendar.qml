import QtQuick
import qs.components
import qs.config
import qs.notch
import qs.services

// Month grid. Always six rows so the card keeps its height across months.
Card {
    id: root

    property int year: Time.now.getFullYear()
    property int month: Time.now.getMonth()

    readonly property real cell: 30 * Theme.s
    readonly property int firstDay: Config.calendar.firstDayOfWeek % 7
    readonly property int offset: (new Date(year, month, 1).getDay() - firstDay + 7) % 7

    function shift(delta: int): void {
        const d = new Date(year, month + delta, 1);
        year = d.getFullYear();
        month = d.getMonth();
    }

    function today(): void {
        year = Time.now.getFullYear();
        month = Time.now.getMonth();
    }

    implicitWidth: cell * 7 + 2 * padding
    implicitHeight: column.implicitHeight + 2 * padding

    // Opening the notch always starts at the current month.
    Connections {
        target: NotchState
        function onExpandedChanged() { if (NotchState.expanded) root.today(); }
    }

    Column {
        id: column

        x: root.padding
        y: root.padding
        width: root.cell * 7
        spacing: 4 * Theme.s

        Item {
            width: parent.width
            height: 28 * Theme.s

            Label {
                anchors.left: parent.left
                anchors.leftMargin: 4 * Theme.s
                anchors.verticalCenter: parent.verticalCenter
                text: Time.locale.toString(new Date(root.year, root.month, 1), "MMMM yyyy")
                size: 14
                font.weight: Font.DemiBold

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.today()
                }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                IconButton {
                    icon: "chevron_left"
                    implicitWidth: 26 * Theme.s
                    onClicked: root.shift(-1)
                }
                IconButton {
                    icon: "chevron_right"
                    implicitWidth: 26 * Theme.s
                    onClicked: root.shift(1)
                }
            }
        }

        Row {
            Repeater {
                model: 7

                Label {
                    required property int index
                    width: root.cell
                    horizontalAlignment: Text.AlignHCenter
                    text: Time.locale.dayName((root.firstDay + index) % 7, Locale.ShortFormat).slice(0, 2)
                    size: 11
                    color: Theme.textDim
                }
            }
        }

        Grid {
            columns: 7

            Repeater {
                model: 42

                Item {
                    id: day

                    required property int index
                    readonly property date date: new Date(root.year, root.month, 1 - root.offset + index)
                    readonly property bool inMonth: date.getMonth() === root.month
                    readonly property bool isToday: date.toDateString() === Time.now.toDateString()

                    width: root.cell
                    height: root.cell

                    Rectangle {
                        anchors.centerIn: parent
                        width: root.cell - 4 * Theme.s
                        height: width
                        radius: width / 2
                        color: day.isToday ? Theme.accent : "transparent"
                    }

                    Label {
                        anchors.centerIn: parent
                        text: day.date.getDate()
                        size: 12
                        font.weight: day.isToday ? Font.DemiBold : Font.Medium
                        font.features: { "tnum": 1 }
                        color: day.isToday ? Theme.text
                            : !day.inMonth ? Theme.textFaint
                            : day.date.getDay() === 0 || day.date.getDay() === 6 ? Theme.textDim
                            : Theme.text
                    }
                }
            }
        }
    }
}
