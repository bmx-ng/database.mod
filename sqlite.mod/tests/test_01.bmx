SuperStrict

Framework Database.SQLite
Import BRL.filesystem
Import brl.standardio

DeleteFile("maxtest.db")

Local db:TDBConnection = LoadDatabase("SQLITE", "maxtest.db")

If Not db Then
	Print("Didn't work...")
	End
End If

Local names:String[][] = [ ..
	[ "Alfred", "Aho" ],   ..
	[ "Brian", "Kernighan" ], ..
	[ "Peter", "Weinberger" ] ]

If db.isOpen() Then

	Local s:String = "CREATE TABLE person (id integer primary key AUTOINCREMENT, " + ..
	  " forename varchar(30)," + ..
	  " surname varchar(30) )"

	db.executeQuery(s)

	If db.hasError() Then
		errorAndClose(db)
	End If
	
	' transaction test :-)
	db.StartTransaction()

	If db.hasError() Then
		errorAndClose(db)
	End If

	For Local i:Int = 0 Until names.length
		db.executeQuery("INSERT INTO person values (NULL, '" + names[i][0] + "', '" + names[i][1] + "')")
		If db.hasError() Then
			errorAndClose(db)
		End If
		
	Next
	
	' commit our changes :-)
	db.Commit()

	If db.hasError() Then
		errorAndClose(db)
	End If

	Local query:TDatabaseQuery = db.executeQuery("SELECT * from person")
	If db.hasError() Then
		errorAndClose(db)
	End If

	While query.nextRow()
		Local record:TQueryRecord = query.rowRecord()
		
		Print("Name = " + TDBString(record.value(1)).value + " " + TDBString(record.value(2)).value)
	Wend
	
			
	db.close()
	
End If

Function errorAndClose(db:TDBConnection)
	Print(db.error().toString())
	db.close()
	End
End Function
