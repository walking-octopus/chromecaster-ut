/*
 * Copyright (C) 2022  walking-octopus
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * chromecaster-ut is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.7
import Ubuntu.Components 1.3
// import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0

MainView {
    id: root
    objectName: 'mainView'
    applicationName: 'chromecaster-ut.walking-octopus'
    automaticOrientation: true

    width: units.gu(85)
    height: units.gu(75)

    Page {
        anchors.fill: parent

        header: PageHeader {
            id: header
            title: serverReady ? i18n.tr('Chromecaster') : i18n.tr('Loading...')
            flickable: scrollView.flickableItem
        }

        ScrollView {
            id: scrollView
            anchors.fill: parent
            ListView {
                id: view
                anchors.fill: parent

                model: deviceModel
                delegate: ListItem {
                    height: layout.height + (divider.visible ? divider.height : 0)

                    ListItemLayout {
                        id: layout

                        Icon {
                            name: "video-display-symbolic"
                            SlotsLayout.position: SlotsLayout.Leading
                            width: units.gu(2)
                        }

                        title.text: device_name
                        subtitle.text: device_type
                        summary.text: status

                        RowLayout {
                            visible: !!status
                            SlotsLayout.position: SlotsLayout.Trailing

                            Button {
                                iconName: "media-playback-start"
                                onClicked: chromecast.unpause(uuid)
                                Layout.preferredWidth: units.gu(4)
                                color: "transparent"
                            }

                            Button {
                                iconName: "media-playback-pause"
                                onClicked: chromecast.pause(uuid)
                                Layout.preferredWidth: units.gu(4)
                                color: "transparent"
                            }
                        }
                    }
                }
            }
        }

        Timer {
            id: discoveryTimer
            running: serverReady
            repeat: true
            interval: 5000
            triggeredOnStart: true
            onTriggered: chromecast.list_devices()
        }

        // Timer {
        //     id: statusTimer
        //     running: chromecast.ready
        //     repeat: true
        //     interval: 4000
        //     onTriggered: chromecast.statusUpdate()
        // }

        Item {
            id: chromecast

            property var connectedDevices: []

            ListModel {
                id: deviceModel
            }

            function list_devices() {
                request("http://localhost:8011/devices").then(response => {
                    const data = JSON.parse(response);

                    deviceModel.clear();
                    for (const device of data) {
                        print(`Parsing ${device.device_name}...`);
                        deviceModel.append({
                            "uuid": device.uuid,
                            "device_name": device.device_name,
                            "device_type": device.device_type,
                            "status": device.info_fields.rs,
                        });
                    }
                    print("End of device list.");

                })
                .catch((error) => {
                    console.error(`Error: ${error}`);
                });
            }

            function status(uuid) {
                connect(uuid).then(status => {
                    request(`http://localhost:8011/status?uuid=${uuid}`).then(response => {
                        const data = JSON.parse(response);

                        print(JSON.stringify(data));
                    })
                    .catch((error) => {
                        print(`Can't get status: ${error}`);
                    });
                }).catch((error) => {
                    print(`Connection error: ${error}`);
                });
            }

            function unpause(uuid) {
                connect(uuid).then(status => {
                    request(`http://localhost:8011/unpause?uuid=${uuid}`).catch((error) => {
                        print(`Can't unpause: ${error}`);
                    });
                }).catch((error) => {
                    print(`Connection error: ${error}`);
                });
            }

            function pause(uuid) {
                connect(uuid).then(status => {
                    request(`http://localhost:8011/pause?uuid=${uuid}`).catch((error) => {
                        print(`Can't pause: ${error}`);
                    });
                }).catch((error) => {
                    print(`Connection error: ${error}`);
                });
            }

            function connect(uuid) {
                print(connectedDevices);

                return new Promise((resolve, reject) => {
                    if (connectedDevices.includes(uuid)) {
                        resolve("Already connected");
                    }

                    if (connectedDevices.length > 3) {
                        request('http://localhost:8011/disconnect-all').then(response => {
                            connectedDevices = [];
                        }).catch((error) => {
                            reject(error);
                        });
                    }

                    request(`http://localhost:8011/connect?uuid=${uuid}`).then(response => {
                        connectedDevices.push(uuid);
                        resolve("Connected");
                    }).catch((error) => {
                        reject(error);
                    });
                })
            }
        }
    }
        function request(url) {
            return new Promise((resolve, reject) => {
                const xhr = new XMLHttpRequest();

                var timer = Qt.createQmlObject("import QtQuick 2.9; Timer {interval: 4000; repeat: false; running: true;}",root,"TimeoutTimer");
                timer.triggered.connect(function() {
                    xhr.abort();
                    xhr.response = "Timed out";
                    reject("Timed out");
                });

                xhr.open("GET", url, true);
                xhr.onload = () => {
                    if (xhr.status >= 200 && xhr.status < 300) {
                        resolve(xhr.response);
                    } else {
                        reject(xhr.status);
                    }
                    timer.running = false;
                };
                xhr.onerror = () => reject(xhr.response);
                xhr.send();
            });
        }
}
