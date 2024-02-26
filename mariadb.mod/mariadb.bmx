' Copyright (c) 2007-2022 Bruce A Henderson
' All rights reserved.
'
' Redistribution and use in source and binary forms, with or without
' modification, are permitted provided that the following conditions are met:
'     * Redistributions of source code must retain the above copyright
'       notice, this list of conditions and the following disclaimer.
'     * Redistributions in binary form must reproduce the above copyright
'       notice, this list of conditions and the following disclaimer in the
'       documentation and/or other materials provided with the distribution.
'     * Neither the auther nor the names of its contributors may be used to 
'       endorse or promote products derived from this software without specific
'       prior written permission.
'
' THIS SOFTWARE IS PROVIDED BY Bruce A Henderson ``AS IS'' AND ANY
' EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
' WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
' DISCLAIMED. IN NO EVENT SHALL Bruce A Henderson BE LIABLE FOR ANY
' DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
' (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
' LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
' ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
' (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
' SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
'
SuperStrict

Rem
bbdoc: Database Driver - MariaDB
about: A MariaDB database driver for #Database.Core
End Rem
Module Database.MariaDB

ModuleInfo "Version: 1.01"
ModuleInfo "Author: Bruce A Henderson"
ModuleInfo "License: BSD"
ModuleInfo "Copyright: Wrapper - 2007-2022 Bruce A Henderson"

ModuleInfo "History: 1.01"
ModuleInfo "History: Fixed setting Null binds"
ModuleInfo "History: 1.00 Initial Release"

?win32x86
ModuleInfo "LD_OPTS: -L%PWD%/lib/win32x86"
?win32x64
ModuleInfo "LD_OPTS: -L%PWD%/lib/win32x64"
?win32arm
ModuleInfo "LD_OPTS: -L%PWD%/lib/win32arm"
?win32arm64
ModuleInfo "LD_OPTS: -L%PWD%/lib/win32arm64"
?macos
ModuleInfo "CC_OPTS: `pkg-config --cflags libmariadb`"
ModuleInfo "LD_OPTS: `pkg-config --libs-only-L libmariadb`"
?linux
ModuleInfo "CC_OPTS: `pkg-config --cflags libmariadb`"
ModuleInfo "LD_OPTS: `pkg-config --libs-only-L libmariadb`"
?

Import "common.bmx"

