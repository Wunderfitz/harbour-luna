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
			tx.executeSql('CREATE TABLE IF NOT EXISTS girls(dbid INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, cycle INTEGER, day1ms BIGINT, pms INTEGER)');

			tx.executeSql('CREATE TABLE IF NOT EXISTS notes(dbid INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, note TEXT, icon INTEGER, girlId INTEGER, idx INTEGER)');
		});
}

function populateGirls(model) {
	database().readTransaction(function(tx) {
		var rs = tx.executeSql("SELECT * FROM girls ORDER BY name");
		for (var i = 0; i < rs.rows.length; i++) {
			model.append(rs.rows.item(i));
		}
	});
}

function persistGirl(g) {
	var res = "";
	database().transaction(function(tx) {
		var rs = tx.executeSql("INSERT INTO girls (name, cycle, day1ms, pms) VALUES (?, ?, ?, ?)", [g.name, g.cycle, g.day1ms, g.pms]);
		if (rs.rowsAffected === 0) {
			res = "Error";
		} else {
			res = rs.insertId;
		}
	});
	return res;
}

function updateGirl(g) {
	database().transaction(function(tx) {
		tx.executeSql("UPDATE girls SET name=?, cycle=?, day1ms=?, pms=? WHERE dbid=?", [g.name, g.cycle, g.day1ms, g.pms, g.dbid]);
	});
}

function removeGirl(dbid) {
	var res = "";
	database().transaction(function(tx) {
		res = "OK";
		var rs = tx.executeSql("DELETE FROM girls WHERE dbid=?", [dbid]);
		if (rs.rowsAffected === 0) {
			res = "Error";
		}
	});
	return res;
}

function removeAllGirls() {
	var res = "";
	database().transaction(function(tx) {
		res = "OK";
		var rs = tx.executeSql("DELETE FROM girls");
		if (rs.rowsAffected === 0) {
			res = "Error";
		}
	});
	return res;
}

function populateNotes(model, girlId) {
	database().readTransaction(function(tx) {
		var rs = tx.executeSql("SELECT * FROM notes WHERE girlId = ?", [girlId]);
		for (var i = 0; i < rs.rows.length; i++) {
			var row = rs.rows.item(i);
			if (model.count > row.idx) {
				model.set(row.idx, row);
			}
		}
	});
}

function noteIcons(iconArr, girlId) {
	database().readTransaction(function(tx) {
		var rs = tx.executeSql("SELECT idx, icon FROM notes WHERE girlId=?", [girlId]);
		for (var i = 0; i < rs.rows.length; i++) {
			var row = rs.rows.item(i);
			if (iconArr.length > row.idx) {
				iconArr[row.idx] = row.icon;
			}
		}
	});
}

function noteTitle(girlId, idx) {
	var res = "";
	database().readTransaction(function(tx) {
		res = "OK";
		var rs = tx.executeSql("SELECT title FROM notes WHERE girlId=? AND idx=?", [girlId, idx]);
		if (rs.rows.length === 1) {
			res = rs.rows.item(0).title;
		} else {
			res = "";
		}
	});
	return res;
}

function note(girlId, idx) {
	var res = "";
	database().readTransaction(function(tx) {
		res = "OK";
		var rs = tx.executeSql("SELECT * FROM notes WHERE girlId=? AND idx=?", [girlId, idx]);
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
		var rs = tx.executeSql("INSERT INTO notes (title, note, icon, girlId, idx) VALUES (?, ?, ?, ?, ?)", [n.title, n.note, n.icon, n.girlId, n.idx]);
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

function removeGirlNotes(girlId) {
	var res = "";
	database().transaction(function(tx) {
		res = "OK";
		var rs = tx.executeSql("DELETE FROM notes WHERE girlId=?", [girlId]);
		if (rs.rowsAffected === 0) {
			res = "Error";
		}
	});
	return res;
}

