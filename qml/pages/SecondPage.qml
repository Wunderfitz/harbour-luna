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

    property var lunasModel

	signal lunaSelected(int index)

	function addOrUpdateLuna(g, idx) {
		//console.log(g, idx);
		var _daysInCycle = Algo.daysInCycle(g.cycle, g.day1ms);
		g.dayInCycle = _daysInCycle + 1;
		var ov = Algo.nextOvDays(_daysInCycle, g.cycle)
		var mn = Algo.nextMnDays(_daysInCycle, g.cycle);
		var today = Algo.formatDays(0);

		g.nextOv = Algo.formatDays(ov);
		g.coverOv = ov === 0? today : String(ov)
		g.nextMn = Algo.formatDays(mn);
		g.coverMn = mn === 0? today : String(mn)
		if (idx >= 0) {
			g.noteTitle = Persistence.noteTitle(g.dbid, _daysInCycle);
            lunasModel.set(idx, g)
		} else {
            lunasModel.append(g);
		}
	}

	SilicaListView {
		id: listView
        model: lunasModel
		anchors.fill: parent

		ListView.onRemove: animateRemoval(delegate)

		PullDownMenu {
			MenuItem {
                text: qsTr("New Profile")
				onClicked:{
					var dialog = pageStack.push(Qt.resolvedUrl("EditLunaDlg.qml"));
                    dialog.accepted.connect(function() {
						addOrUpdateLuna(dialog.lunaInfo);
					});
				}
			}
		}

		header: PageHeader {
            title: qsTr("Profiles")
		}
		delegate: ListItem {
			id: delegate
			menu: contextMenu

			Label {
				x: Theme.paddingLarge
				text: model.name
				anchors.verticalCenter: parent.verticalCenter
				color: delegate.highlighted ? Theme.highlightColor : Theme.primaryColor
			}

			onClicked: {
				lunaSelected(model.index)
				pageStack.pop();
			}

			RemorseItem { id: remorse }

			function propLunaInfo(idx) {
				var _lunaInfo = {};
                Ql.on(page.lunasModel.get(index)).each(function(v, k){
					//console.log(k,v);
					_lunaInfo[k] = v;
				});
				return {lunaInfo: _lunaInfo};
			}

			function manageNotes() {
				var dialog = pageStack.push(Qt.resolvedUrl("NotesPage.qml"), propLunaInfo(index));
				dialog.currentNoteChanged.connect(function(newTitle) {
					console.log(index, newTitle);
                    lunasModel.setProperty(index, "noteTitle", newTitle);
				});
			}

			function editLuna() {
				var dialog = pageStack.push(Qt.resolvedUrl("EditLunaDlg.qml"),
                        {lunaInfo: page.lunasModel.get(index)});
				dialog.accepted.connect(function() {
					//console.log(dialog.lunaInfo);
					addOrUpdateLuna(dialog.lunaInfo, index);
				});
			}

			function deleteLuna() {
				var idx = index;
				var dbid = model.dbid;
				remorseAction(qsTr("Deleting"), function() {
                    page.lunasModel.remove(idx);
					Persistence.removeLuna(dbid);
					Persistence.removeLunaNotes(dbid);
				});
			}

			Component {
				id: contextMenu
				ContextMenu {
					id: itemInfo

					MenuItem {
						text: qsTr("Manage day notes")
						onClicked: manageNotes()
					}
					MenuItem {
						text: qsTr("Edit")
						onClicked: editLuna()
					}
					MenuItem {
						text: qsTr("Delete")
						onClicked: deleteLuna()
					}
				}
			}
		}
		VerticalScrollDecorator {}
	}
	ViewPlaceholder {
        enabled: lunasModel.count === 0
        text: qsTr("No profiles yet")
		hintText: qsTr("Pull down to add one")
	}
}
