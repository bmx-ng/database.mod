' Copyright (c) 2007-2026, Bruce A Henderson
' All rights reserved.
'
' Redistribution and use in source and binary forms, with or without
' modification, are permitted provided that the following conditions are met:
'     * Redistributions of source code must retain the above copyright
'       notice, this list of conditions and the following disclaimer.
'     * Redistributions in binary form must reproduce the above copyright
'       notice, this list of conditions and the following disclaimer in the
'       documentation and/or other materials provided with the distribution.
'     * Neither the name of the author nor the
'       names of its contributors may be used to endorse or promote products
'       derived from this software without specific prior written permission.
'
' THIS SOFTWARE IS PROVIDED BY THE AUTHOR ''AS IS'' AND ANY
' EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
' WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
' DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
' DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
' (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
' LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
' ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
' (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
' SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
'
SuperStrict

Rem
bbdoc: Database Driver - PostgreSQL
about: A PostgreSQL database driver for #Database
End Rem
Module Database.PostgreSQL

ModuleInfo "Version: 1.06"
ModuleInfo "Author: Bruce A Henderson"
ModuleInfo "License: BSD"
ModuleInfo "Copyright: 2007-2026 Bruce A Henderson"
ModuleInfo "Modserver: BRL"

ModuleInfo "History: 1.06"
ModuleInfo "History: Changed macOS pkg-config path for libpq to not use specific version number"
ModuleInfo "History: Implemented tableExists() and getTableInfo() methods."
ModuleInfo "History: 1.05"
ModuleInfo "History: Linux/macOS uses pkg-config to configure libpq"
ModuleInfo "History: dll no longer provided for Windows - Ensure libpq.dll is in the path"
ModuleInfo "History: 1.04"
ModuleInfo "History: Update to latest postgres client library."
ModuleInfo "History: NG support."
ModuleInfo "History: 1.03"
ModuleInfo "History: isOpen() now checks the connection status."
ModuleInfo "History: Sets active to false when all rows read."
ModuleInfo "History: Resultset cleanup improvements."
ModuleInfo "History: Fixed prepared statement dealloc case issue."
ModuleInfo "History: Fixed invalid definition for float/double."
ModuleInfo "History: Added blob support."
ModuleInfo "History: Added date/time support."
ModuleInfo "History: 1.02"
ModuleInfo "History: Added hasPrepareSupport() and hasTransactionSupport() methods."
ModuleInfo "History: 1.01"
ModuleInfo "History: Fixed open() not closing if already open."
ModuleInfo "History: 1.00 Initial Release"

?macos
ModuleInfo "CC_OPTS: `pkg-config --cflags /opt/homebrew/opt/libpq/lib/pkgconfig/libpq.pc`"
ModuleInfo "LD_OPTS: `pkg-config --libs /opt/homebrew/opt/libpq/lib/pkgconfig/libpq.pc`"
?linux
ModuleInfo "CC_OPTS: `pkg-config --cflags libpq`"
ModuleInfo "LD_OPTS: `pkg-config --libs libpq`"
?win32x86
ModuleInfo "LD_OPTS: -L%PWD%/lib/win32x86"
?win32x64
ModuleInfo "LD_OPTS: -L%PWD%/lib/win32x64"
?

Import Database.Core

Import "common.bmx"



