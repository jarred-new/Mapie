import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import QtLocation
import QtPositioning

ApplicationWindow {
    id: window
    width: 640
    height: 480
    minimumWidth: 200
    minimumHeight: 250
    visible: true
    title: qsTr("Mapie")

    // System theme or button override state
    property bool lightMode: Application.styleHints.colorScheme === Qt.Light

    // Theme Palette
    property color reallyDark: "#1f1f1f"
    property color dark: "#262626"
    property color reallyLight: "#e7e7e7"
    property color light: "#e0e0e0"

    Plugin {
        id: mapPlugin
        name: "osm"
    }

    GridLayout {
        id: grid
        columns: width < 400 ? 1 : 2
        rowSpacing: 0
        columnSpacing: 0
        anchors.fill: parent

        // Left Pane (Map Container)
        Rectangle {
            id: rectangle1
            color: window.lightMode ? window.reallyLight : window.reallyDark
            Layout.fillHeight: true
            Layout.fillWidth: true

            Map {
                id: mainMap
                anchors.fill: parent
                plugin: mapPlugin

                // Coordinates for Paris (Latitude, Longitude)
                center: QtPositioning.coordinate(48.8566, 2.3522)
                zoomLevel: 14

                // 1. Initial configuration when the component finishes loading
                Component.onCompleted: {
                    updateMapTheme()
                }

                // 2. Explicitly listen to theme changes on the window
                Connections {
                    target: window
                    function onLightModeChanged() {
                        mainMap.updateMapTheme();
                    }
                }

                // 3. Theme swapping function (Flipped to fix inverted logic)
                function updateMapTheme() {
                    if (supportedMapTypes.length === 0) return;

                    // Loop through available map styles provided by the OSM plugin
                    for (var i = 0; i < supportedMapTypes.length; i++) {
                        var type = supportedMapTypes[i];

                        if (window.lightMode) {
                            // Light Mode: Default back to standard light street map
                            if (type.style === MapType.StreetMap || type.name.toLowerCase().includes("street")) {
                                mainMap.activeMapType = type;
                                return;
                            }
                        } else {
                            // Dark Mode: Look for a dark or night style
                            if (type.style === MapType.NightStreetMap || type.name.toLowerCase().includes("night")) {
                                mainMap.activeMapType = type;
                                return;
                            }
                        }
                    }
                }

                // --- Handlers for User Map Interactions ---
                PinchHandler {
                    id: pinch
                    target: null
                    onActiveChanged: if (active) {
                        mainMap.startCentroid = mainMap.toCoordinate(pinch.centroid.position, false)
                    }
                    onScaleChanged: (delta) => {
                        mainMap.zoomLevel += Math.log2(delta)
                    }
                }

                DragHandler {
                    id: drag
                    target: null
                    property point lastTrans: Qt.point(0, 0)

                    onActiveChanged: {
                        if (active) {
                            lastTrans = Qt.point(0, 0)
                        }
                    }

                    onTranslationChanged: {
                        if (active) {
                            let dx = translation.x - lastTrans.x
                            let dy = translation.y - lastTrans.y
                            mainMap.pan(-dx, -dy)
                            lastTrans = translation
                        }
                    }
                }

                WheelHandler {
                    id: wheel
                    onWheel: (event) => {
                        if (event.angleDelta.y > 0)
                            mainMap.zoomLevel += 0.5
                        else
                            mainMap.zoomLevel -= 0.5
                    }
                }
            }
        }

        // Right Pane (Control Center Container)
        Rectangle {
            id: rectangle2
            color: window.lightMode ? window.light : window.dark
            Layout.fillHeight: true
            Layout.fillWidth: true

            ColumnLayout {
                anchors.fill: parent
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop

                // Bottom Padding Spacer
                Item {
                    Layout.fillHeight: true
                }

                Button {
                    id: button1
                    text: window.lightMode ? qsTr("\u263D  Dark mode")
                                           : qsTr("\u263C  Light mode")
                    Layout.bottomMargin: 16
                    Layout.alignment: Qt.AlignHCenter

                    contentItem: Text {
                        text: button1.text
                        // Flipped so text remains visible against the dynamic button backdrop
                        color: window.lightMode ? window.light : window.dark
                        font: button1.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        implicitWidth: 120
                        implicitHeight: 36
                        radius: 8
                        color: window.lightMode ? window.dark : window.light
                    }

                    onClicked: window.lightMode = !window.lightMode
                }
            }
        }
    }
}
