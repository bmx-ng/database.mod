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


If db.isOpen() Then

	db.executeQuery("DROP TABLE if exists nulltest")
	
	Local s:String = "CREATE TABLE if not exists nulltest ( " + ..
	  " c1 varchar(30)," + ..
	  " c2 int, c3 float )"

	db.executeQuery(s)

	If db.hasError() Then
		errorAndClose(db)
	End If
	
	db.executeQuery("INSERT INTO nulltest VALUES('hello', 1, 5)")
	db.executeQuery("INSERT INTO nulltest VALUES('world', 2, 10)")

	Local query:TDatabaseQuery = TDatabaseQuery.Create(db)
	query.Prepare("UPDATE nulltest SET c3=? WHERE c2=?")
	
	query.BindValue(0, TDBFLoat.Set(1))
	query.BindValue(1, TDBInt.Set(1))
	
	query.Execute()
	
	query.BindValue(0, New TDBFLoat())
	query.BindValue(1, TDBInt.Set(1))
	
	query.Execute()
	
	
	db.close()
	
End If

Function errorAndClose(db:TDBConnection)
	Print(db.error().toString())
	db.close()
	End
End Function

