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
import "Persistence.js" as Persistence
import "Qlecti.js" as Ql

Dialog {
	id: page

    property var noteInfo
	property var idx

	DialogHeader {
		id: header
		title: qsTr("Edit day note")
		onPressed: {
			// force lose focus if title pressed
			if (note.editor.activeFocus) {
				page.focus = true;
			}
		}
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
				id: title
				property string safeText: ''

				width: parent.width
				placeholderText: qsTr("Enter title")
				label: qsTr("Title")
				maximumLength: 20
				EnterKey.iconSource: "image://theme/icon-m-enter-next"
				EnterKey.onClicked: note.focus = true
				onTextChanged: {
					if (text.length > maximumLength) {
						safeText = text.substring(0, maximumLength)
						color = 'red'
					} else {
						safeText = text
						color = Theme.primaryColor
					}
				}
			}
			/* TBD ComboBox {
				label: "Icon"
				menu: ContextMenu {
					MenuItem {
						property string _img: "image://theme/icon-m-alarm"

						text: "automatic";
						Image {
							anchors.right: parent.right
							anchors.verticalCenter: parent.verticalCenter
							source: _img
						}
					}
					MenuItem { text: "manual" }
					MenuItem { text: "high" }
				}
			}*/
			TextArea {
				id: note
				width: parent.width
				height: Math.max(page.width/3, implicitHeight)
				placeholderText: qsTr("Enter note")
				//label: qsTr("Title")
			}
		}
		VerticalScrollDecorator {}
	}

    Component.onCompleted: {
        if (noteInfo) {
			title.text = noteInfo.title || '';
			note.text = noteInfo.note || '';
        }
    }

	canAccept: String(title.text).trim() !== "";

    onAccepted: {
        var update = false;
		var _noteInfo = {};
		Ql.on(noteInfo).each(function(v,k){
			_noteInfo[k]=v;
		});
		if (noteInfo.title !== String(title.safeText).trim()) {
            update = true;
			_noteInfo.title = String(title.safeText).trim();
			console.log(noteInfo.title, noteInfo);
        }
		if (noteInfo.note !== note.text) {
            update = true;
			_noteInfo.note = note.text;
        }
        if (update) {
			console.log(_noteInfo.dbid, _noteInfo.lunaId);
			if (_noteInfo.dbid > 0) {
				noteInfo['idx'] = idx;
				Persistence.updateNote(_noteInfo);
            } else {
				var dbid = Persistence.persistNote(_noteInfo);
				//console.log(dbid);
				_noteInfo['dbid'] = parseInt(dbid);
            }
			noteInfo = _noteInfo;
        }
    }
}
