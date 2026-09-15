import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Dialogs
import QtQuick.Layouts
import QtLocation
import QtPositioning

ApplicationWindow {
    id: window
    width: 1280
    height: 800
    minimumWidth: 820
    minimumHeight: 560
    visible: true
    title: qsTr("Mapie")

    property bool darkMode: Application.styleHints.colorScheme === Qt.Dark
    property color canvas: darkMode ? "#101820" : "#f4f7f8"
    property color panel: darkMode ? "#18232c" : "#ffffff"
    property color panelRaised: darkMode ? "#21303a" : "#edf2f3"
    property color ink: darkMode ? "#e8f0f2" : "#19323a"
    property color muted: darkMode ? "#9db0b7" : "#6d8085"
    property color accent: darkMode ? "#70d5c5" : "#087f73"
    property color border: darkMode ? "#30424c" : "#dce6e8"
    property var selectedPlace: null

    function formatCoordinate(value, positive, negative) {
        return Math.abs(value).toFixed(4) + "° " + (value >= 0 ? positive : negative)
    }

    Plugin { id: mapPlugin; name: "osm" }

    header: ToolBar {
        height: 64
        background: Rectangle { color: window.panel; border.color: window.border }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 22
            anchors.rightMargin: 22
            spacing: 18
            Label { text: "MAPIE"; color: window.accent; font { family: "Trebuchet MS"; pixelSize: 20; bold: true; letterSpacing: 2 } }
            Label { text: qsTr("Explore the world"); color: window.muted; font.pixelSize: 13 }
            Item { Layout.fillWidth: true }
            ToolButton { text: "☼"; font.pixelSize: 22; ToolTip.visible: hovered; ToolTip.text: qsTr("Light mode"); onClicked: window.darkMode = false }
            ToolButton { text: "☾"; font.pixelSize: 21; ToolTip.visible: hovered; ToolTip.text: qsTr("Dark mode"); onClicked: window.darkMode = true }
            Button { text: qsTr("Open KML"); onClicked: openDialog.open() }
            Button { text: qsTr("Save KML"); highlighted: true; onClicked: saveDialog.open() }
        }
    }

    background: Rectangle { color: window.canvas }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.preferredWidth: 292
            Layout.fillHeight: true
            color: window.panel
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16
                Label { text: qsTr("PLACES"); color: window.muted; font { pixelSize: 11; bold: true; letterSpacing: 1.6 } }
                Label {
                    text: kmlManager.places.length === 0 ? qsTr("Your saved places will appear here") : qsTr("%1 saved places").arg(kmlManager.places.length)
                    color: window.ink; font.pixelSize: 16; wrapMode: Text.WordWrap; Layout.fillWidth: true
                }
                Button {
                    text: qsTr("＋  Add place at center")
                    Layout.fillWidth: true
                    onClicked: { const coordinate = mainMap.center; kmlManager.addPlace(qsTr("New place"), coordinate.latitude, coordinate.longitude) }
                }
                ListView {
                    id: placesList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 6
                    model: kmlManager.places
                    delegate: Rectangle {
                        width: placesList.width
                        height: 58
                        radius: 7
                        color: window.selectedPlace === modelData ? window.panelRaised : "transparent"
                        border.color: window.selectedPlace === modelData ? window.accent : "transparent"
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 10; spacing: 10
                            Rectangle { width: 8; height: 8; radius: 4; color: window.accent }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 2
                                Label { text: modelData.name; color: window.ink; font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true }
                                Label { text: window.formatCoordinate(modelData.latitude, "N", "S") + "  " + window.formatCoordinate(modelData.longitude, "E", "W"); color: window.muted; font.pixelSize: 11 }
                            }
                        }
                        MouseArea { anchors.fill: parent; onClicked: { window.selectedPlace = modelData; mainMap.center = QtPositioning.coordinate(modelData.latitude, modelData.longitude); mainMap.zoomLevel = Math.max(mainMap.zoomLevel, 10) } }
                    }
                }
                Button { text: qsTr("Clear places"); enabled: kmlManager.places.length > 0; Layout.fillWidth: true; onClicked: kmlManager.clear() }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Map {
                id: mainMap
                anchors.fill: parent
                plugin: mapPlugin
                center: QtPositioning.coordinate(20, 0)
                zoomLevel: 2.2
                copyrightsVisible: true
                MapItemView {
                    model: kmlManager.places
                    delegate: MapQuickItem {
                        coordinate: QtPositioning.coordinate(modelData.latitude, modelData.longitude)
                        anchorPoint.x: marker.width / 2
                        anchorPoint.y: marker.height
                        sourceItem: Column {
                            id: marker
                            spacing: 3
                            Rectangle {
                                width: 28; height: 28; radius: 14; color: window.accent; border.color: "#ffffff"; border.width: 3
                                Text { anchors.centerIn: parent; text: "•"; color: "#ffffff"; font.pixelSize: 20 }
                            }
                            Label { text: modelData.name; color: window.ink; font.bold: true; leftPadding: 5; rightPadding: 5; background: Rectangle { color: window.panel; radius: 4; opacity: 0.92 } }
                        }
                    }
                }
                PinchHandler { target: null; onScaleChanged: delta => mainMap.zoomLevel += Math.log2(delta) }
                DragHandler {
                    target: null
                    property point previousTranslation
                    onActiveChanged: if (active) previousTranslation = Qt.point(0, 0)
                    onTranslationChanged: { mainMap.pan(-(translation.x - previousTranslation.x), -(translation.y - previousTranslation.y)); previousTranslation = translation }
                }
                WheelHandler { onWheel: event => mainMap.zoomLevel += event.angleDelta.y > 0 ? 0.5 : -0.5 }
            }
            Rectangle {
                anchors.left: parent.left; anchors.top: parent.top; anchors.margins: 18
                width: 250; height: 56; radius: 8; color: window.panel; opacity: 0.96
                Column { anchors.fill: parent; anchors.margins: 10; spacing: 3; Label { text: window.formatCoordinate(mainMap.center.latitude, "N", "S"); color: window.ink; font.pixelSize: 12 } Label { text: window.formatCoordinate(mainMap.center.longitude, "E", "W") + "  ·  Zoom " + mainMap.zoomLevel.toFixed(1); color: window.muted; font.pixelSize: 11 } }
            }
            Column {
                anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 18; spacing: 6
                Button { text: "+"; width: 42; height: 38; onClicked: mainMap.zoomLevel += 1 }
                Button { text: "−"; width: 42; height: 38; onClicked: mainMap.zoomLevel -= 1 }
                Button { text: "⌖"; width: 42; height: 38; onClicked: { mainMap.center = QtPositioning.coordinate(20, 0); mainMap.zoomLevel = 2.2 } }
            }
        }
    }

    FileDialog { id: openDialog; title: qsTr("Open KML file"); nameFilters: [qsTr("KML files (*.kml)"), qsTr("All files (*)")]; onAccepted: kmlManager.loadKml(selectedFile) }
    FileDialog { id: saveDialog; title: qsTr("Save KML file"); fileMode: FileDialog.SaveFile; currentFile: "mapie-places.kml"; nameFilters: [qsTr("KML files (*.kml)")]; onAccepted: kmlManager.saveKml(selectedFile) }
    Connections {
        target: kmlManager
        function onLastErrorChanged() { if (kmlManager.lastError.length > 0) errorLabel.text = kmlManager.lastError }
    }
    Label { id: errorLabel; anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 14; color: "#c84b4b"; visible: text.length > 0; background: Rectangle { color: window.panel; radius: 5; anchors.fill: parent; anchors.margins: -7 } }
}