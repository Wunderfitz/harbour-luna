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
import "Algo.js" as Algo
import "Persistence.js" as Persistence

Page {
	id: page

	property var lunaInfo

	property bool _search: false
	property string _searchString: ''
	property var _clipboard
	property int _daysInCycle

	signal currentNoteChanged(string newTitle)

    Component {
		id: noteDelegate

		ListItem {
			id: listItem

		   // width: timeLabel.x + timeLabel.width
			//height: Theme.itemSizeSmall // 2 + 2
			function updateNote(noteInfo, idx) {
				notesModel.set(idx, {
					"dbid": noteInfo.dbid,
					"lunaId": lunaInfo.dbid,
					"title": noteInfo.title,
					"note": noteInfo.note,
					"idx": idx
				});
			}

			onClicked: {
				var prop = {
						noteInfo: model,
						idx: model.index
					}

				var dialog = pageStack.push(Qt.resolvedUrl("EditNoteDlg.qml"), prop);
					dialog.accepted.connect(function() {
						updateNote(dialog.noteInfo, model.index);
						page._clipboard = undefined;
				});
			}

			Rectangle {
				id: timeRect
				width: page.width;
				height: parent.height
				color: Theme.primaryColor;
				opacity: 0.05
				visible: !(index & 1)
			}

			Label {
				id: timeLabel
				x: Theme.paddingMedium
				height: parent.height
				verticalAlignment: Text.AlignVCenter
				font.pixelSize: Theme.fontSizeSmall
				font.bold: index == page._daysInCycle
				color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
				opacity: (index & 1) ? 0.4 : 0.6
				text: model.index < 9? "0" + (model.index + 1) : model.index + 1
			}
			Label {
				id: titleLabel
				x: Theme.paddingMedium * 4
				height: parent.height
				verticalAlignment: Text.AlignVCenter
				font.pixelSize: Theme.fontSizeMedium
				//opacity: (index & 1) ? 0.4 : 0.6
				color: model.searchMatch? Theme.highlightColor
									: (listItem.highlighted ? Theme.highlightColor : Theme.primaryColor)
				text: model.title
			}
			menu: ContextMenu {
				id: itemMenu
				property bool _canPaste: false
				property bool _canCopy: true
				property bool _canClear: true
				MenuItem {
					text: qsTr("Paste")
					visible: itemMenu._canPaste
					onClicked: {
						page._clipboard.idx = model.index;
						if (model.dbid > 0) {
							page._clipboard.dbid = model.dbid;
							Persistence.updateNote(page._clipboard);
						} else {
							var dbid = Persistence.persistNote(page._clipboard);
							page._clipboard.dbid = parseInt(dbid);
						}
						listItem.updateNote(page._clipboard, model.index);
					}
				}
				MenuItem {
					text: qsTr("Copy")
					enabled: itemMenu._canCopy
					onClicked: {
						page._clipboard = {}
						Ql.on(model).each(function(v,k) {
							page._clipboard[k]=v;
						});
					}
				}
				MenuItem {
					text: qsTr("Clear")
					enabled: itemMenu._canClear
					onClicked: {
						var dbid = model.dbid;
						var idx = model.index;
						remorseAction(qsTr("Clearing"), function() {
							Persistence.removeNote(dbid);
							listItem.updateNote(Algo.emptyNoteInfo(0), idx);
						});
					}
				}
				onActiveChanged: {
					if (active) {
						itemMenu._canPaste = page._clipboard !== undefined;
						itemMenu._canCopy = model.dbid > 0
								&& (page._clipboard === undefined || page._clipboard.dbid !== model.dbid);
						itemMenu._canClear = model.dbid > 0;
					}
				}
			}
		}
    }

    ListModel {
        id: notesModel
    }

	on_SearchStringChanged: {
		//console.log(_searchString)
		Ql.on(notesModel).each(function(v, i) {
			var searchMatch = false;
			if (_searchString.length > 0) {
				searchMatch = v.title.toLowerCase().indexOf(_searchString) !== -1
					|| v.note.toLowerCase().indexOf(_searchString) !== -1
			}
			notesModel.setProperty(i, "searchMatch", searchMatch);
		});
	}

    SilicaListView {
		id: listView
		anchors.fill: parent

		header: Column {
			width: page.width

			PageHeader {
				title: qsTr("Notes")
			}
			Item {
				width: parent.width
				height: page._search? searchField.height : 0
				clip: true
				SearchField {
					id: searchField
					width: parent.width
					placeholderText: qsTr("Highlight Notes")
					//visible: page._search
					autoScrollEnabled: false
					visible: opacity > 0
					opacity: page._search? 1 : 0
					z: 2

					Binding {
						target: page
						property: "_searchString"
						value: searchField.text.toLowerCase().trim()
					}
					Behavior on opacity {
						FadeAnimation {
							duration: 150
						}
					}

					Keys.onReturnPressed: page.focus = true
					Keys.onEnterPressed: page.focus = true
				}
				Behavior on height {
					NumberAnimation {
						duration: 150
						easing.type: Easing.InOutQuad
					}
				}
			}
		}
		PullDownMenu {
			MenuItem {
				text: qsTr("Toggle Search")
				onClicked: {
					page._search = !page._search
					page.focus = true
				}
			}
		}

		model: notesModel

		delegate: noteDelegate

		VerticalScrollDecorator {}
	}


    Component.onCompleted: {

		Ql.ng().range(lunaInfo.cycle, function(idx) {
			notesModel.append(Algo.emptyNoteInfo(lunaInfo.dbid, idx));
        });

		Persistence.populateNotes(notesModel, lunaInfo.dbid);

		Ql.on(notesModel).each(function(v, i) {
			notesModel.setProperty(i, "searchMatch", false);
		});
		_daysInCycle = lunaInfo.dayInCycle - 1;
    }

	onStatusChanged: {
		//console.log(status)
		if (status === PageStatus.Inactive) {
			var pop = pageStack.find(function(_page) {
				return _page === page;
			});
			//console.log(pop);
			if(!pop) {
				var noteInfo = notesModel.get(lunaInfo.dayInCycle - 1);
				console.log(noteInfo.title);
				if (lunaInfo.noteTitle !== noteInfo.title) {
					currentNoteChanged(noteInfo.title)
				}
			}

		}
	}
}
