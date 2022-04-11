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

	' Create a new table
	Local s:String = "CREATE TABLE if not exists person (id integer primary key AUTO_INCREMENT, " + ..
	  " forename varchar(30)," + ..
	  " surname varchar(30), stamp datetime, num integer )"

	db.executeQuery(s)

	If db.hasError() Then
		errorAndClose(db)
	End If

	' get a new query object 
	Local query:TDatabaseQuery = TDatabaseQuery.Create(db)

	' prepare the insert statement
	' by preparing it once, the database can reuse it on succesive inserts which is more efficient.
	query.prepare("INSERT INTO person values (NULL, ?, ?, ?, ?)")
	
	If db.hasError() Then
		errorAndClose(db)
	End If

	' iterate round the array inserting new entries
	For Local i:Int = 0 Until 3
		query.bindValue(0, TDBString.Set(names[i][0]))
		query.bindValue(1, TDBString.Set(names[i][1]))
		query.bindValue(2, TDBDateTime.Set(2007, 4 + i, 30, 10, 4, 16))
		query.bindValue(3, TDBInt.Set(i + 10))

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
		
		Print("Name = " + record.getString(1) + " " + record.getString(2))
		Print TDBDateTime(record.value(3)).format()
		Print record.getInt(4)
	Wend
	
			
	db.close()
	
End If

Function errorAndClose(db:TDBConnection)
	Print(db.error().toString())
	db.close()
	End
End Function


