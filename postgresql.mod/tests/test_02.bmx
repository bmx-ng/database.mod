SuperStrict

Framework Database.PostgreSQL
Import BRL.StandardIO

Local db:TDBConnection = LoadDatabase("POSTGRESQL", "maxtest", "localhost", 0, "user", "pass")

If Not db Then
	Print "Didn't work..."
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

	db.executeQuery("DROP TABLE person")
	db.executeQuery("DROP SEQUENCE person_id")
	
	' create the auto-incrementing field
	db.executeQuery("CREATE SEQUENCE person_id INCREMENT 1 START 1")
	
	' id field assigned to sequence
	Local s:String = "CREATE TABLE person (id integer primary key DEFAULT NEXTVAL('person_id'), " + ..
	  " forename varchar(30)," + ..
	  " surname varchar(30) )"

	db.executeQuery(s)

	If db.hasError() Then
		errorAndClose(db)
	End If

	' get a new query object 
	Local query:TDatabaseQuery = TDatabaseQuery.Create(db)

	' prepare the insert statement
	' by preparing it once, the database can reuse it on succesive inserts which is more efficient.
	query.prepare("INSERT INTO person (forename, surname) values ($1, $2)")
	
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
		
		Print "Name = " + record.getString(1) + " " + record.getString(2)
	Wend
	
			
	db.close()
	
End If

Function errorAndClose(db:TDBConnection)
	Print db.error().toString()
	db.close()
	End
End Function


