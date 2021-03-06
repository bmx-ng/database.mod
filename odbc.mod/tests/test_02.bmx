SuperStrict

Framework Database.ODBC
Import BRL.StandardIO

'                                             database                                   dsn name
Local db:TDBConnection = LoadDatabase("ODBC", "maxtest", Null, Null, "brucey", "brucey", "maxtest")

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

	' we don't care if the drop table fails, since it might not exist yet...
	db.executeQuery("DROP TABLE person")

	' Create a new table
	Local s:String = "CREATE TABLE if not exists person (id integer primary key AUTO_INCREMENT, " + ..
	  " forename varchar(30)," + ..
	  " surname varchar(30) )"

	db.executeQuery(s)

	If db.hasError() Then
		errorAndClose(db)
	End If

	' get a new query object 
	Local query:TDatabaseQuery = TDatabaseQuery.Create(db)
'DebugStop
	' prepare the insert statement
	' by preparing it once, the database can reuse it on succesive inserts which is more efficient.
	query.prepare("INSERT INTO person values (NULL, ?, ?)")
	
	If db.hasError() Then
		errorAndClose(db)
	End If

	' iterate round the array inserting new entries
	For Local i:Int = 0 Until names.length
		query.bindValue(0, TDBString.Set(names[i][0]))
		query.bindValue(1, TDBString.Set(names[i][1]))

		query.execute()
		
		If db.hasError() Then
			errorAndClose(db)
		End If
	Next
	
	' select
	query = db.executeQuery("SELECT * from person")
	If db.hasError() Then
		errorAndClose(db)
	End If

	While query.nextRow()
		Local record:TQueryRecord = query.rowRecord()
		
		Print("Name = " + record.value(1).getString() + " " + record.value(2).getString())
	Wend
	
			
	db.close()
	
End If

Function errorAndClose(db:TDBConnection)
	Print(db.error().toString())
	db.close()
	End
End Function


