SuperStrict

Framework Database.MariaDB
Import BRL.filesystem
Import BRL.StandardIO

Local db:TDBConnection = LoadDatabase("MARIADB", "maxtest", Null, 0, "brucey", "brucey")

If Not db Then
	Print("Didn't work...")
	End
End If

If db.hasError() Then
	errorAndClose(db)
End If


Local names:String[][] = [ ..
	[ "Alfred", "Aho" ],   ..
	[ "Brian", "Kernighan" ], ..
	[ "Peter", "Weinberger" ] ]

If db.isOpen() Then

	db.executeQuery("DROP TABLE if exists person")
	
	Local s:String = "CREATE TABLE if not exists person (id integer primary key AUTO_INCREMENT, " + ..
	  " forename varchar(30)," + ..
	  " surname varchar(30), stamp datetime )"

	db.executeQuery(s)

	If db.hasError() Then
		errorAndClose(db)
	End If

	For Local i:Int = 0 Until names.length
		Local query:TDatabaseQuery = db.executeQuery("INSERT INTO person values (NULL, '" + names[i][0] + "', '" + names[i][1] + "', now())")

		Print "LastInserted id = " + query.lastInsertedId()
		
		If db.hasError() Then
			errorAndClose(db)
		End If
	Next

	Local query:TDatabaseQuery = db.executeQuery("SELECT * from person")
	If db.hasError() Then
		errorAndClose(db)
	End If

	While query.nextRow()
		Local record:TQueryRecord = query.rowRecord()
		
		Print(record.getInt(0) + ". Name = " + record.getString(1) + " " + record.getString(2))
		Print TDBDateTime(record.value(3)).format()
	Wend
	
			
	db.close()
	
End If

Function errorAndClose(db:TDBConnection)
	Print(db.error().toString())
	db.close()
	End
End Function
