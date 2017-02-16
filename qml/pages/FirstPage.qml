/*
  Copyright (C) 2016 Amilcar Santos
  Contact: Amilcar Santos <amilcar.santos@gmail.com>
  All rights reserved.

  You may use this file under the terms of BSD license as follows:

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:
	* Redistributions of source code must retain the above copyright
	  notice, this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright
	  notice, this list of conditions and the following disclaimer in the
	  documentation and/or other materials provided with the distribution.
	* Neither the name of the Amilcar Santos nor the
	  names of its contributors may be used to endorse or promote products
	  derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR
  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import QtQuick 2.0
import Sailfish.Silica 1.0
import "Qlecti.js" as Ql
import "Persistence.js" as Persistence
import "Algo.js" as Algo


Page {
	id: page

	property bool updateAfterManage: false
	property var selectGirlIndex

	SilicaFlickable {
		id: mainView
		anchors.fill: parent

		PullDownMenu {
			MenuItem {
                text: qsTr("About Luna")
				onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"));
			}
			MenuItem {
				text: qsTr("Manage girls")
				onClicked: {
					var pg = pageStack.push(Qt.resolvedUrl("SecondPage.qml"),
						{girlsModel: girlsModel});
					updateAfterManage = true;
					pg.girlSelected.connect(function(idx){
						girlView.currentIndex = idx;
					});
				}
			}
		}

		PushUpMenu {
			MenuItem {
				text: qsTr("Go to today")
				onClicked: datePicker.date = new Date();
			}
			MenuItem {
				text: qsTr("Edit day note")
				visible: girlsModel.count > 0
				onClicked: {
					var _girlInfo = girlsModel.get(girlView.currentIndex);
					var _noteInfo = Persistence.note(_girlInfo.dbid, _girlInfo.dayInCycle - 1);
					if (_noteInfo === '') {
						_noteInfo = Algo.emptyNoteInfo(_girlInfo.dbid, _girlInfo.dayInCycle - 1);
					}

					var dialog = pageStack.push(Qt.resolvedUrl("EditNoteDlg.qml"),
						{noteInfo: _noteInfo})
					dialog.accepted.connect(function() {
						girlsModel.setProperty(girlView.currentIndex, "noteTitle", dialog.noteInfo.title);
					});
				}
			}
		}

		// Tell SilicaFlickable the height of its content.
		contentHeight: isPortrait? dateColumn.height + girlColumn.height : dateColumn.height

		Column {
			id: dateColumn

			property var pickerGirlInfo

			width: isPortrait? parent.width : Screen.width//parent.width * 0.55;
			spacing: 0
			PageHeader {
				id: header
                title: "Luna"
				visible: isPortrait
			}
			Item {
				id: landscapeSpacing
				visible: isLandscape
				width: parent.width
				height: Theme.paddingMedium
			}
			Item {
				property int cellWidth: width / 7
				property int cellHeight: cellWidth

				id: dateContainer
				width: parent.width
				height: datePicker.height + weekDaysSimulator.height
				Row {
					id: weekDaysSimulator
					height: Theme.paddingMedium + Theme.iconSizeExtraSmall + Theme.paddingSmall
					Repeater {
						model: 7
						delegate: Label {
							// 2 Jan 2000 was a Sunday
							text: Qt.formatDateTime(new Date(2000, 0, 3 + index, 12), "ddd")
							width: dateContainer.cellWidth
							font.pixelSize: Theme.fontSizeExtraSmall
							color: Theme.highlightColor
							opacity: 0.5
							horizontalAlignment: Text.AlignHCenter
						}
					}
				}
				Image {
					anchors.fill: parent
					source: "image://theme/graphic-gradient-edge"
					rotation: 180
					visible: isPortrait
				}
				DatePicker {
					id: datePicker
					//daysVisible: true
					anchors.top: weekDaysSimulator.bottom

					delegate: Component {
						Rectangle {
							id: rect
							width: dateContainer.cellWidth
							height: dateContainer.cellHeight
							radius: 2
							color: rectColor(model.day, model.month, model.year)

							function rectColor(day, month, year) {
								if (dateColumn.pickerGirlInfo) {
									var pgi = dateColumn.pickerGirlInfo;
									var d = Algo.daysInCycle(pgi.cycle, pgi.day1ms, Date.UTC(year, month - 1, day));
									var color = pgi.colorArr[d];
									//console.log(d, color, day, month, year)
									if (color) {
										return Theme.rgba(color, pgi.opacityArr[d])
									}
								}
								return 'transparent';
							}
							function rectIcon(day, month, year) {
								if (dateColumn.pickerGirlInfo) {
									var pgi = dateColumn.pickerGirlInfo;
									var d = Algo.daysInCycle(pgi.cycle, pgi.day1ms, Date.UTC(year, month - 1, day));
									var icon = pgi.iconArr[d];
									if (icon === 0) {
										return 'image://theme/icon-s-alarm'
									}
								}
								return '';
							}

							Label {
								property bool _today: {
									return datePicker.day == model.day
										&& datePicker.month == model.month
										&& datePicker.year == model.year;
									}
								anchors.centerIn: parent
								text: model.day
								font.pixelSize: 0
								font.bold: _today
								color: Theme.primaryColor
							}
							/*TBD Image {
								anchors.right: parent.right
								anchors.top: parent.top
								source: rectIcon(model.day, model.month, model.year)
								scale: 0.75
							}*/
						}
					}
				}
				Component.onCompleted: {
					if (Object(datePicker).hasOwnProperty('daysVisible')) {
						// SfOS 2
						weekDaysSimulator.height = 0;
						weekDaysSimulator.visible = false;
						datePicker.daysVisible = true;
						dateContainer.cellWidth = datePicker.cellWidth;
						dateContainer.cellHeight = datePicker.cellHeight;
					}
				}
			}
		}
		Item {
			id: girlColumn
			x: isPortrait? 0 : dateColumn.width
			y: isPortrait? dateColumn.height + dateColumn.y : Theme.paddingLarge
			width: isPortrait? page.width : page.width - dateColumn.width
			height: isPortrait? page.height - dateColumn.height : page.height
			clip: true

			SectionHeader {
				id: girlHeader
                text: qsTr("Information")
			}

			SlideshowView {
				id: girlView
                y: girlHeader.y
                width: parent.width
				itemWidth: parent.width

				model: 0
				delegate: Item {
					width: girlView.itemWidth
					height: labels.height

					Column {
						id: labels
						property bool hasNote: !!model.noteTitle
						width: parent.width
						spacing: hasNote ? -Theme.paddingSmall : -1
						Label {
							id: name
							width: parent.width
							horizontalAlignment: Text.AlignHCenter
							text: model.name
							font.pixelSize: Theme.fontSizeLarge
							color: Theme.primaryColor
						}
						DetailItem {
							id: cycles
							label: qsTr("Cycle")
							value: model.cycle
						}
						DetailItem {
							id: dayincycle
							label: qsTr("Day in cycle")
							value: model.dayInCycle
						}
						DetailItem {
							id: nextOv
							label: qsTr("Next ovulation")
							value: model.nextOv
						}
						DetailItem {
							id: nextMn
							label: qsTr("Next menstruation")
							value: model.nextMn
						}
						DetailItem {
							id: note
							label: qsTr("Note title")
							rightMargin: Theme.paddingSmall
							visible: labels.hasNote
							value: model.noteTitle
						}
					}
				}

				onCurrentIndexChanged: {
					Ql.on(girlsModel).at(currentIndex, function(girl) {
						page.fillGirlInfo(girl);
					}).empty(function() {
						appWindow.coverInfo = undefined;
						dateColumn.pickerGirlInfo = undefined;
					});
				}
			}
		}

		Label {
			id: noGirlPlaceholder
			anchors.fill: girlColumn
			wrapMode: Text.Wrap
			horizontalAlignment: Text.AlignHCenter
			verticalAlignment: Text.AlignVCenter
			font {
				pixelSize: Theme.fontSizeLarge
				family: Theme.fontFamilyHeading
			}
			color: Theme.rgba(Theme.highlightColor, 0.6)
			visible: girlView.model.count === 0
			text: qsTr("No girls yet")
		}
	}

	onStatusChanged: {
		if (status === PageStatus.Activating && updateAfterManage) {
			updateAfterManage = false;
			//console.log("Activating");
			Ql.on(girlsModel).at(girlView.currentIndex, function(girl) {
				page.fillGirlInfo(girl);
			}).empty(function() {
				appWindow.coverInfo = undefined;
				dateColumn.pickerGirlInfo = undefined;
			});
		}
	}

	ListModel {
		id: girlsModel
	}

	function fillGirlInfo(g) {
		var colors = [];
		var opacitys = [];
		var icons = [];
		colors[g.cycle] = undefined;
		opacitys[g.cycle] = undefined;
		icons[g.cycle] = undefined;

		if (g.pms > Algo.PMS_OFF) {
			Ql.ng().loop(g.cycle - g.pms, g.pms, function(i, p) {
				colors[i] = Algo.PMS_COLOR;
				opacitys[i] = (p / g.pms) * 0.5 + 0.1;
			});
		}

		Ql.ng().loop(0, Algo.MN_DAYS, function(i, p) {
			colors[i] = Algo.MN_COLOR;
			opacitys[i] = (Algo.MN_DAYS + 1 - p) / Algo.MN_DAYS * 0.6 + 0.2;
		});
		Ql.ng().loop(g.cycle - Algo.OV_DAYS_BEFORE - Algo.OV_DAYS_SPAN, Algo.OV_DAYS, function(i, p) {
			colors[i] = Algo.OV_COLOR;
			var o = 0.75;
			if (p < Algo.OV_DAYS_SPAN) {
				o = p / Algo.OV_DAYS_SPAN;
			} else if (p > Algo.OV_DAYS_SPAN) {
				o = (Algo.OV_DAYS_SPAN*2 - p) / Algo.OV_DAYS_SPAN;
			}
			opacitys[i] = o + 0.15;
		});

		var coverColor = Theme.rgba('#a0a0a0', 0.6);
		if (colors[g.dayInCycle - 1]) {
			coverColor = Theme.rgba(colors[g.dayInCycle - 1], opacitys[g.dayInCycle - 1]);
		}

		//TBD Persistence.noteIcons(icons, g.dbid);
		//console.log(icons);
		dateColumn.pickerGirlInfo = {
			colorArr: colors,
			opacityArr: opacitys,
			iconArr: icons,
			cycle: g.cycle,
			day1ms: g.day1ms
		}

		appWindow.coverInfo = {
			name: g.name,
			color: coverColor,
			dayInCycle: g.dayInCycle,
			nextOv: g.coverOv,
			nextMn: g.coverMn
		}

		/*console.log(g.name);
		console.log(colors);
		console.log(opacitys);*/
	}

	Component.onCompleted: {
		Persistence.initialize();
		Persistence.populateGirls(girlsModel);

		var curDayMS = Algo.todayMS();

		Ql.on(girlsModel).each(function(g, i) {
			var _daysInCycle = Algo.daysInCycle(g.cycle, g.day1ms, curDayMS);
			var ov = Algo.nextOvDays(_daysInCycle, g.cycle);
			var mn = Algo.nextMnDays(_daysInCycle, g.cycle);
			var today = Algo.formatDays(0);

			girlsModel.setProperty(i, "dayInCycle", _daysInCycle + 1);
			girlsModel.setProperty(i, "nextOv", Algo.formatDays(ov));
			girlsModel.setProperty(i, "coverOv", ov === 0? today : String(ov));
			girlsModel.setProperty(i, "nextMn", Algo.formatDays(mn));
			girlsModel.setProperty(i, "coverMn", mn === 0? today : String(mn));
			girlsModel.setProperty(i, "noteTitle", Persistence.noteTitle(g.dbid, _daysInCycle));
		}).first(function(girl) {
			fillGirlInfo(girl);
		});
		girlView.model = girlsModel;
	}
}