Type TDBMariaDB Extends TDBConnection

	Field clientVersion:Int
	Field serverVersion:Int

	Function Create:TDBConnection(dbname:String = Null, host:String = Null, ..
		port:Int = Null, user:String = Null, password:String = Null, server:String = Null, options:String = Null)
		
		Local this:TDBMariaDB = New TDBMariaDB
		
		this.init(dbname, host, port, user, password, server, options)
		
		this.clientVersion = mysql_get_client_version()
		
		If this._dbname Then
			this.open(user, password)
		End If
		
		Return this
		
	End Function

	Method close()
		If _isOpen Then

			free() ' tidy up queries and stuff
			
			mysql_close(handle)
			handle = Null
			_isOpen = False
		End If
	End Method

	Method isOpen:Int()
		If _isOpen Then
			' really check that the database is open
			If mysql_ping(handle) Then
				setError("Connection has closed", Null, TDatabaseError.ERROR_CONNECTION, mysql_errno(handle))
				_isOpen = False
			End If
		End If
		
		Return _isOpen
	End Method
		
	Method commit:Int()
		If Not _isOpen Then
			Return False
		End If
		
		If mysql_query(handle, "COMMIT") Then
			setError("Error committing transaction", Null, TDatabaseError.ERROR_TRANSACTION, mysql_errno(handle))
			Return False
		End If
		
		Return True
	End Method
	
	Method getTables:String[]()
		Local list:String[]
		
		If Not _isOpen Then
			Return list
		End If
		
		Local tableList:TList = New TList
		Local tablesHandle:Byte Ptr = mysql_list_tables(handle, Null)
		
		If tablesHandle Then
			Local row:Byte Ptr = mysql_fetch_row(tablesHandle)

			While row
				Local s:String = String.FromUTF8String(bmx_mysql_rowField_chars(row, 0))
				tableList.addLast(s)
			
				row = mysql_fetch_row(tablesHandle)
			Wend
			
			mysql_free_result(tablesHandle)
		End If
		
		If tableList.count() > 0 Then
			list = New String[tableList.count()]
			Local i:Int = 0
			For Local s:String = EachIn tableList
				list[i] = s
				i:+ 1
			Next
		End If
		
		Return list
	End Method

	Method getTableInfo:TDBTable(tableName:String, withDDL:Int = False)
		If Not _isOpen Then
			Return Null
		End If
		
		Local query:TDatabaseQuery = TDatabaseQuery.Create(Self)
		
		Local table:TDBTable

		Local sql:String = "SHOW COLUMNS FROM " + tableName
			
		If query.execute(sql) Then
			table = New TDBTable
			table.name = tableName
			
			Local cols:TList = New TList
			
			For Local rec:TQueryRecord = EachIn query

				Local name:String = rec.GetString(0)
				Local _type:String = rec.GetString(1).Split("(")[0]
				Local dbType:Int
				Select _type
					Case "boolean", "bool", "tinyint", "smallint", "mediumint", "int", "integer"
						dbType = DBTYPE_INT
					Case "bigint"
						dbType = DBTYPE_LONG
					Case "real", "double", "decimal"
						dbType = DBTYPE_DOUBLE
					Case "float"
						dbType = DBTYPE_FLOAT
					Case "date"
						dbType = DBTYPE_DATE
					Case "timestamp", "datetime"
						dbType = DBTYPE_DATETIME
					Case "time"
						dbType = DBTYPE_TIME
					Case "tinyblob", "blob", "mediumblob", "longblob"
						dbType = DBTYPE_BLOB
					Default
						dbType = DBTYPE_STRING
				End Select
				
				Local nullable:Int
				If rec.GetString(2) = "YES" Then
					nullable = True
				End If
				
				Local defaultValue:TDBType = rec.value(4)
				
				cols.AddLast(TDBColumn.Create(name, dbType, nullable, defaultValue))
			Next
			
			table.SetCountColumns(cols.count())
			Local i:Int
			For Local col:TDBColumn = EachIn cols
				table.SetColumn(i, col)
				i:+ 1
			Next
			
			cols.Clear()
			
			If withDDL Then
				sql = "SHOW CREATE TABLE " + tableName
				If query.execute(sql) Then
					
					For Local rec:TQueryRecord = EachIn query
						table.ddl:+ rec.GetString(1) + ";~n~n"
					Next

				End If
				
			End If
		Else
			' no table?
		End If
		
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
		
		' initialize the handle
		handle = mysql_init(0)
		
		If handle Then
		
			Local ret:Int = 0
			
			Local d:Byte Ptr = _dbname.ToUTF8String()

			If _host Then
				Local h:Byte Ptr = _host.ToUTF8String()
				If _user Then
					Local u:Byte Ptr = _user.ToUTF8String()
					If _password
						Local p:Byte Ptr = _password.ToUTF8String()
						ret = mysql_real_connect(handle, h, u, p, d, _port, Null, _options.ToInt())
						MemFree(p)
					Else
						ret = mysql_real_connect(handle, h, u, Null, d, _port, Null, _options.ToInt())
					End If
					MemFree(u)
				Else
					ret = mysql_real_connect(handle, h, Null, Null, d, _port, Null, _options.ToInt())
				End If
				MemFree(h)
			Else
				If _user Then
					Local u:Byte Ptr = _user.ToUTF8String()
					If _password
						Local p:Byte Ptr = _password.ToUTF8String()
						ret = mysql_real_connect(handle, Null, u, p, d, _port, Null, _options.ToInt())
						MemFree(p)
					Else
						ret = mysql_real_connect(handle, Null, u, Null, d, _port, Null, _options.ToInt())
					End If
					MemFree(u)
				Else
					ret = mysql_real_connect(handle, Null, Null, Null, d, _port, Null, _options.ToInt())
				End If
			End If
			
			If Not ret Then
				setError("Error connecting to database", String.FromUTF8String(mysql_error(handle)), TDatabaseError.ERROR_CONNECTION, mysql_errno(handle))
				Return False
			End If
			
			If mysql_select_db(handle, _dbname) Then
				setError("Error opening database '" + _dbname + "'", String.FromUTF8String(mysql_error(handle)), TDatabaseError.ERROR_CONNECTION, mysql_errno(handle))
				Return False
			End If
		Else
			setError("Error initializing database", Null, TDatabaseError.ERROR_CONNECTION, 0)
			Return False
		End If
		
		If clientVersion >= 50007 Then
			mysql_set_character_set(handle, "utf8")
		End If
		
		serverVersion = mysql_get_server_version(handle)
		
		_isOpen = True
		Return True
	End Method
	
	Method rollback:Int()
		If Not _isOpen Then
			Return False
		End If
		
		If mysql_query(handle, "ROLLBACK") Then
			setError("Error rolling back transaction", Null, TDatabaseError.ERROR_TRANSACTION, mysql_errno(handle))
			Return False
		End If
		
		Return True
	End Method
	
	Method startTransaction:Int()
		If Not _isOpen Then
			Return False
		End If
		
		If mysql_query(handle, "BEGIN WORK") Then
			setError("Error starting transaction", Null, TDatabaseError.ERROR_TRANSACTION, mysql_errno(handle))
			Return False
		End If
		
		Return True
	End Method
	
	Method databaseHandle:Byte Ptr()
		Return handle
	End Method
	
	Method createResultSet:TQueryResultSet()
		Return TMySQLResultSet.Create(Self)
	End Method

	Method nativeErrorMessage:String(err:Int)
	End Method
	
	Method hasPrepareSupport:Int()
		Return True
	End Method

	Method hasTransactionSupport:Int()
		Return True
	End Method

