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

	Local s:String = "CREATE TABLE person (id integer primary key AUTO_INCREMENT, " + ..
	  " forename varchar(30)," + ..
	  " surname varchar(30), bday date, thetime time, exact datetime )"

	db.executeQuery(s)

	If db.hasError() Then
		errorAndClose(db)
	End If

	For Local i:Int = 0 Until names.length
		db.executeQuery("INSERT INTO person values (NULL, '" + names[i][0] + "', '" + ..
			names[i][1] + "', '200" + i + "-01-01', '04:01:45', '2007-03-04 13:20:13')")
		If db.hasError() Then
			errorAndClose(db)
		End If
	Next

	Local query:TDatabaseQuery = TDatabaseQuery.Create(db)
	
	' prepare select
	query.prepare("SELECT * FROM person WHERE bday = ? and thetime > ? and exact < ?")
	
	If db.hasError() Then
		errorAndClose(db)
	End If

	query.bindValue(0, TDBDate.Set(2001, 1, 1))
	query.bindValue(1, TDBTime.Set(4, 0 ,0))
	query.bindValue(2, TDBDateTime.Set(2008, 1, 1, 10, 0, 0))

	query.execute()

	If db.hasError() Then
		errorAndClose(db)
	End If

	While query.nextRow()
		Local record:TQueryRecord = query.rowRecord()
		
		Print("Name = " + record.getString(1) + " " + record.getString(2) + " - " + ..
			record.getString(3) + " - " + record.getString(4) + " - " + record.getString(5))
	Wend
	
	
	db.close()
	
End If

Function errorAndClose(db:TDBConnection)
	Print(db.error().toString())
	db.close()
	End
End Function