Type TDBPostgreSQL Extends TDBConnection

	Function Create:TDBConnection(dbname:String = Null, host:String = Null, ..
		port:Int = Null, user:String = Null, password:String = Null, ..
		server:String = Null, options:String = Null)
		
		Local this:TDBPostgreSQL = New TDBPostgreSQL
		
		this.init(dbname, host, port, user, password, server, options)
		
		If this._dbname Then
			this.open(user, password)
		End If
		
		Return this
		
	End Function

	Method close()
	
		If _isOpen Then
			If handle Then
				bmx_pgsql_PQfinish(handle)
				handle = Null
			End If
			
			_isOpen = False
		End If
	
	End Method

	Method isOpen:Int()
		If _isOpen Then
			' really check that the database is open
			If bmx_pgsql_PQstatus(handle) Then
				_isOpen = False
			End If
		End If
		
		Return _isOpen
	End Method
		
	Method commit:Int()

		If Not _isOpen Or Not handle Then
			Return False
		End If
		
		Local result:Byte Ptr = bmx_pgsql_PQexec(handle, "COMMIT")
		
		If Not result Or bmx_pgsql_PQresultStatus(result) <> PGRES_COMMAND_OK Then
			setError("Error committing transaction", bmx_pgsql_PQerrorMessage(handle), TDatabaseError.ERROR_TRANSACTION)
			bmx_pgsql_PQclear(result)
			Return False
		End If
		
		bmx_pgsql_PQclear(result)
		
		Return True
	End Method
	
	Method getTables:String[]() Override
		Local list:String[]

		If Not _isOpen Then
			Return list
		End If

		Local tables:TList = New TList
		Local query:TDatabaseQuery = TDatabaseQuery.Create(Self)

		Local sql:String = "SELECT c.relname " + ..
			"FROM pg_catalog.pg_class c " + ..
			"JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace " + ..
			"WHERE c.relkind IN ('r', 'p') " + ..
			"AND n.nspname NOT IN ('pg_catalog', 'information_schema') " + ..
			"AND n.nspname NOT LIKE 'pg_toast%' " + ..
			"ORDER BY c.relname"

		If query.execute(sql) Then
			While query.nextRow()
				tables.addLast(query.value(0).getString())
			Wend
		End If

		If tables.count() > 0 Then
			list = New String[tables.count()]
			Local i:Int
			For Local s:String = EachIn tables
				list[i] = s
				i:+1
			Next
		End If

		query.Free()
		Return list
	End Method

	Method tableExists:Int(tableName:String) Override
		If Not _isOpen Then
			Return False
		End If

		Local query:TDatabaseQuery = TDatabaseQuery.Create(Self)

		Local sql:String = "SELECT 1 " + ..
			"FROM pg_catalog.pg_class c " + ..
			"JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace " + ..
			"WHERE c.relkind IN ('r', 'p') " + ..
			"AND c.relname = $1 " + ..
			"AND pg_catalog.pg_table_is_visible(c.oid) " + ..
			"LIMIT 1"
		
		query.prepare(sql)
		query.addString(tableName)

		If query.execute() Then
			Local res:Int = query.nextRow()
			query.Free()
			Return res
		End If

		query.Free()

		Return False
	End Method

	Method getTableInfo:TDBTable(tableName:String, withDDL:Int = False) Override
		If Not _isOpen Then
			Return Null
		End If

		If Not tableExists(tableName) Then
			Return Null
		End If

		Local query:TDatabaseQuery = TDatabaseQuery.Create(Self)
		Local table:TDBTable

		Local sql:String = "SELECT " + ..
			"a.attname, " + ..
			"a.atttypid, " + ..
			"CASE WHEN a.attnotnull THEN 0 ELSE 1 END AS nullable, " + ..
			"pg_catalog.pg_get_expr(ad.adbin, ad.adrelid) AS default_value, " + ..
			"pg_catalog.format_type(a.atttypid, a.atttypmod) AS formatted_type, " + ..
			"pg_catalog.quote_ident(n.nspname) || '.' || pg_catalog.quote_ident(c.relname) AS qualified_name " + ..
			"FROM pg_catalog.pg_class c " + ..
			"JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace " + ..
			"JOIN pg_catalog.pg_attribute a ON a.attrelid = c.oid " + ..
			"LEFT JOIN pg_catalog.pg_attrdef ad ON ad.adrelid = c.oid AND ad.adnum = a.attnum " + ..
			"WHERE c.relkind IN ('r', 'p') " + ..
			"AND c.relname = $1 " + ..
			"AND pg_catalog.pg_table_is_visible(c.oid) " + ..
			"AND a.attnum > 0 " + ..
			"AND NOT a.attisdropped " + ..
			"ORDER BY a.attnum"

		query.prepare(sql)
		query.addString(tableName)

		If query.execute() Then
			table = New TDBTable
			table.name = tableName

			Local cols:TList = New TList
			Local ddlCols:TList = New TList
			Local qualifiedName:String

			For Local rec:TQueryRecord = EachIn query
				Local name:String = rec.GetString(0)
				Local nativeType:Int = rec.GetInt(1)
				Local dbType:Int = TPostgreSQLResultSet.dbTypeFromNative(Null, nativeType)
				Local nullable:Int = rec.GetInt(2)
				Local defaultValue:TDBType = rec.value(3)

				cols.AddLast(TDBColumn.Create(name, dbType, nullable, defaultValue))

				If withDDL Then
					qualifiedName = rec.GetString(5)

					Local line:String = "    " + QuoteIdent(name) + " " + rec.GetString(4)

					If Not nullable Then
						line:+ " NOT NULL"
					End If

					If defaultValue And Not defaultValue.isNull() Then
						line:+ " DEFAULT " + defaultValue.getString()
					End If

					ddlCols.AddLast(line)
				End If
			Next

			table.SetCountColumns(cols.count())

			Local i:Int
			For Local col:TDBColumn = EachIn cols
				table.SetColumn(i, col)
				i:+1
			Next

			If withDDL And ddlCols.count() > 0 Then
				table.ddl = "CREATE TABLE " + qualifiedName + " (~n"

				i = 0
				For Local line:String = EachIn ddlCols
					If i > 0 Then
						table.ddl:+ ",~n"
					End If
					table.ddl:+ line
					i:+1
				Next

				table.ddl:+ "~n);~n~n"
			End If

			cols.Clear()
			ddlCols.Clear()
		End If

		query.Free()
		Return table
	End Method

	Method open:Int(user:String = Null, pass:String = Null)
	
		If _isOpen Then
			close()
		End If
		
		If user Then
			_user = user
		End If
		
		If pass Then
			_password = pass
		End If
		
		Local count:Int = 0

		If _dbname Then count:+1
		If _host Then count:+1
		If _port Then count:+1
		If _user Then count:+1
		If _password Then count:+1

		Local keywords:Byte Ptr = bmx_pgsql_createStringArray(count + 1)
		Local values:Byte Ptr = bmx_pgsql_createStringArray(count + 1)
		Local i:Int
		Local s:Int

		If _dbname Then
			bmx_pgsql_setStringArrayValue(keywords, i, "dbname")
			bmx_pgsql_setStringArrayValue(values, i, _dbname)
			i:+1
		End If

		If _host Then
			bmx_pgsql_setStringArrayValue(keywords, i, "host")
			bmx_pgsql_setStringArrayValue(values, i, _host)
			i:+1
		End If

		If _port Then
			bmx_pgsql_setStringArrayValue(keywords, i, "port")
			bmx_pgsql_setStringArrayValue(values, i, String.FromInt(_port))
			i:+1
		End If

		If _user Then
			bmx_pgsql_setStringArrayValue(keywords, i, "user")
			bmx_pgsql_setStringArrayValue(values, i, _user)
			i:+1
		End If

		If _password Then
			bmx_pgsql_setStringArrayValue(keywords, i, "password")
			bmx_pgsql_setStringArrayValue(values, i, _password)
			i:+1
		End If

		handle = bmx_pgsql_PQconnectdbParams(keywords, values)

		bmx_pgsql_deleteStringArray(keywords, count)
		bmx_pgsql_deleteStringArray(values, count)

		_isOpen = True

		If Not handle Or bmx_pgsql_PQstatus(handle) Then

			setError("Error connecting to database '" + _dbname + "'", bmx_pgsql_PQerrorMessage(handle), TDatabaseError.ERROR_CONNECTION)
			If handle Then
				bmx_pgsql_PQfinish(handle)
				handle = Null
			End If
			_isOpen = False
			Return False

		End If

		Return True
	End Method

	Method rollback:Int()
	
		If Not _isOpen Or Not handle Then
			Return False
		End If
		
		Local result:Byte Ptr = bmx_pgsql_PQexec(handle, "ROLLBACK")
		
		If Not result Or bmx_pgsql_PQresultStatus(result) <> PGRES_COMMAND_OK Then
			setError("Error rolling back transaction", bmx_pgsql_PQerrorMessage(handle), TDatabaseError.ERROR_TRANSACTION)
			bmx_pgsql_PQclear(result)
			Return False
		End If
		
		bmx_pgsql_PQclear(result)
		
		Return True
	End Method
	
	Method startTransaction:Int()
	
		If Not _isOpen Or Not handle Then
			Return False
		End If
		
		Local result:Byte Ptr = bmx_pgsql_PQexec(handle, "BEGIN")
		
		If Not result Or bmx_pgsql_PQresultStatus(result) <> PGRES_COMMAND_OK Then
			setError("Error starting transaction", bmx_pgsql_PQerrorMessage(handle), TDatabaseError.ERROR_TRANSACTION)
			bmx_pgsql_PQclear(result)
			Return False
		End If
		
		bmx_pgsql_PQclear(result)
		
		Return True
	End Method

	Method databaseHandle:Byte Ptr()
		Return handle
	End Method
	
	Method createResultSet:TQueryResultSet()
		Return TPostgreSQLResultSet.Create(Self)
	End Method
	
	Method nativeErrorMessage:String(err:Int)
	End Method

	Method hasPrepareSupport:Int()
		Return True
	End Method

	Method hasTransactionSupport:Int()
		Return True
	End Method

	Function QuoteIdent:String(value:String)
		Return "~q" + value.Replace("~q", "~q~q") + "~q"
	End Function
