// Persistence.js
.import QtQuick.LocalStorage 2.0 as PersistenceLS

// First, let's create a short helper function to get the database connection
function database() {
	return PersistenceLS.LocalStorage.openDatabaseSync("luna", "1.0", "PersistenceDatabase", 100000);
}

// At the start of the application, we can initialize the tables we need if they haven't been created yet
function initialize() {
	database().transaction(
		function(tx,er) {
			// Creates tables if it doesn't already exist
			tx.executeSql('CREATE TABLE IF NOT EXISTS lunas(dbid INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, cycle INTEGER, day1ms BIGINT, pms INTEGER)');

			tx.executeSql('CREATE TABLE IF NOT EXISTS notes(dbid INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, note TEXT, icon INTEGER, lunaId INTEGER, idx INTEGER)');
		});
}

function populateLunas(model) {
	database().readTransaction(function(tx) {
		var rs = tx.executeSql("SELECT * FROM lunas ORDER BY name");
		for (var i = 0; i < rs.rows.length; i++) {
			model.append(rs.rows.item(i));
		}
	});
}

function persistLuna(g) {
	var res = "";
	database().transaction(function(tx) {
		var rs = tx.executeSql("INSERT INTO lunas (name, cycle, day1ms, pms) VALUES (?, ?, ?, ?)", [g.name, g.cycle, g.day1ms, g.pms]);
		if (rs.rowsAffected === 0) {
			res = "Error";
		} else {
			res = rs.insertId;
		}
	});
	return res;
}

function updateLuna(g) {
	database().transaction(function(tx) {
		tx.executeSql("UPDATE lunas SET name=?, cycle=?, day1ms=?, pms=? WHERE dbid=?", [g.name, g.cycle, g.day1ms, g.pms, g.dbid]);
	});
}

function removeLuna(dbid) {
	var res = "";
	database().transaction(function(tx) {
		res = "OK";
		var rs = tx.executeSql("DELETE FROM lunas WHERE dbid=?", [dbid]);
		if (rs.rowsAffected === 0) {
			res = "Error";
		}
	});
	return res;
}

function removeAllLunas() {
	var res = "";
	database().transaction(function(tx) {
		res = "OK";
		var rs = tx.executeSql("DELETE FROM lunas");
		if (rs.rowsAffected === 0) {
			res = "Error";
		}
	});
	return res;
}

function populateNotes(model, lunaId) {
	database().readTransaction(function(tx) {
		var rs = tx.executeSql("SELECT * FROM notes WHERE lunaId = ?", [lunaId]);
		for (var i = 0; i < rs.rows.length; i++) {
			var row = rs.rows.item(i);
			if (model.count > row.idx) {
				model.set(row.idx, row);
			}
		}
	});
}

function noteIcons(iconArr, lunaId) {
	database().readTransaction(function(tx) {
		var rs = tx.executeSql("SELECT idx, icon FROM notes WHERE lunaId=?", [lunaId]);
		for (var i = 0; i < rs.rows.length; i++) {
			var row = rs.rows.item(i);
			if (iconArr.length > row.idx) {
				iconArr[row.idx] = row.icon;
			}
		}
	});
}

function noteTitle(lunaId, idx) {
	var res = "";
	database().readTransaction(function(tx) {
		res = "OK";
		var rs = tx.executeSql("SELECT title FROM notes WHERE lunaId=? AND idx=?", [lunaId, idx]);
		if (rs.rows.length === 1) {
			res = rs.rows.item(0).title;
		} else {
			res = "";
		}
	});
	return res;
}

function note(lunaId, idx) {
	var res = "";
	database().readTransaction(function(tx) {
		res = "OK";
		var rs = tx.executeSql("SELECT * FROM notes WHERE lunaId=? AND idx=?", [lunaId, idx]);
		if (rs.rows.length === 1) {
			res = rs.rows.item(0);
		} else {
			res = "";
		}
	});
	return res;
}

function persistNote(n) {
	var res = "";
	database().transaction(function(tx) {
		var rs = tx.executeSql("INSERT INTO notes (title, note, icon, lunaId, idx) VALUES (?, ?, ?, ?, ?)", [n.title, n.note, n.icon, n.lunaId, n.idx]);
		if (rs.rowsAffected === 0) {
			res = "Error";
		} else {
			res = rs.insertId;
		}
	});
	return res;
}

function updateNote(n) {
	database().transaction(function(tx) {
		tx.executeSql("UPDATE notes SET title=?, note=?, icon=? WHERE dbid=?", [n.title, n.note, n.icon, n.dbid]);
	});
}

function removeNote(dbid) {
	var res = "";
	database().transaction(function(tx) {
		res = "OK";
		var rs = tx.executeSql("DELETE FROM notes WHERE dbid=?", [dbid]);
		if (rs.rowsAffected === 0) {
			res = "Error";
		}
	});
	return res;
}

function removeLunaNotes(lunaId) {
	var res = "";
	database().transaction(function(tx) {
		res = "OK";
		var rs = tx.executeSql("DELETE FROM notes WHERE lunaId=?", [lunaId]);
		if (rs.rowsAffected === 0) {
			res = "Error";
		}
	});
	return res;
}
