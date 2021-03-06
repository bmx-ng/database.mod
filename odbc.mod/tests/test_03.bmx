SuperStrict

Framework Database.ODBC
Import BRL.StandardIO
Import BRL.RandomDefault

Type TPersonStuff
	Field forename:String
	Field surname:String
	Field dataInt:Int
	Field dataFloat:Float
	Field dataDouble:Double
	Field dataLong:Long
End Type


'                                             database                                   dsn name
Local db:TDBConnection = LoadDatabase("ODBC", "maxtest", Null, Null, "brucey", "brucey", "maxtest")

If Not db Then
	Print("Didn't work...")
	End
End If

If db.hasError() Then
	errorAndClose(db)
End If

If db.isOpen() Then

	' Load up some data for insertion...

	Local names:String[][] = [ ..
		[ "Alfred", "Aho" ],   ..
		[ "Brian", "Kernighan" ], ..
		[ "Peter", "Weinberger" ] ]
		
	Local pstuff:TPersonStuff[] = New TPersonStuff[names.length]
	For Local i:Int = 0 Until names.length
		pstuff[i] = New TPersonStuff
		pstuff[i].forename = names[i][0]
		pstuff[i].surname = names[i][1]
		pstuff[i].dataInt = Rnd(1, 10)
		pstuff[i].dataFloat = Rnd(1, 10)
		pstuff[i].dataDouble = Rnd(1, 10)
		pstuff[i].dataLong = Rnd(1, 100000000:Long)
	Next


	' we don't care if the drop table fails, since it might not exist yet...
	db.executeQuery("DROP TABLE person")

	' Create a new table
	Local s:String = "CREATE TABLE if not exists person (id integer primary key AUTO_INCREMENT, " + ..
	  " forename varchar(30), surname varchar(30), dataint integer, datafloat float, datadouble double, datalong bigint )"

	db.executeQuery(s)

	If db.hasError() Then
		errorAndClose(db)
	End If

	' get a new query object 
	Local query:TDatabaseQuery = TDatabaseQuery.Create(db)

	' prepare the insert statement
	' by preparing it once, the database can reuse it on succesive inserts which is more efficient.
	query.prepare("INSERT INTO person values (NULL, ?, ?, ?, ?, ?, ?)")
	
	If db.hasError() Then
		errorAndClose(db)
	End If

	' iterate round the array inserting new entries
	For Local i:Int = 0 Until names.length
		query.bindValue(0, TDBString.Set(pstuff[i].forename))
		query.bindValue(1, TDBString.Set(pstuff[i].surname))
		query.bindValue(2, TDBInt.Set(pstuff[i].dataInt))
		query.bindValue(3, TDBFloat.Set(pstuff[i].dataFloat))
		query.bindValue(4, TDBDouble.Set(pstuff[i].datadouble))
		query.bindValue(5, TDBLong.Set(pstuff[i].dataLong))
'DebugStop
		query.execute()
		
		If db.hasError() Then
			errorAndClose(db)
		End If
	Next
	
	' select
	query = db.executeQuery("SELECT * FROM person")
	If db.hasError() Then
		errorAndClose(db)
	End If

	While query.nextRow()
		Local record:TQueryRecord = query.rowRecord()
		
		Local i:Int = record.value(0).getInt() - 1
		Print(" IN  - " + pstuff[i].forename + " : " + pstuff[i].surname + " : " + pstuff[i].dataInt + ..
			" : " + pstuff[i].dataFloat + " : " + pstuff[i].dataDouble + " : " + pstuff[i].dataLong)
		
		Print(" OUT - " + record.value(1).getString() + " : " + record.value(2).getString() + ..
			" : " + record.value(3).getInt() + " : " + record.value(4).getFloat() + ..
			" : " + record.value(5).getDouble() + " : " + record.value(6).getLong() )
	Wend
	
			
	db.close()
	
End If

Function errorAndClose(db:TDBConnection)
	Print(db.error().toString())
	db.close()
	End
End Function



