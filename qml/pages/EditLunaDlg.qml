import QtQuick 2.0
import Sailfish.Silica 1.0
import "controls"
import "Persistence.js" as Persistence
import "Algo.js" as Algo

Dialog {
	id: page

	property var lunaInfo

    DialogHeader {
        id: header
        title: qsTr("Edit information")
    }

	SilicaFlickable {
        anchors.top: header.bottom
		anchors.bottom: page.bottom
		anchors.left: page.left
		anchors.right: page.right
		clip: true

		contentHeight: column.height

		Column {
			id: column
			width: page.width

			spacing: Theme.paddingSmall
			TextField {
				id: name
				width: parent.width
                placeholderText: qsTr("Enter profile name")
                label: qsTr("Profile")
				EnterKey.onClicked: page.focus = true
                text: "Luna"
			}
			SectionHeader {
                text: qsTr("Cycle Length")
			}
			Slider {
				id: cycleLength
				width: parent.width
				label: qsTr("Days")
				minimumValue: 21
				maximumValue: 45
				value: 28
				stepSize: 1
				valueText: value
				onValueChanged: {
					if (value < dayInCycle.value) {
						dayInCycle.value = value
					}
				}
			}
			SectionHeader {
                text: qsTr("Day in Cycle")
			}

            Slider {
                id: dayInCycle
                width: parent.width
                minimumValue: 1
                maximumValue: 45
                label: qsTr("Today is which day in your cycle?")
                value: 1
                stepSize: 1
                valueText: {
                    if (dateInCycle.selectedDate) {
                        return "";
                    }
                    if (value == 1) {
                        return qsTr("Menstruation");
                    }
                    return value;
                }
                onValueChanged: {
                    if (value > cycleLength.value) {
                        value = cycleLength.value
                    }
                }
            }
            ValueButtonEx {
                id: dateInCycle
                property var selectedDate

                function openDateDialog() {
                    var _selectedDate = selectedDate;
                    if (!_selectedDate) {
                        _selectedDate = new Date(Algo.todayMS());
                    }

                    var dialog = pageStack.push("Sailfish.Silica.DatePickerDialog", {
                        date: _selectedDate
                    })
                    dialog.accepted.connect(function() {
                        value = dialog.dateText
                        selectedDate = dialog.date
                        dayInCycle.value = 1
                        dayInCycle.handleVisible = false
                        dayInCycle.enabled = false

                    })
                }
                visible: !page.lunaInfo
                label: qsTr("Menstruation")
                value: qsTr("Select")
                description: qsTr("Select the last date of your menstruation")
                width: parent.width
                onClicked: openDateDialog()
            }

			SectionHeader {
				text: qsTr("PMS")
			}
			Slider {
				id: pmsCount
				width: parent.width
				label: qsTr("Days")
				minimumValue: 4
				maximumValue: 11
				value: 7
				stepSize: 1
				valueText: value == 4 ? qsTr("Don't show") : value
			}
		}
		VerticalScrollDecorator {}
	}

	Component.onCompleted: {
        if (lunaInfo) {
			name.text = lunaInfo.name;
			cycleLength.value = lunaInfo.cycle;
			dayInCycle.value = lunaInfo.dayInCycle;
			pmsCount.value = lunaInfo.pms;
		}
	}

	canAccept: String(name.text).trim().length > 0
	onAccepted: {
		var dt;
		if (lunaInfo) {
			//console.log(lunaInfo);

			var update = false;
			if (lunaInfo.name !== String(name.text).trim()) {
				update = true;
				lunaInfo.name = String(name.text).trim();
			}
			if (lunaInfo.cycle !== cycleLength.value
					|| lunaInfo.dayInCycle !== dayInCycle.value) {
				update = true;
				lunaInfo.cycle = cycleLength.value;
				dt = new Date(Algo.todayMS());
				dt.setDate(dt.getDate() - dayInCycle.value + 1)
				lunaInfo.day1ms = dt.getTime();
			}
			if (lunaInfo.pms !== pmsCount.value) {
				update = true;
				lunaInfo.pms = pmsCount.value;
			}
			if (update) {
				Persistence.updateLuna(lunaInfo);
			}
		} else {
			if (dateInCycle.selectedDate) {
				var sdt = dateInCycle.selectedDate;
				dt = new Date(Date.UTC(sdt.getUTCFullYear(), sdt.getUTCMonth(), sdt.getUTCDate()));
			} else {
				dt = new Date(Algo.todayMS());
				dt.setDate(dt.getDate() - dayInCycle.value + 1);
			}
			var luna = {
				name: String(name.text).trim(),
				cycle: cycleLength.value,
				day1ms: dt.getTime(),
				pms: pmsCount.value,
				noteTitle: ''
			};

			var dbid = Persistence.persistLuna(luna);
			console.log(dbid);
			luna['dbid'] = parseInt(dbid);
			lunaInfo = luna;
		}
	}
}