End Type

Type TMySQLField

	Field mySQLField:Byte Ptr
	Field dataValue:Byte Ptr
	Field dataLength:ULongInt
	Field isNull:Byte
	Field flag:Int

	Method clear()
		mySQLField = Null
		If dataValue Then
			MemFree(dataValue)
			dataValue = Null
		End If
		dataLength = 0
		isNull = 0
	End Method
	
	Method Delete()
		clear()
	End Method
	
End Type

Type TMySQLResultSet Extends TQueryResultSet

	' a pointer to a mysql result
	Field resultHandle:Byte Ptr
	Field row:Byte Ptr
	
	' a pointer to a mysql prepared statement
	Field stmtHandle:Byte Ptr
	Field metaHandle:Byte Ptr
	
	Field preparedQuery:Int
	Field _rowsAffected:Int

	Field parameterBindings:Byte Ptr
	Field selectBindings:Byte Ptr
	
	Field mySQLFields:TMySQLField[]

	Function Create:TQueryResultSet(db:TDBConnection, sql:String = Null)
		Local this:TMySQLResultSet = New TMySQLResultSet
		
		this.init(db, sql)
		this.rec = TQueryRecord.Create()
		
		Return this
	End Function

	Method executeQuery:Int(statement:String)
	
		If Not conn.isOpen() Then
			Return False
		End If
		
		preparedQuery = False
		
		Local q:Byte Ptr = statement.ToUTF8String()
		Local query:Int = mysql_real_query(conn.handle, q, _strlen(q)) Then
		MemFree(q)
		
		If query
			conn.setError("Error executing query", String.FromUTF8String(mysql_error(conn.handle)), TDatabaseError.ERROR_STATEMENT, mysql_errno(conn.handle))
			Return False
		End If
		
		resultHandle = mysql_store_result(conn.handle)
		
		If Not resultHandle And mysql_field_count(conn.handle) > 0 Then
			conn.setError("Error storing result set", String.FromUTF8String(mysql_error(conn.handle)), TDatabaseError.ERROR_STATEMENT, mysql_errno(conn.handle))
			Return False
		End If
		
		Local fieldCount:Int = mysql_field_count(conn.handle)

		initRecord(fieldCount)

		Local af:Long
		bmx_mysql_affected_rows(conn.handle, Varptr af)
		_rowsAffected = af
		
		If fieldCount <> 0 Then
			
			For Local i:Int = 0 Until fieldCount
				Local _field:Byte Ptr = mysql_fetch_field_direct(resultHandle, i)
				
				Local qf:TQueryField = TQueryField.Create(bmx_mysql_field_name(_field), dbTypeFromNative(Null, bmx_mysql_field_type(_field), bmx_mysql_field_flags(_field)))
				qf.length = bmx_mysql_field_length(_field)
				qf.precision = bmx_mysql_field_decimals(_field)
				
				rec.setField(i, qf)
				
			Next
		End If
		
		_isActive = True
		Return True
	End Method
	
	Method prepare:Int(statement:String)
	
		cleanup()
		
		If Not statement Or statement.length = 0 Then
			Return False
		End If
		
		' initialize the statement if required
		If Not stmtHandle Then
			stmtHandle = mysql_stmt_init(conn.handle)
		End If
		
		If Not stmtHandle Then
			conn.setError("Error preparing statement", String.FromUTF8String(mysql_error(conn.handle)), TDatabaseError.ERROR_STATEMENT, mysql_errno(conn.handle))
			Return False
		End If
		
		' prepare the statement
		Local q:Byte Ptr = statement.ToUTF8String()
		Local result:Int = mysql_stmt_prepare(stmtHandle, q, _strlen(q))
		MemFree(q)
		
		If result Then
			conn.setError("Error preparing statement", String.FromUTF8String(mysql_stmt_error(stmtHandle)), TDatabaseError.ERROR_STATEMENT, mysql_errno(stmtHandle))
			cleanup()
			Return False
		End If
		
		' if the param count > 0 there are "?" in the SQL that need to be bound
		If mysql_stmt_param_count(stmtHandle) > 0 Then
			parameterBindings = bmx_mysql_makeBindings(mysql_stmt_param_count(stmtHandle))
		End If
		
		' **********************************
		' setup bindings for inbound data...
		If Not metaHandle Then
			metaHandle = mysql_stmt_result_metadata(stmtHandle)
		End If
		
		If metaHandle Then

			Local fieldCount:Int = mysql_num_fields(metaHandle)
			initRecord(fieldCount)

			mySQLFields = New TMySQLField[fieldCount]
		
			selectBindings = bmx_mysql_makeBindings(fieldCount)
			
			For Local i:Int = 0 Until fieldCount
			
				Local _field:Byte Ptr = mysql_fetch_field(metaHandle)

				mySQLFields[i] = New TMySQLField
				
				mySQLFields[i].mySQLField = _field
				mySQLFields[i].dataLength = bmx_mysql_field_length(_field) + 1
				' make some space for the data...
				Local size:Size_T = bmx_mysql_length_for_field(_field)
				mySQLFields[i].dataValue = MemAlloc(size)
				
				Local ty:Int = bmx_mysql_field_type(_field)
				' build result set field information
				Local qf:TQueryField = TQueryField.Create(bmx_mysql_field_name(_field), dbTypeFromNative(Null, ty, bmx_mysql_field_flags(_field)))
				qf.length = bmx_mysql_field_length(_field)
				qf.precision = bmx_mysql_field_decimals(_field)
				rec.setField(i, qf)

				bmx_mysql_inbind(selectBindings, i, _field, mySQLFields[i].dataValue, Varptr mySQLFields[i].dataLength, Varptr mySQLFields[i].isNull, ty)
			Next

		End If
		
		Return True
	End Method
	
	Method execute:Int()

		If Not preparedQuery Then
			Return False
		End If
		
		If Not stmtHandle Then
			Return False
		End If
		
		index = SQL_BeforeFirstRow
		
		Local result:Int = 0
		
		result = bmx_mysql_stmt_reset(stmtHandle)
		If result Then
			conn.setError("Error resetting statement", String.FromUTF8String(mysql_stmt_error(stmtHandle)), TDatabaseError.ERROR_STATEMENT, mysql_errno(stmtHandle))
			Return False
		End If

		' BIND stuff
		Local values:TDBType[] = boundValues

		Local paramCount:Int = mysql_stmt_param_count(stmtHandle)

		Local strings:Byte Ptr[]
		Local times:Byte Ptr[]
		Local nulls:Byte[]

		If paramCount = bindCount Then

			strings = New Byte Ptr[paramCount]
			times = New Byte Ptr[paramCount]
			nulls = New Byte[paramCount]
		
			For Local i:Int = 0 Until paramCount

				Local isNull:Int = False
				Local nullsPtr:Byte Ptr

				If Not values[i] Or values[i].isNull() Then
					isNull = True
					nulls[i] = 1
					nullsPtr = Byte Ptr(nulls) + i
				End If

				Select values[i].kind()
					Case DBTYPE_INT
						bmx_mysql_bind_int(parameterBindings, i, Varptr TDBInt(values[i]).value, nullsPtr)
					Case DBTYPE_FLOAT
						bmx_mysql_bind_float(parameterBindings, i, Varptr TDBFloat(values[i]).value, nullsPtr)
					Case DBTYPE_DOUBLE
						bmx_mysql_bind_double(parameterBindings, i, Varptr TDBDouble(values[i]).value, nullsPtr)
					Case DBTYPE_LONG
						bmx_mysql_bind_long(parameterBindings, i, Varptr TDBLong(values[i]).value, nullsPtr)
					Case DBTYPE_STRING
						local s:Byte Ptr = values[i].getString().ToUTF8String()
						strings[i] = s
						bmx_mysql_bind_string(parameterBindings, i, s, _strlen(s), nullsPtr)
						
					Case DBTYPE_BLOB
						bmx_mysql_bind_blob(parameterBindings, i, TDBBlob(values[i]).value, TDBBlob(values[i])._size, nullsPtr)

					Case DBTYPE_DATE
						Local date:TDBDate = TDBDate(values[i])
						times[i] = bmx_mysql_makeTime()
						bmx_mysql_bind_date(parameterBindings, i, times[i], date.getYear(), date.getMonth(), date.getDay(), nullsPtr)
					Case DBTYPE_DATETIME
						Local date:TDBDateTime = TDBDateTime(values[i])
						times[i] = bmx_mysql_makeTime()
						bmx_mysql_bind_datetime(parameterBindings, i, times[i], date.getYear(), date.getMonth(), date.getDay(), date.getHour(), date.getMinute(), date.getSecond(), nullsPtr)
					Case DBTYPE_TIME
						Local date:TDBTime = TDBTime(values[i])
						times[i] = bmx_mysql_makeTime()
						bmx_mysql_bind_time(parameterBindings, i, times[i], date.getHour(), date.getMinute(), date.getSecond(), nullsPtr)
				End Select


			Next

			' actually bind the parameters
			result = bmx_mysql_stmt_bind_param(stmtHandle, parameterBindings)

			If result Then
				conn.setError("Error binding values", String.FromUTF8String(mysql_stmt_error(stmtHandle)), TDatabaseError.ERROR_STATEMENT, mysql_errno(stmtHandle))
			
				' free up the strings
				For Local i:Int = 0 Until paramCount
					If strings[i] Then
						MemFree(strings[i])
					End If
					
					If times[i] Then
						bmx_mysql_deleteTime(times[i])
					End If
				Next
				
				Return False
			End If
			
		End If
	
		' execute the statement
		result = mysql_stmt_execute(stmtHandle)

		' free up the strings
		If strings Or times Then
			For Local i:Int = 0 Until paramCount
				If strings[i] Then
					MemFree(strings[i])
				End If
				
				If times[i] Then
					bmx_mysql_deleteTime(times[i])
				End If
			Next
		End If
		
		If result Then
			conn.setError("Error executing statement", String.FromUTF8String(mysql_stmt_error(stmtHandle)), TDatabaseError.ERROR_STATEMENT, mysql_errno(stmtHandle))
			Return False
		End If
		
		Local af:Long
		bmx_mysql_stmt_affected_rows(stmtHandle, Varptr af)
		_rowsAffected = af

		' if this is set, then there is data returned from the statement execution
		' in which case we need to bind the results for the result set
		If metaHandle Then

			result = bmx_mysql_stmt_bind_result(stmtHandle, selectBindings)

			If result Then
				conn.setError("Error binding result", String.FromUTF8String(mysql_stmt_error(stmtHandle)), TDatabaseError.ERROR_STATEMENT, mysql_errno(stmtHandle))
				Return False
			End If

			result = mysql_stmt_store_result(stmtHandle)

			If result Then
				conn.setError("Error storing result", String.FromUTF8String(mysql_stmt_error(stmtHandle)), TDatabaseError.ERROR_STATEMENT, mysql_errno(stmtHandle))
				Return False
			End If
		
		End If


		_isActive = True
		Return True
	End Method

	Method initRecord(size:Int)

		rec.clear()

		If size > 0 Then		
			rec.init(size)
		End If
		
		resetValues(size)
	End Method
	
	Method firstRow:Int()
		If index = SQL_BeforeFirstRow Then
			Return nextRow()
		End If
		
		Return False
	End Method
	
	Method nextRow:Int()
		If preparedQuery Then
			If Not stmtHandle Then
				Return False
			End If
			
			Local result:Int = bmx_mysql_stmt_fetch(stmtHandle)
			If result Then
				Return False
			End If
		Else
			row = mysql_fetch_row(resultHandle)
			If Not row Then
				Return False
			End If
		End If
		
		' now populate the values[] array with the fetched data !
		For Local i:Int = 0 Until rec.count()
		
			If values[i] Then
				values[i].clear()
			End If

			
			If preparedQuery Then
			
				If Not mySQLFields[i].isNull Then
				
					Local fieldLength:Int = mySQLFields[i].dataLength

					' it seems that we need to retrieve all values as if they were "strings"...
					' Don't ask... it doesn't work otherwise. (except on Windows... haw)
					Select rec.fields[i].fType
						Case DBTYPE_INT
							values[i] = New TDBInt
							values[i].setInt(bmx_mysql_char_to_int(mySQLFields[i].dataValue))
						Case DBTYPE_LONG
							values[i] = New TDBLong
							values[i].setLong(bmx_mysql_char_to_long(mySQLFields[i].dataValue))
						Case DBTYPE_FLOAT
							values[i] = New TDBFloat
							values[i].setFloat(bmx_mysql_char_to_float(mySQLFields[i].dataValue))
						Case DBTYPE_DOUBLE
							values[i] = New TDBDouble
							values[i].setDouble(bmx_mysql_char_to_double(mySQLFields[i].dataValue))
						Case DBTYPE_DATE
							values[i] = bmx_mysql_char_to_date(mySQLFields[i].dataValue)
						Case DBTYPE_DATETIME
							values[i] = bmx_mysql_char_to_datetime(mySQLFields[i].dataValue)
						Case DBTYPE_TIME
							values[i] = bmx_mysql_char_to_time(mySQLFields[i].dataValue)
						Case DBTYPE_BLOB
							values[i] = TDBBlob.Set(mySQLFields[i].dataValue, fieldLength)
						Default
							values[i] = New TDBString
							values[i].setString(sizedUTF8toISO8859(mySQLFields[i].dataValue, fieldLength))
					End Select
					
				End If
				
			Else
				' a non-prepared query
				If Not bmx_mysql_rowField_isNull(row, i) Then
				
					Local fieldLength:Int = Int(mysql_fetch_lengths(resultHandle)[i])
				
					Select rec.fields[i].fType
						Case DBTYPE_INT
							values[i] = New TDBInt
							values[i].setInt(String.fromBytes(bmx_mysql_rowField_chars(row, i), fieldLength).toInt())
						Case DBTYPE_LONG
							values[i] = New TDBLong
							values[i].setLong(String.fromBytes(bmx_mysql_rowField_chars(row, i), fieldLength).toLong())
						Case DBTYPE_FLOAT
							values[i] = New TDBFloat
							values[i].setFloat(String.fromBytes(bmx_mysql_rowField_chars(row, i), fieldLength).toFloat())
						Case DBTYPE_DOUBLE
							values[i] = New TDBDouble
							values[i].setDouble(String.fromBytes(bmx_mysql_rowField_chars(row, i), fieldLength).toDouble())
						Case DBTYPE_DATE
							values[i] = TDBDate.SetFromString(String.FromUTF8Bytes(bmx_mysql_rowField_chars(row, i), fieldLength))
						Case DBTYPE_DATETIME
							values[i] = TDBDateTime.SetFromString(String.FromUTF8Bytes(bmx_mysql_rowField_chars(row, i), fieldLength))
						Case DBTYPE_TIME
							values[i] = TDBTime.SetFromString(String.FromUTF8Bytes(bmx_mysql_rowField_chars(row, i), fieldLength))
						Case DBTYPE_BLOB
							values[i] = TDBBlob.Set(bmx_mysql_rowField_chars(row, i), fieldLength)
						Default
							values[i] = New TDBString
							values[i].setString(String.FromUTF8Bytes(bmx_mysql_rowField_chars(row, i), fieldLength))
					End Select
					
				End If
				
			End If
		Next		
		
		
		index:+ 1
		
		Return True
	End Method
	
	Method lastInsertedId:Long()
		If Not isActive()
			Return -1
		End If
		
		Local id:Long = -1
		
		If preparedQuery Then
			bmx_mysql_stmt_insert_id(stmtHandle, Varptr id)
		Else
			bmx_mysql_insert_id(conn.handle, Varptr id)
		End If
		
		Return id
	End Method
	
	Method rowsAffected:Int()
		Return _rowsAffected
	End Method

	Function dbTypeFromNative:Int(name:String, _type:Int = 0, _flags:Int = 0)
	
		Local dbType:Int
		
		Select _type
			Case MYSQL_TYPE_TINY, MYSQL_TYPE_SHORT, MYSQL_TYPE_LONG, MYSQL_TYPE_INT24
				dbType = DBTYPE_INT
			Case MYSQL_TYPE_YEAR
				dbType = DBTYPE_INT
			Case MYSQL_TYPE_LONGLONG
				dbType = DBTYPE_LONG
			Case MYSQL_TYPE_FLOAT
				dbType = DBTYPE_FLOAT
			Case MYSQL_TYPE_DOUBLE, MYSQL_TYPE_DECIMAL
				dbType = DBTYPE_DOUBLE
			Case MYSQL_TYPE_DATE
				dbType = DBTYPE_DATE
			Case MYSQL_TYPE_TIME
				dbType = DBTYPE_TIME
			Case MYSQL_TYPE_DATETIME, MYSQL_TYPE_TIMESTAMP
				dbType = DBTYPE_DATETIME
			Case MYSQL_TYPE_BLOB, MYSQL_TYPE_TINY_BLOB, MYSQL_TYPE_MEDIUM_BLOB, MYSQL_TYPE_LONG_BLOB
				If _flags & 128 Then ' binary !
					dbType = DBTYPE_BLOB
				Else ' String!
					dbType = DBTYPE_STRING
				End If
			Default
				dbType = DBTYPE_STRING
		End Select
		
		Return dbType
	End Function

	Method cleanup()

		If resultHandle Then
			mysql_free_result(resultHandle)
			resultHandle = Null
		End If
		
		If metaHandle Then
			mysql_free_result(metaHandle)
			metaHandle = Null
		End If
		
		If stmtHandle Then
			If bmx_mysql_stmt_close(stmtHandle) Then
				'
			End If
			stmtHandle = Null
		End If
		
		If parameterBindings Then
			bmx_mysql_deleteBindings(parameterBindings)
			parameterBindings = Null
		End If

		If selectBindings Then
			bmx_mysql_deleteBindings(selectBindings)
			selectBindings = Null
		End If
	
		If mySQLFields Then
			For Local i:Int = 0 Until mySQLFields.length
				If mySQLFields[i] Then
					mySQLFields[i].clear()
					mySQLFields[i] = Null
				End If
			Next
		End If
		
		index = SQL_BeforeFirstRow
		rec.clear()
		_isActive = False
		
		preparedQuery = True
	End Method
	
	Method clear()
		cleanup()
	
		Super.clear()
	End Method
	
	Method reset()
		clear()
	End Method
	
	Method free()
		clear()
	End Method
	
	Method Delete()
		free()
	End Method
	
End Type




Type TMariaDBDatabaseLoader Extends TDatabaseLoader

	Method New()
		_type = "MARIADB"
	End Method

	Method LoadDatabase:TDBConnection( dbname:String = Null, host:String = Null, ..
		port:Int = Null, user:String = Null, password:String = Null, ..
		server:String = Null, options:String = Null )
	
		Return TDBMariaDB.Create(dbName, host, port, user, password, server, options)
		
	End Method

End Type

AddDatabaseLoader New TMariaDBDatabaseLoader