End Type


Type TPostgreSQLResultSet Extends TQueryResultSet

	' a pointer to a PGResult
	Field pgResult:Byte Ptr
	' number of rows returned in the query
	Field _queryRows:Int

	Field _rowsAffected:Int
	
	Field _preparedStatementName:String

	Function Create:TQueryResultSet(db:TDBConnection, sql:String = Null)
		Local this:TPostgreSQLResultSet = New TPostgreSQLResultSet
		
		this.init(db, sql)
		this.rec = TQueryRecord.Create()
		
		Return this
	End Function
	
	Method Delete()
		If _preparedStatementName Then
			executeQuery("DEALLOCATE ~q" + _preparedStatementName + "~q")
			_preparedStatementName = Null
		End If
		cleanup()
	End Method

	Method clearResultSet()
		If pgResult Then
			bmx_pgsql_PQclear(pgResult)
			pgResult = Null
		End If
	End Method
	
	Method cleanup()
		clearResultSet()
		index = SQL_BeforeFirstRow
		_isActive = False
		_queryRows = -1
	End Method
	
	Method executeQuery:Int(statement:String)
		
		If Not conn.isOpen() Then
			Return False
		End If
		
		cleanup()
		
		pgResult = bmx_pgsql_PQexec(conn.handle, statement)
		
		If Not pgResult Then
			cleanup()
			Return False
		End If
		
		Local status:Int = bmx_pgsql_PQresultStatus(pgResult)
		
		Select status
			Case PGRES_TUPLES_OK
				' returned some row data... probably a select!?
				' how many ?
				_queryRows = bmx_pgsql_PQntuples(pgResult)
			Case PGRES_COMMAND_OK
				' success but returned nothing. insert, update, delete etc
				' nothing to see here...
				_queryRows = -1
			Default
				' an error!
				conn.setError("Error executing statement", bmx_pgsql_PQerrorMessage(conn.handle), TDatabaseError.ERROR_STATEMENT, 0)				
				cleanup()
				Return False
		End Select

		Local fieldCount:Int = bmx_pgsql_PQnfields(pgResult)

		initRecord(fieldCount)

		' PQcmdTuples returns an empty string for non-change statements, so we should
		' get a zero in here for selects...
		_rowsAffected = String.fromCString(bmx_pgsql_PQcmdTuples(pgResult)).toInt()

		' get the field descriptions
		If fieldCount <> 0 Then
			
			For Local i:Int = 0 Until fieldCount
				Local dtype:Int = bmx_pgsql_PQftype(pgResult, i)
				Local qf:TQueryField = TQueryField.Create(bmx_pgsql_PQfname(pgResult, i), dbTypeFromNative(Null, dtype))
				qf.length = bmx_pgsql_PQfsize(pgResult, i)
				qf.precision = bmx_pgsql_PQfmod(pgResult, i)
				qf.dtype = dtype
				' if length is -1, then precision field holds actual length value, and
				' precision should be ignored.
				If qf.length = -1 Then
					qf.length = qf.precision - 4
					qf.precision = -1
				End If
				
				rec.setField(i, qf)
				
			Next
		End If
		
		If _queryRows = -1 Then
			cleanup()
		Else
			_isActive = True
		End If
		
		Return True
	End Method

	Method initRecord(size:Int)

		If rec Then
			rec.clear()
	
			If size > 0 Then		
				rec.init(size)
			End If
		End If
		
		resetValues(size)
	End Method

	Method prepare:Int(statement:String)

		cleanup()
		
		If Not statement Or statement.length = 0 Then
			Return False
		End If
		
		If Not _preparedStatementName Then
			_preparedStatementName = "prep" + Self.toString()
		Else
			executeQuery("DEALLOCATE ~q" + _preparedStatementName + "~q")
			cleanup()
		End If
		
		pgResult = bmx_pgsql_PQprepare(conn.handle, _preparedStatementName, statement)

		If Not pgResult Then
			Return False
		End If
		
		If bmx_pgsql_PQresultStatus(pgResult) <> PGRES_COMMAND_OK Then
			conn.setError("Error preparing statement", bmx_pgsql_PQerrorMessage(conn.handle), TDatabaseError.ERROR_STATEMENT, 0)				
			cleanup()
			Return False
		End If

		Return True
	End Method
	
	Method execute:Int()
	
		cleanup()

		Local params:Byte Ptr
		Local lengths:Int Ptr
		Local formats:Int Ptr
		Local paramCount:Int
		Local length:Int
		Local s:String
		Local strings:Byte Ptr[]
		
		' BIND stuff
		Local values:TDBType[] = boundValues
		
		If values Then
			paramCount = values.length

			' ** NOTE **
			' PQdescribePrepared is only available in more recent additions.
			' It is useful in it lets us check validity of parameter count.
			' Otherwise we hope that the database catches any issues... :-/

			'Local result:Byte Ptr = bmx_pgsql_PQdescribePrepared(conn.handle, _preparedStatementName)
			
			'If bmx_pgsql_PQresultStatus(pgResult) <> PGRES_COMMAND_OK Then
			'	conn.setError("Error getting prepared statement details", convertUTF8toISO8859(bmx_pgsql_PQerrorMessage(conn.handle)), TDatabaseError.ERROR_STATEMENT, 0)				
			'	Return False
			'End If
			
			'If paramCount <> bmx_pgsql_PQnparams(result) Then
			'	conn.setError("Wrong number of bind parameters. Expected " + bmx_pgsql_PQnparams(result) + ..
			'		". Actual " + paramCount, Null, TDatabaseError.ERROR_STATEMENT, 0)				
			'	If result Then
			'		bmx_pgsql_PQclear(result)
			'	End If
			'	Return False
			'End If
			
			strings = New Byte Ptr[paramCount]
			params = bmx_pgsql_createParamValues(paramCount)
			lengths = bmx_pgsql_createParamInts(paramCount)
			formats = bmx_pgsql_createParamInts(paramCount)
			
			For Local i:Int = 0 Until paramCount
			
				If Not values[i] Or values[i].isNull() Then
					bmx_pgsql_setNullParam(params, i)
				Else
					
					Select values[i].kind()
						Case DBTYPE_BYTE
							s = String.FromInt(TDBByte(values[i]).value)
							strings[i] = s.toCString()
							bmx_pgsql_setParam(params, lengths, formats, i, strings[i], s.length)
						Case DBTYPE_SHORT
							s = String.FromInt(TDBShort(values[i]).value)
							strings[i] = s.toCString()
							bmx_pgsql_setParam(params, lengths, formats, i, strings[i], s.length)
						Case DBTYPE_INT
							s = String.fromInt(TDBInt(values[i]).value)
							strings[i] = s.toCString()
							bmx_pgsql_setParam(params, lengths, formats, i, strings[i], s.length)
						Case DBTYPE_UINT
							s = String.fromUInt(TDBUInt(values[i]).value)
							strings[i] = s.toCString()
							bmx_pgsql_setParam(params, lengths, formats, i, strings[i], s.length)
						Case DBTYPE_LONG
							s = String.fromLong(TDBLong(values[i]).value)
							strings[i] = s.toCString()
							bmx_pgsql_setParam(params, lengths, formats, i, strings[i], s.length)
						Case DBTYPE_ULONG
							s = String.fromULong(TDBULong(values[i]).value)
							strings[i] = s.toCString()
							bmx_pgsql_setParam(params, lengths, formats, i, strings[i], s.length)
						Case DBTYPE_FLOAT
							s = String.fromFloat(TDBFloat(values[i]).value)
							strings[i] = s.toCString()
							bmx_pgsql_setParam(params, lengths, formats, i, strings[i], s.length)
						Case DBTYPE_DOUBLE
							s = String.fromDouble(TDBDouble(values[i]).value)
							strings[i] = s.toCString()
							bmx_pgsql_setParam(params, lengths, formats, i, strings[i], s.length)
						Case DBTYPE_BLOB
							Local b:TDBBlob = TDBBlob(values[i])
							bmx_pgsql_setParamBinary(params, lengths, formats, i, b.value, b._size)
						Case DBTYPE_DATE
							s = TDBDate(values[i]).getString()
							strings[i] = s.toCString()
							bmx_pgsql_setParam(params, lengths, formats, i, strings[i], s.length)
						Case DBTYPE_DATETIME
							s = TDBDateTime(values[i]).getString()
							strings[i] = s.toCString()
							bmx_pgsql_setParam(params, lengths, formats, i, strings[i], s.length)
						Case DBTYPE_TIME
							s = TDBTime(values[i]).getString()
							strings[i] = s.toCString()
							bmx_pgsql_setParam(params, lengths, formats, i, strings[i], s.length)
						Case DBTYPE_BOOL
							If TDBBool(values[i]).getInt() Then
								s = "t"
							Else
								s = "f"
							End If
							strings[i] = s.toCString()
							bmx_pgsql_setParam(params, lengths, formats, i, strings[i], s.length)
						Default
							strings[i] = values[i].getString().ToUtF8String()
							
							bmx_pgsql_setParam(params, lengths, formats, i, strings[i], s.length)
					End Select
					
				End If

			Next
			
			'If result Then
			'	bmx_pgsql_PQclear(result)
			'End If
		End If

		If params Then
			pgResult = bmx_pgsql_PQexecPrepared(conn.handle, _preparedStatementName, ..
				paramCount, params, lengths, formats)
		Else
			pgResult = bmx_pgsql_PQexecPrepared(conn.handle, _preparedStatementName, ..
				paramCount, Null, Null, Null)
		End If
		
		' free up the strings
		For Local i:Int = 0 Until paramCount
			If strings[i] Then
				MemFree(strings[i])
			End If
		Next
		
		If params Then
			bmx_pgsql_deleteParamValues(params)
			bmx_pgsql_deleteParamInts(lengths)
			bmx_pgsql_deleteParamInts(formats)
		End If
		
		If Not pgResult Then
			conn.setError("Error executing prepared statement", "", TDatabaseError.ERROR_STATEMENT, 0)				
			cleanup()
			Return False
		End If

		Local status:Int = bmx_pgsql_PQresultStatus(pgResult)
		
		Select status
			Case PGRES_TUPLES_OK
				' returned some row data... probably a select!?
				' how many ?
				_queryRows = bmx_pgsql_PQntuples(pgResult)
			Case PGRES_COMMAND_OK
				' success but returned nothing. insert, update, delete etc
				' nothing to see here...
				_queryRows = -1
			Default
				' an error!
				conn.setError("Error executing prepared statement", bmx_pgsql_PQerrorMessage(conn.handle), TDatabaseError.ERROR_STATEMENT, 0)				
				cleanup()
				Return False
		End Select

		Local fieldCount:Int = bmx_pgsql_PQnfields(pgResult)

		initRecord(fieldCount)

		' PQcmdTuples returns an empty string for non-change statements, so we should
		' get a zero in here for selects...
		_rowsAffected = String.fromCString(bmx_pgsql_PQcmdTuples(pgResult)).toInt()

		' get the field descriptions
		If fieldCount <> 0 Then
			
			For Local i:Int = 0 Until fieldCount
				Local dtype:Int = bmx_pgsql_PQftype(pgResult, i)
				Local qf:TQueryField = TQueryField.Create(bmx_pgsql_PQfname(pgResult, i), dbTypeFromNative(Null, dtype))
				qf.length = bmx_pgsql_PQfsize(pgResult, i)
				qf.precision = bmx_pgsql_PQfmod(pgResult, i)
				qf.dtype = dtype
				' if length is -1, then precision field holds actual length value, and
				' precision should be ignored.
				If qf.length = -1 Then
					qf.length = qf.precision - 4
					qf.precision = -1
				End If
				
				rec.setField(i, qf)
				
			Next
		End If

		' did we return any data?
		' if we didn't, then we may as well cleanup now
		If _queryRows < 1 Then
			cleanup()
		Else
			_isActive = True
		End If
		
		Return True
	End Method
	
	Method firstRow:Int()
		If index = SQL_BeforeFirstRow Then
			Return nextRow()
		End If
		
		Return False
	End Method
	
	Method nextRow:Int()

		If Not _isActive
			cleanup()
			Return False
		End If
		
		If index >= _queryRows - 1 Then
			cleanup()
			Return False
		End If
		
		' now populate the values[] array with the fetched data !
		
		For Local i:Int = 0 Until rec.count()
		
			If values[i] Then
				values[i].clear()
			End If

			If Not bmx_pgsql_PQgetisnull(pgResult, index + 1, i)
			
				Local fieldLength:Int = bmx_pgsql_PQgetlength(pgResult, index + 1, i)
			
				Select rec.fields[i].fType
					Case DBTYPE_INT
						If rec.fields[i].dtype = BOOLOID Then
							Local v:String = String.fromBytes(bmx_pgsql_PQgetvalue(pgResult, index + 1, i), fieldLength)
							values[i] = New TDBInt
							values[i].setInt(v = "t")
						Else
							values[i] = New TDBInt
							values[i].setInt(String.fromBytes(bmx_pgsql_PQgetvalue(pgResult, index + 1, i), fieldLength).toInt())
						End If
					Case DBTYPE_LONG
						values[i] = New TDBLong
						values[i].setLong(String.fromBytes(bmx_pgsql_PQgetvalue(pgResult, index + 1, i), fieldLength).toLong())
					Case DBTYPE_UINT
						values[i] = New TDBUInt
						values[i].setUInt(String.fromBytes(bmx_pgsql_PQgetvalue(pgResult, index + 1, i), fieldLength).toUInt())
					Case DBTYPE_ULONG
						values[i] = New TDBULong
						values[i].setULong(String.fromBytes(bmx_pgsql_PQgetvalue(pgResult, index + 1, i), fieldLength).toULong())
					Case DBTYPE_FLOAT
						values[i] = New TDBFloat
						values[i].SetFloat(String.fromBytes(bmx_pgsql_PQgetvalue(pgResult, index + 1, i), fieldLength).toFloat())
					Case DBTYPE_DOUBLE
						values[i] = New TDBDouble
						values[i].setDouble(String.fromBytes(bmx_pgsql_PQgetvalue(pgResult, index + 1, i), fieldLength).toDouble())
					Case DBTYPE_DATE
							values[i] = TDBDate.SetFromString(String.fromBytes(bmx_pgsql_PQgetvalue(pgResult, index + 1, i), fieldLength))
					Case DBTYPE_DATETIME
							values[i] = TDBDateTime.SetFromString(String.fromBytes(bmx_pgsql_PQgetvalue(pgResult, index + 1, i), fieldLength))
					Case DBTYPE_TIME
							values[i] = TDBTime.SetFromString(String.fromBytes(bmx_pgsql_PQgetvalue(pgResult, index + 1, i), fieldLength))
					Case DBTYPE_DECIMAL
						values[i] = New TDBDecimal
						values[i].setString(String.fromBytes(bmx_pgsql_PQgetvalue(pgResult, index + 1, i), fieldLength))
					Case DBTYPE_BLOB
						' get the escaped data
						Local b:Byte Ptr = bmx_pgsql_PQgetvalue(pgResult, index + 1, i)
						' now... unescape!
						Local c:Byte Ptr = bmx_pgsql_PQunescapeBytea(b, Varptr fieldLength)
						values[i] = TDBBlob.Set(c, fieldLength)
						' free :-)
						bmx_pgsql_PQfreemem(c)
					Default
						values[i] = New TDBString
						values[i].setString(String.FromUTF8Bytes(bmx_pgsql_PQgetvalue(pgResult, index + 1, i), fieldLength))
				End Select
			
				
			End If
			
		Next
		
		index:+ 1
		
		If index >= _queryRows - 1 Then
			clearResultSet()
		End If
		
		Return True
	End Method
	
	Method lastInsertedId:Long()
		Return -1
	End Method
	
	Method rowsAffected:Int()
		Return _rowsAffected
	End Method

	Function dbTypeFromNative:Int(name:String, _type:Int = 0, _flags:Int = 0)
	
		Local dbType:Int
		
		Select _type
			Case BOOLOID
				dbType = DBTYPE_BOOL
			Case INT2OID, INT4OID, VOIDOID, REGPROCOID, XIDOID, CIDOID
				dbType = DBTYPE_INT
			Case INT8OID
				dbType = DBTYPE_LONG
			Case FLOAT4OID
				dbType = DBTYPE_FLOAT
			Case NUMERICOID
				dbType = DBTYPE_DECIMAL
			Case FLOAT8OID
				dbType = DBTYPE_DOUBLE
			Case DATEOID
				dbType = DBTYPE_DATE
			Case TIMEOID, TIMETZOID
				dbType = DBTYPE_TIME
			Case TIMESTAMPOID, TIMESTAMPTZOID, ABSTIMEOID, RELTIMEOID
				dbType = DBTYPE_DATETIME
			Case BYTEAOID
				dbType = DBTYPE_BLOB
			Default
				dbType = DBTYPE_STRING
		End Select
		
		Return dbType
	End Function

End Type

Type TPostgreSQLDatabaseLoader Extends TDatabaseLoader

	Method New()
		_type = "POSTGRESQL"
	End Method

	Method LoadDatabase:TDBConnection( dbname:String = Null, host:String = Null, ..
		port:Int = Null, user:String = Null, password:String = Null, ..
		server:String = Null, options:String = Null )
	
		Return TDBPostgreSQL.Create(dbName, host, port, user, password, server, options)
		
	End Method

End Type

AddDatabaseLoader New TPostgreSQLDatabaseLoader
