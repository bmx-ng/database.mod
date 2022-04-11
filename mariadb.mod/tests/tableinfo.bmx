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

	Local table:TDBTable = db.getTableInfo("person", True)

	If table Then	
		Print "name = " + table.name
		For Local i:Int = 0 Until table.columns.length
			Print i + " : " + table.columns[i].name
		Next
		Print "DDL : ~n" + table.ddl
	Else
		Print "No table information found"
	End If

	db.close()
	
End If

Function errorAndClose(db:TDBConnection)
	Print(db.error().toString())
	db.close()
	End
End Function


