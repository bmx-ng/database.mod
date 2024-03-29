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


If db.isOpen() Then

	' get a list of tables in the database
	Local list:String[] = db.getTables()
	
	If list Then
		For Local i:Int = 0 Until list.length
			Print "   " + (i + 1) + ".   " + list[i]
		Next
	End If

	db.close()
	
End If

Function errorAndClose(db:TDBConnection)
	Print db.error().toString()
	db.close()
	End
End Function

