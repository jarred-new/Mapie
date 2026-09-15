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
    property string mapMode: "Clean"
    property var mapTypesByMode: ({})

    onDarkModeChanged: updateMapType()

    function formatCoordinate(value, positive, negative) {
        return Math.abs(value).toFixed(4) + "° " + (value >= 0 ? positive : negative)
    }

    function updateMapType() {
        const mapTypes = mainMap.supportedMapTypes
        if (mapTypes.length === 0)
            return

        let streetLight = mapTypes[0]
        let streetDark = null
        let explorationLight = null
        let explorationDark = null
        let everythingLight = null
        let everythingDark = null
        for (const mapType of mapTypes) {
            if (mapType.mapType === MapType.StreetMap) {
                if (mapType.night)
                    streetDark = mapType
                else
                    streetLight = mapType
            } else if (mapType.mapType === MapType.HikingMap || mapType.mapType === MapType.TerrainMap) {
                if (mapType.night)
                    explorationDark = mapType
                else if (!explorationLight)
                    explorationLight = mapType
            } else if (mapType.mapType === MapType.HybridMap || mapType.mapType === MapType.SatelliteMap) {
                if (mapType.night)
                    everythingDark = mapType
                else if (!everythingLight)
                    everythingLight = mapType
            }
        }
        window.mapTypesByMode = {
            Clean: { light: streetLight, dark: streetDark || streetLight },
            Exploration: { light: explorationLight || streetLight, dark: explorationDark || streetDark || explorationLight || streetLight },
            Everything: { light: everythingLight || streetLight, dark: everythingDark || streetDark || everythingLight || streetLight }
        }
        window.applyMapMode()
    }

    function applyMapMode() {
        const selectedTypes = window.mapTypesByMode[window.mapMode]
        if (selectedTypes)
            mainMap.activeMapType = window.darkMode ? selectedTypes.dark : selectedTypes.light
    }

    function selectMapMode(mode) {
        window.mapMode = mode
        window.applyMapMode()
        settingsPopup.close()
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
            Label { id: fileNameHeader; text: qsTr("Untitled.kml"); color: window.muted; font.pixelSize: 13 }
            Item { Layout.fillWidth: true }
            ToolButton {
                text: qsTr("Settings");
                font.pixelSize: 10;
                ToolTip.visible: hovered;
                ToolTip.text: qsTr("Mapie Settings");
                onClicked: settingsPopup.open()
            }
            ToolButton { text: "☼"; font.pixelSize: 22; ToolTip.visible: hovered; ToolTip.text: qsTr("Light mode"); onClicked: window.darkMode = false }
            ToolButton { text: "☾"; font.pixelSize: 21; ToolTip.visible: hovered; ToolTip.text: qsTr("Dark mode"); onClicked: window.darkMode = true }
            Button { text: qsTr("Open KML"); onClicked: openDialog.open() }
            Button { text: qsTr("Save KML"); highlighted: true; onClicked: saveDialog.open() }
        }
    }

    background: Rectangle { color: window.canvas }

    Popup {
        id: settingsPopup
        x: window.width - width - 20
        y: 70
        width: 190
        padding: 10
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle { color: window.panel; border.color: window.border; radius: 8 }
        contentItem: ColumnLayout {
            spacing: 4
            Label { text: qsTr("Map style"); color: window.muted; font.bold: true; Layout.leftMargin: 8; Layout.bottomMargin: 4 }
            Button { text: qsTr("Clean"); highlighted: window.mapMode === "Clean"; Layout.fillWidth: true; onClicked: window.selectMapMode("Clean") }
            Button { text: qsTr("Exploration"); highlighted: window.mapMode === "Exploration"; Layout.fillWidth: true; onClicked: window.selectMapMode("Exploration") }
            Button { text: qsTr("Everything"); highlighted: window.mapMode === "Everything"; Layout.fillWidth: true; onClicked: window.selectMapMode("Everything") }
        }
    }

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
                Component.onCompleted: window.updateMapType()
                onSupportedMapTypesChanged: window.updateMapType()
                MapItemView {
                    model: kmlManager.places
                    delegate: MapQuickItem {
                        visible: window.mapMode !== "Clean"
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

    FileDialog {
        id: openDialog;
        title: qsTr("Open KML file");
        nameFilters: [qsTr("KML files (*.kml)"), qsTr("All files (*)")];
        onAccepted: {
            var filename = fileUtils.getFileName(selectedFile);
            kmlManager.loadKml(selectedFile);
            fileNameHeader.text = filename;
        }
    }

    FileDialog {
        id: saveDialog;
        title: qsTr("Save KML file");
        fileMode: FileDialog.SaveFile;
        currentFile: "Untitled.kml";
        nameFilters: [qsTr("KML files (*.kml)")];
        onAccepted: {
            var filename = fileUtils.getFileName(selectedFile);
            kmlManager.saveKml(selectedFile);
            fileNameHeader.text = filename;
        }
    }

    Connections {
        target: kmlManager
        function onLastErrorChanged() { if (kmlManager.lastError.length > 0) errorLabel.text = kmlManager.lastError }
    }
    Label { id: errorLabel; anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 14; color: "#c84b4b"; visible: text.length > 0; background: Rectangle { color: window.panel; radius: 5; anchors.fill: parent; anchors.margins: -7 } }
}