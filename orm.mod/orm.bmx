' Copyright (c) 2026 Bruce A Henderson
' All rights reserved.
'
' Permission is hereby granted, free of charge, to any person obtaining a copy
' of this software and associated documentation files (the "Software"), to deal
' in the Software without restriction, including without limitation the rights
' to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
' copies of the Software, and to permit persons to whom the Software is
' furnished to do so, subject to the following conditions:
' 
' The above copyright notice and this permission notice shall be included in
' all copies or substantial portions of the Software.
' 
' THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
' IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
' FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
' AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
' LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
' OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
' THE SOFTWARE.
'
SuperStrict

Rem
bbdoc: Core ORM implementation.
about: This module defines the main #TOrm class, which provides methods for registering models, creating tables, and performing CRUD operations.
It also defines the #TOrmDialect base class for database-specific behaviour and the #TOrmDaoBase class for basic data access operations.
End Rem
Module Database.Orm

ModuleInfo "Version: 1.00"
ModuleInfo "License: MIT"
ModuleInfo "Copyright: Bruce A Henderson"

ModuleInfo "History: 1.00"
ModuleInfo "History: Initial Release."

Import Collections.ArrayList
Import Collections.HashMap
Import BRL.Reflection
Import Database.Core
Import BRL.StringBuilder
Import Text.JConv

' metadata
' table="users"       type-level
' column="email"      field-level
' pk                  primary key
' auto                auto-generated id
' transient           do not persist
' json                serialize with Text.JConv
' bool                convert Int <-> database boolean
' nullable            allow NULL
' unique              add UNIQUE in generated schema. Can also specify unique index name like { unique="my_index" }
' index			      add index on this column (can specify index name like { index="my_index" }). columns with the same index name will be part of the same index
' enum_string		  for enum fields, store the string value instead of numeric value

Rem
bbdoc: Default styles for mapping between type/field names and database table/column names. The naming style can be configured per model or globally in the ORM instance.
about: The naming style determines how type and field names are converted to table and column names when not explicitly specified with the #orm_table and #orm_column metadata.

| Style | Description |
|-------|-------------|
| LowerCase | Converts names to lowercase (e.g. "UserProfile" -> "userprofile") |
| UpperCase | Converts names to uppercase (e.g. "UserProfile" -> "USERPROFILE") |
| CamelCase | Converts names to camelCase (e.g. "UserProfile" -> "userProfile") |
| PascalCase | Converts names to PascalCase (e.g. "UserProfile" -> "UserProfile") |
| LowerCaseUnderscore | Converts names to lowercase with underscores (e.g. "UserProfile" -> "user_profile") |
| UpperCaseUnderscore | Converts names to uppercase with underscores (e.g. "UserProfile" -> "USER_PROFILE") |

End Rem
Enum EOrmNamingStyle
	LowerCase
	UpperCase
	CamelCase
	PascalCase
	LowerCaseUnderscore
	UpperCaseUnderscore
End Enum

Private
Global _orm_dialects:TOrmDialect
Public

Type TOrmModel

    Field typeId:TTypeId
    Field tableName:String
    Field fields:TArrayList<TOrmField>
	Field indexes:TArrayList<TOrmIndex>
    Field primaryKey:TOrmField

	Method FieldByName:TOrmField(name:String)
		For Local fld:TOrmField = EachIn fields
			If fld.name.Equals(name, True) Or fld.columnName.Equals(name, True) Then
				Return fld
			End If
		Next

		Return Null
	End Method
End Type

Type TOrmField

    Field typeField:TField
    Field name:String
    Field columnName:String
    Field isPrimaryKey:Int
    Field isAuto:Int
    Field isJson:Int
    Field isBool:Int
	Field isUnique:Int
    Field nullable:Int
	Field isDecimal:Int
	Field isEnum:Int
	Field isEnumString:Int

End Type

Type TOrmIndex

	Field name:String
	Field fields:TArrayList<TOrmField>
	Field isUnique:Int

End Type

' global registry of ORM models and Daos
Type TOrmRegistry
	Field models:THashMap<TTypeId, TOrmModel>
	Field daos:THashMap<TTypeId, Object>

	Method New()
		models = New THashMap<TTypeId, TOrmModel>
		daos = New THashMap<TTypeId, Object>
	End Method

	Method GetModelForName:TOrmModel(typeName:String)
		Local ty:TTypeId = TTypeId.ForName(typeName)
		If Not ty Then
			Throw New TOrmTypeNotFoundException(typeName)
		End If
		Return GetModelForType(ty)
	End Method

	Method GetModelForType:TOrmModel(typeId:TTypeId)
		If Not models.ContainsKey(typeId) Then
			Throw New TOrmTypeNotFoundException(typeId.Name())
		End If
		Return models[typeId]
	End Method
End Type


Type TOrm

    Field db:TDBConnection

    Field dialect:TOrmDialect
    Field registry:TOrmRegistry

	Field builder:TOrmModelBuilder

	Field jconv:TJConv

	Function Create:TOrm(dbType:String, dbname:String = Null, host:String = Null, ..
			port:Int = Null, user:String = Null, password:String = Null, server:String = Null, ..
			options:String = Null)

		Local db:TDBConnection = LoadDatabase(dbType, dbname, host, port, user, password, server, options)
		If Not db Then
			Throw New TRuntimeException("Failed to create database connection")
		End If
		Local dialect:TOrmDialect = TOrmDialect.Load(dbType)
		If Not dialect Then
			Throw New TRuntimeException("No ORM dialect found for database type: " + dbType)
		End If
		Return New TOrm(db, dialect, New TOrmRegistry)
	End Function

	Method New(db:TDBConnection, dialect:TOrmDialect, registry:TOrmRegistry, jconv:TJConv = Null)
		Self.db = db
		Self.dialect = dialect
		Self.registry = registry
		Self.builder = New TOrmModelBuilder(registry)
		If jconv Then
			Self.jconv = jconv
		Else
			Self.jconv = New TJConvBuilder.WithCompact().Build()
		End If
	End Method

	Method RegisterType:TOrmModel(typeName:String)
		Return GetOrBuildModelForName(typeName)
	End Method

	Method GetOrBuildModelForName:TOrmModel(typeName:String)
		Local ty:TTypeId = TTypeId.ForName(typeName)
		If Not ty Then
			Throw New TOrmTypeNotFoundException(typeName)
		End If

		Return GetOrBuildModelForType(ty)
	End Method

	Method GetOrBuildModelForType:TOrmModel(typeId:TTypeId)
		If registry.models.ContainsKey(typeId) Then
			Return registry.models[typeId]
		End If

		Return builder.BuildModel(typeId)
	End Method

	Method CreateTable(typeName:String)
		Local model:TOrmModel = registry.GetModelForName(typeName)
		If model Then
			CreateTable(model)
		Else
			Throw New TOrmTypeNotFoundException(typeName)
		End If
	End Method

	Method CreateTable(model:TOrmModel)
		Local sql:String = BuildCreateTableSql(model)
		db.ExecuteQuery(sql)

		CreateIndexes(model)
	End Method

	Method BuildCreateTableSql:String(model:TOrmModel)
		Local sql:TStringBuilder = New TStringBuilder
		sql.Append("CREATE TABLE IF NOT EXISTS ")
		sql.Append(dialect.QuoteIdentifier(model.tableName))
		sql.Append(" (")
		For Local i:Int = 0 Until model.fields.Count()
			If i > 0 Then
				sql.Append(", ")
			End If
			Local fld:TOrmField = model.fields.Get(i)
			sql.Append(ColumnDefinition(fld))
		Next
		sql.Append(")")
		Return sql.ToString()
	End Method

	Method ColumnDefinition:String(fld:TOrmField)
		Local sql:TStringBuilder = New TStringBuilder
		sql.Append(dialect.QuoteIdentifier(fld.columnName))
		sql.Append(" ")
		If fld.isPrimaryKey And fld.isAuto Then
			sql.Append(dialect.AutoGeneratedPrimaryKeyType(fld))
		Else
			sql.Append(dialect.SqlTypeForField(fld))
			If fld.isPrimaryKey Then
				sql.Append(" PRIMARY KEY")
			End If
			If Not fld.nullable And Not fld.isPrimaryKey Then
				sql.Append(" NOT NULL")
			End If
			If fld.isUnique Then
				sql.Append(" UNIQUE")
			End If
		End If
		Return sql.ToString()
	End Method

	Method SetJConv(jconv:TJConv)
		If Not jconv Then
			Throw New TOrmException("jconv cannot be Null")
		End If

		Self.jconv = jconv
	End Method

	Method StartTransaction:TOrmTransaction(isStrict:Int = True)
		Return New TOrmTransaction(Self, isStrict)
	End Method

	Method CreateIndexes(model:TOrmModel)
		For Local index:TOrmIndex = EachIn model.indexes
			Local sql:String = BuildCreateIndexSql(model, index)
			db.ExecuteQuery(sql)
		Next
	End Method

	Method BuildCreateIndexSql:String(model:TOrmModel, index:TOrmIndex)
		Local sql:TStringBuilder = New TStringBuilder
		sql.Append("CREATE ")

		If index.isUnique Then
			sql.Append("UNIQUE ")
		End If

		sql.Append("INDEX IF NOT EXISTS ")
		sql.Append(dialect.QuoteIdentifier(index.name))
		sql.Append(" ON ")
		sql.Append(dialect.QuoteIdentifier(model.tableName))
		sql.Append(" (")

		For Local i:Int = 0 Until index.fields.Count()
			If i > 0 Then
				sql.Append(", ")
			End If
			Local fld:TOrmField = index.fields.Get(i)
			sql.Append(dialect.QuoteIdentifier(fld.columnName))
		Next
		sql.Append(")")

		Return sql.ToString()
	End Method

	Method ValidateOnStartup:TOrmSchemaValidationReport()
		Return ValidateAllModels()
	End Method

	Method ValidateOnStartupOrThrow()
		Local report:TOrmSchemaValidationReport = ValidateOnStartup()

		If Not report.IsValid() Then
			Throw New TOrmSchemaValidationException(report)
		End If
	End Method

	Method ValidateAllModels:TOrmSchemaValidationReport()
		Local report:TOrmSchemaValidationReport = New TOrmSchemaValidationReport

		For Local model:TOrmModel = EachIn registry.models.Values()
			ValidateModel(model, report)
		Next

		Return report
	End Method

	Method ValidateModel(model:TOrmModel, report:TOrmSchemaValidationReport)
		Local table:TDBTable = db.GetTableInfo(model.tableName)

		If Not table Then
			report.AddIssue(model, "Table '" + model.tableName + "' does not exist")
			Return
		End If

		For Local fld:TOrmField = EachIn model.fields
			If Not TableHasColumn(table, fld.columnName) Then
				report.AddIssue(model, "Column '" + fld.columnName + "' does not exist in table '" + model.tableName + "'")
			End If
		Next
	End Method

	Method TableHasColumn:Int(table:TDBTable, columnName:String)
		For Local column:TDBColumn = EachIn table.columns
			If column.name.Equals(columnName, True) Then
				Return True
			End If
		Next

		Return False
	End Method
End Type


Type TOrmDialect
	Field _succ:TOrmDialect

	Method QuoteIdentifier:String(name:String) Abstract
	Method SqlTypeForField:String(fld:TOrmField) Abstract
	Method AutoGeneratedPrimaryKeyType:String(fld:TOrmField) Abstract
	Method Placeholder:String(index:Int) Abstract
	Method GetName:String() Abstract

	Method AddBindValue(query:TDatabaseQuery, value:TDBType) Abstract
	Method AddBool(query:TDatabaseQuery, value:Int) Abstract
	Method AddByte(query:TDatabaseQuery, value:Byte) Abstract
	Method AddShort(query:TDatabaseQuery, value:Short) Abstract
	Method AddUInt(query:TDatabaseQuery, value:UInt) Abstract
	Method AddULong(query:TDatabaseQuery, value:ULong) Abstract
	Method AddDecimal(query:TDatabaseQuery, value:TDecimal) Abstract

	Method BoolFromDatabase:Int(value:TDBType) Abstract
	Method ByteFromDatabase:Byte(value:TDBType) Abstract
	Method ShortFromDatabase:Short(value:TDBType) Abstract
	Method UIntFromDatabase:UInt(value:TDBType) Abstract
	Method ULongFromDatabase:ULong(value:TDBType) Abstract
	Method DecimalFromDatabase:TDecimal(value:TDBType) Abstract

	Method RewritePlaceholders:String(sql:String)
		Return sql
	End Method

	Method InsertReturningClause:String(model:TOrmModel)
		Return ""
	End Method

	Method ReadGeneratedId:Long(query:TDatabaseQuery)
		Return query.LastInsertedId()
	End Method

	Method New()
		If _orm_dialects Then
			Self._succ = _orm_dialects
		End If
		_orm_dialects = Self
	End Method

	Function Load:TOrmDialect(dbType:String)
		Local current:TOrmDialect = _orm_dialects
		While current
			If dbType.Equals(current.GetName(), True) Then
				Return current
			End If
			current = current._succ
		Wend
		Return Null
	End Function

End Type

Type TOrmDaoBase

	Field orm:TOrm
	Field model:TOrmModel

	Method SaveObject(obj:Object)

		If Not obj Then
			Throw New TOrmException("Cannot save Null object")
		End If

		Local sql:String = BuildInsertSql()

		Local query:TDatabaseQuery = PrepareQuery(sql)

		BindInsertValues(query, obj)

		ExecuteQuery(query, sql, "Failed to execute insert")

		If model.primaryKey And model.primaryKey.isAuto Then
			Local id:Long = orm.dialect.ReadGeneratedId(query)
			model.primaryKey.typeField.SetLong(obj, id)
		End If

		query.Free()

	End Method

	Method BuildInsertSql:String()
		Local sql:TStringBuilder = New TStringBuilder
		Local count:Int = 0

		sql.Append("INSERT INTO ")
		sql.Append(orm.dialect.QuoteIdentifier(model.tableName))
		sql.Append(" (")

		For Local fld:TOrmField = EachIn model.fields
			If ShouldSkipInsertField(fld) Then Continue
			If count > 0 Then sql.Append(", ")
			sql.Append(orm.dialect.QuoteIdentifier(fld.columnName))
			count :+ 1
		Next

		sql.Append(") VALUES (")

		For Local i:Int = 0 Until count
			If i > 0 Then sql.Append(", ")
			sql.Append(orm.dialect.Placeholder(i + 1))
		Next

		sql.Append(")")

		' append any database-specific clause needed to return the generated id for auto-increment primary keys
		sql.Append(orm.dialect.InsertReturningClause(model))

		Return sql.ToString()
	End Method

	Method ShouldSkipInsertField:Int(fld:TOrmField)
		If fld.isPrimaryKey And fld.isAuto Then
			Return True
		End If
		Return False
	End Method

	Method BindInsertValues(query:TDatabaseQuery, obj:Object)
		For Local fld:TOrmField = EachIn model.fields
			If ShouldSkipInsertField(fld) Then
				Continue
			End If
			BindFieldValue(query, obj, fld)
		Next
	End Method

	Method BindFieldValue(query:TDatabaseQuery, obj:Object, fld:TOrmField)

		Local ty:TTypeId = fld.typeField.TypeId()

		If fld.isJson Then
			Local value:Object = fld.typeField.Get(obj)
			If Not value Then
				query.AddString(Null)
			Else
				query.AddString(orm.jconv.ToJson(value))
			End If
			Return
		End If

		If fld.isBool Then
			orm.dialect.AddBool(query, fld.typeField.GetInt(obj))
			Return
		End If

		If fld.isDecimal Then
			orm.dialect.AddDecimal(query, TDecimal(fld.typeField.Get(obj)))
			Return
		End If

		If fld.isEnum Then
			If fld.isEnumString Then
				query.AddString(fld.typeField.GetEnumAsString(obj))
				Return
			End If
			' non-string, fallthrough...
			ty = ty.UnderlyingType()
		End If

		Select ty
			Case StringTypeId
				query.AddString(fld.typeField.GetString(obj))
				Return
			Case ByteTypeId
				orm.dialect.AddByte(query, fld.typeField.GetByte(obj))
				Return
			Case ShortTypeId
				orm.dialect.AddShort(query, fld.typeField.GetShort(obj))
				Return
			Case IntTypeId
				query.AddInt(fld.typeField.GetInt(obj))
				Return
			Case UIntTypeId
				orm.dialect.AddUInt(query, fld.typeField.GetUInt(obj))
				Return
			Case LongTypeId, LongIntTypeId
				query.AddLong(fld.typeField.GetLong(obj))
				Return
			Case ULongTypeId, ULongIntTypeId
				orm.dialect.AddULong(query, fld.typeField.GetULong(obj))
				Return
			Case FloatTypeId
				query.AddFloat(fld.typeField.GetFloat(obj))
				Return
			Case DoubleTypeId
				query.AddDouble(fld.typeField.GetDouble(obj))
				Return
		End Select

		Throw New TOrmException("Unsupported field type for column: " + fld.name + " (" + ty.Name() + ")")
	End Method

	Method UpdateObject(obj:Object)
		If Not obj Then
			Throw New TOrmException("Cannot update Null object")
		End If

		If Not model.primaryKey Then
			Throw New TOrmException("Cannot update model without primary key: " + model.typeId.Name())
		End If

		Local sql:String = BuildUpdateSql()
		Local query:TDatabaseQuery = PrepareQuery(sql)

		BindUpdateValues(query, obj)
		BindPrimaryKeyValue(query, obj)

		ExecuteQuery(query, sql, "Failed to execute update")

		query.Free()
	End Method

	Method BuildUpdateSql:String()
		Local sql:TStringBuilder = New TStringBuilder
		Local count:Int = 0
		sql.Append("UPDATE ")
		sql.Append(orm.dialect.QuoteIdentifier(model.tableName))
		sql.Append(" SET ")
		For Local fld:TOrmField = EachIn model.fields
			If ShouldSkipUpdateField(fld) Then
				Continue
			End If
			If count > 0 Then
				sql.Append(", ")
			End If
			sql.Append(orm.dialect.QuoteIdentifier(fld.columnName))
			sql.Append(" = ")
			sql.Append(orm.dialect.Placeholder(count + 1))
			count :+ 1
		Next
		sql.Append(" WHERE ")
		sql.Append(orm.dialect.QuoteIdentifier(model.primaryKey.columnName))
		sql.Append(" = ")
		sql.Append(orm.dialect.Placeholder(count + 1))
		Return sql.ToString()
	End Method

	Method ShouldSkipUpdateField:Int(fld:TOrmField)
		If fld.isPrimaryKey Then
			Return True
		End If
		Return False
	End Method

	Method BindUpdateValues(query:TDatabaseQuery, obj:Object)
		For Local fld:TOrmField = EachIn model.fields
			If ShouldSkipUpdateField(fld) Then
				Continue
			End If
			BindFieldValue(query, obj, fld)
		Next
	End Method

	Method BindPrimaryKeyValue(query:TDatabaseQuery, obj:Object)
		BindFieldValue(query, obj, model.primaryKey)
	End Method

	Method RemoveObject(obj:Object)
		If Not obj Then
			Throw New TOrmException("Cannot remove Null object")
		End If

		If Not model.primaryKey Then
			Throw New TOrmException("Cannot remove model without primary key: " + model.typeId.Name())
		End If

		Local sql:String = BuildDeleteSql()
		Local query:TDatabaseQuery = PrepareQuery(sql)
		BindPrimaryKeyValue(query, obj)

		ExecuteQuery(query, sql, "Failed to execute delete")

		query.Free()
	End Method

	Method BuildDeleteSql:String()
		Local sql:TStringBuilder = New TStringBuilder
		sql.Append("DELETE FROM ")
		sql.Append(orm.dialect.QuoteIdentifier(model.tableName))
		sql.Append(" WHERE ")
		sql.Append(orm.dialect.QuoteIdentifier(model.primaryKey.columnName))
		sql.Append(" = ")
		sql.Append(orm.dialect.Placeholder(1))
		Return sql.ToString()
	End Method

	Method FindByIdObject:Object(id:Int)
		Local sql:String = BuildFindByIdSql()
		Local query:TDatabaseQuery = PrepareQuery(sql)
		query.AddInt(id)
		Return ExecuteFindOne(query, sql)
	End Method

	Method FindByIdObject:Object(id:Long)
		Local sql:String = BuildFindByIdSql()
		Local query:TDatabaseQuery = PrepareQuery(sql)
		query.AddLong(id)
		Return ExecuteFindOne(query, sql)
	End Method

	Method FindByIdObject:Object(id:String)
		Local sql:String = BuildFindByIdSql()
		Local query:TDatabaseQuery = PrepareQuery(sql)
		query.AddString(id)
		Return ExecuteFindOne(query, sql)
	End Method

	Method ExecuteFindOne:Object(query:TDatabaseQuery, sql:String)
		ExecuteQuery(query, sql)
		
		Local obj:Object = Null

		If query.NextRow() Then
			obj = ObjectFromCurrentRow(query)
		End If

		query.Free()

		Return obj
	End Method

	Method BuildFindByIdSql:String()
		If Not model.primaryKey Then
			Throw New TOrmException("Cannot find model without primary key: " + model.typeId.Name())
		End If

		Local sql:TStringBuilder = New TStringBuilder
		sql.Append("SELECT ")
		sql.Append(BuildSelectColumnList())
		sql.Append(" FROM ")
		sql.Append(orm.dialect.QuoteIdentifier(model.tableName))
		sql.Append(" WHERE ")
		sql.Append(orm.dialect.QuoteIdentifier(model.primaryKey.columnName))
		sql.Append(" = ")
		sql.Append(orm.dialect.Placeholder(1))
		
		Return sql.ToString()
	End Method

	Method BuildSelectColumnList:String()
		Local sql:TStringBuilder = New TStringBuilder
		For Local i:Int = 0 Until model.fields.Count()
			If i > 0 Then sql.Append(", ")
			Local fld:TOrmField = model.fields.Get(i)
			sql.Append(orm.dialect.QuoteIdentifier(fld.columnName))
		Next

		Return sql.ToString()
	End Method

	Method ObjectFromCurrentRow:Object(query:TDatabaseQuery)
		Local obj:Object = model.typeId.NewObject()
		For Local i:Int = 0 Until model.fields.Count()
			Local fld:TOrmField = model.fields.Get(i)
			Local value:TDBType = query.Value(i)
			SetFieldFromDbValue(obj, fld, value)
		Next
		Return obj
	End Method

	Method SetFieldFromDbValue(obj:Object, fld:TOrmField, value:TDBType)

		If Not value Or value.IsNull() Then
			Return
		End If

		If fld.isJson Then
			Local json:String = value.GetString()

			If json = Null Or json.Trim() = "" Then
				Return
			End If

			Local fieldValue:Object = orm.jconv.FromJson(json, fld.typeField.TypeId(), Null)
			fld.typeField.Set(obj, fieldValue)
			Return
		End If

		If fld.isBool Then
			fld.typeField.SetInt(obj, orm.dialect.BoolFromDatabase(value))
			Return
		End If

		If fld.isDecimal Then
			fld.typeField.Set(obj, value.GetDecimal())
			Return
		End If

		Local ty:TTypeId = fld.typeField.TypeId()

		If fld.isEnum Then
			If fld.isEnumString Then
				fld.typeField.SetEnum(obj, value.GetString())
				Return		
			End If
			' non string, fallthrough...
			ty = ty.UnderlyingType()
		End If

		If ty = StringTypeId Then
			fld.typeField.SetString(obj, value.GetString())
			Return
		End If

		If ty = ByteTypeId Then
			fld.typeField.SetByte(obj, orm.dialect.ByteFromDatabase(value))
			Return
		End If

		If ty = ShortTypeId Then
			fld.typeField.SetShort(obj, orm.dialect.ShortFromDatabase(value))
			Return
		End If

		If ty = IntTypeId Then
			fld.typeField.SetInt(obj, value.GetInt())
			Return
		End If

		If ty = UIntTypeId Then
			fld.typeField.SetUInt(obj, orm.dialect.UIntFromDatabase(value))
			Return
		End If

		If ty = LongTypeId Then
			fld.typeField.SetLong(obj, value.GetLong())
			Return
		End If

		If ty = ULongTypeId Then
			fld.typeField.SetULong(obj, orm.dialect.ULongFromDatabase(value))
			Return
		End If

		If ty = FloatTypeId Then
			fld.typeField.SetFloat(obj, value.GetFloat())
			Return
		End If

		If ty = DoubleTypeId Then
			fld.typeField.SetDouble(obj, value.GetDouble())
			Return
		End If

		Throw New TOrmException("Unsupported field type for column: " + fld.name)

	End Method

	Method BindIdValue(query:TDatabaseQuery, fld:TOrmField, value:Int)
		query.AddInt(value)
	End Method

	Method BindIdValue(query:TDatabaseQuery, fld:TOrmField, value:Long)
		query.AddLong(value)
	End Method

	Method BindIdValue(query:TDatabaseQuery, fld:TOrmField, value:String)
		query.AddString(value)
	End Method

	Method PopulateFindAll(collector:TOrmResultCollector, orderBy:TOrmOrder = Null, limit:Int = 0, offset:Int = 0)
		Local sql:String = BuildFindWhereSql(Null, orderBy, limit, offset)
		Local query:TDatabaseQuery = PrepareQuery(sql)

		ExecuteQuery(query, sql, "Failed to execute find all")

		While query.NextRow()
			collector.Add(ObjectFromCurrentRow(query))
		Wend

		query.Free()
	End Method

	Method BuildFindWhereSql:String(whereSql:String, orderBy:TOrmOrder = Null, limit:Int = 0, offset:Int = 0)
		Local sql:TStringBuilder = New TStringBuilder

		sql.Append("SELECT ")
		sql.Append(BuildSelectColumnList())

		sql.Append(" FROM ")
		sql.Append(orm.dialect.QuoteIdentifier(model.tableName))

		If whereSql And whereSql.Trim() <> "" Then
			sql.Append(" WHERE ")
			sql.Append(whereSql)
		End If

		If orderBy And orderBy.items.Count() > 0 Then
			sql.Append(BuildOrderBySql(orderBy))
		End If

		If limit > 0 Then
			sql.Append(" LIMIT ")
			sql.Append(limit)
			If offset > 0 Then
				sql.Append(" OFFSET ")
				sql.Append(offset)
			End If
		End If

		Return sql.ToString()
	End Method

	Method PopulateFindWhere(whereSql:String, params:TOrmParams, collector:TOrmResultCollector, orderBy:TOrmOrder = Null, limit:Int = 0, offset:Int = 0)
		Local sql:String = BuildFindWhereSql(whereSql, orderBy, limit, offset)
		Local query:TDatabaseQuery = PrepareQuery(sql)

		If params Then
			params.BindTo(query, orm.dialect)
		End If

		ExecuteQuery(query, sql, "Failed to execute find where")

		While query.NextRow()
			collector.Add(ObjectFromCurrentRow(query))
		Wend

		query.Free()
	End Method

	Method FindOneWhereObject:Object(whereSql:String, params:TOrmParams = Null)

		Local sql:String = BuildFindWhereSql(whereSql, Null, 1)
		Local query:TDatabaseQuery = PrepareQuery(sql)

		If params Then
			params.BindTo(query, orm.dialect)
		End If

		ExecuteQuery(query, sql, "Failed to execute find one where")
		
		Local obj:Object = Null
		If query.NextRow() Then
			obj = ObjectFromCurrentRow(query)
		End If
		query.Free()
		Return obj

	End Method

	Method CountAll:Long()
		Return CountWhere(Null, TOrmParams(Null))
	End Method

	Method CountWhere:Long(whereSql:String, params:TOrmParams = Null)
		Local sql:String = BuildCountWhereSql(whereSql)
		Local query:TDatabaseQuery = PrepareQuery(sql)

		If params Then
			params.BindTo(query, orm.dialect)
		End If

		ExecuteQuery(query, sql, "Failed to execute count query")

		Local count:Long = 0
		If query.NextRow() Then
			count = query.Value(0).GetLong()
		End If
		query.Free()

		Return count
	End Method

	Method BuildCountWhereSql:String(whereSql:String)
		Local sql:TStringBuilder = New TStringBuilder
		sql.Append("SELECT COUNT(*) FROM ")
		sql.Append(orm.dialect.QuoteIdentifier(model.tableName))

		If whereSql And whereSql.Trim() <> "" Then
			sql.Append(" WHERE ")
			sql.Append(whereSql)
		End If

		Return sql.ToString()
	End Method

	Method CountWhere:Long(whereSql:String, value:Int)
		Return CountWhere(whereSql, Params().AddInt(value))
	End Method

	Method CountWhere:Long(whereSql:String, value:Long)
		Return CountWhere(whereSql, Params().AddLong(value))
	End Method

	Method CountWhere:Long(whereSql:String, value:String)
		Return CountWhere(whereSql, Params().AddString(value))
	End Method

	Method CountWhere:Long(whereSql:String, value:Double)
		Return CountWhere(whereSql, Params().AddDouble(value))
	End Method

	Method ExistsWhere:Int(whereSql:String, params:TOrmParams = Null)
		Local sql:String = BuildExistsWhereSql(whereSql)
		Local query:TDatabaseQuery = PrepareQuery(sql)

		If params Then
			params.BindTo(query, orm.dialect)
		End If

		ExecuteQuery(query, sql, "Failed to execute exists query")

		Local exists:Int = query.NextRow()

		query.Free()

		Return exists
	End Method
	
	Method BuildExistsWhereSql:String(whereSql:String)
		Local sql:TStringBuilder = New TStringBuilder

		sql.Append("SELECT 1 FROM ")
		sql.Append(orm.dialect.QuoteIdentifier(model.tableName))

		If whereSql And whereSql.Trim() <> "" Then
			sql.Append(" WHERE ")
			sql.Append(whereSql)
		End If

		Return sql.ToString()
	End Method

	Method ExistsWhere:Int(whereSql:String, value:Int)
		Return ExistsWhere(whereSql, Params().AddInt(value))
	End Method

	Method ExistsWhere:Int(whereSql:String, value:Long)
		Return ExistsWhere(whereSql, Params().AddLong(value))
	End Method

	Method ExistsWhere:Int(whereSql:String, value:UInt)
		Return ExistsWhere(whereSql, Params().AddUInt(value))
	End Method

	Method ExistsWhere:Int(whereSql:String, value:ULong)
		Return ExistsWhere(whereSql, Params().AddULong(value))
	End Method

	Method ExistsWhere:Int(whereSql:String, value:String)
		Return ExistsWhere(whereSql, Params().AddString(value))
	End Method

	Rem
	bbdoc: Convenience method to check if a record exists with the given primary key value.
	End Rem
	Method ExistsById:Int(id:Long)
		Return ExistsWhere(model.primaryKey.columnName + " = ?", id)
	End Method

	Method BuildOrderBySql:String(order:TOrmOrder)
		If Not order Or order.items.Count() = 0 Then
			Return ""
		End If

		Local sql:TStringBuilder = New TStringBuilder

		sql.Append(" ORDER BY ")

		For Local i:Int = 0 Until order.items.Count()
			If i > 0 Then
				sql.Append(", ")
			End If

			Local item:TOrmOrderItem = order.items.Get(i)
			Local fld:TOrmField = model.FieldByName(item.fieldName)

			If Not fld Then
				Throw New TOrmException("Unknown order field: " + item.fieldName)
			End If

			sql.Append(orm.dialect.QuoteIdentifier(fld.columnName))

			If item.ascending Then
				sql.Append(" ASC")
			Else
				sql.Append(" DESC")
			End If
		Next

		Return sql.ToString()
	End Method

	Method QueryError:TOrmDatabaseException(sql:String, message:String = Null)
		Return TOrmDatabaseException.Create(sql, orm.db.Error(), message)
	End Method

	Method PrepareQuery:TDatabaseQuery(sql:String)
		Local rewrittenSql:String = orm.dialect.RewritePlaceholders(sql)

		Local query:TDatabaseQuery = TDatabaseQuery.Create(orm.db)
		If Not query.Prepare(rewrittenSql) Then
			Local err:TOrmDatabaseException = QueryError(rewrittenSql)
			query.Free()
			Throw err
		End If

		Return query
	End Method

	Method ExecuteQuery(query:TDatabaseQuery, sql:String, msg:String = Null)
		If Not query.Execute() Then
			Local err:TOrmDatabaseException = QueryError(sql, msg)
			query.Free()
			Throw err
		End If
	End Method

	Method RemoveWhere:Int(whereSql:String, params:TOrmParams = Null)
		Local sql:String = BuildRemoveWhereSql(whereSql)
		Local query:TDatabaseQuery = PrepareQuery(sql)

		If params Then
			params.BindTo(query, orm.dialect)
		End If

		ExecuteQuery(query, sql)

		Local affected:Int = query.RowsAffected()

		query.Free()

		Return affected
	End Method

	Method BuildRemoveWhereSql:String(whereSql:String)
		Local sql:TStringBuilder = New TStringBuilder
		sql.Append("DELETE FROM ")
		sql.Append(orm.dialect.QuoteIdentifier(model.tableName))

		If whereSql And whereSql.Trim() <> "" Then
			sql.Append(" WHERE ")
			sql.Append(whereSql)
		End If

		Return sql.ToString()
	End Method

	Method RemoveWhere:Int(whereSql:String, value:Int)
		Return RemoveWhere(whereSql, Params().AddInt(value))
	End Method

	Method RemoveWhere:Int(whereSql:String, value:Long)
		Return RemoveWhere(whereSql, Params().AddLong(value))
	End Method

	Method RemoveWhere:Int(whereSql:String, value:String)
		Return RemoveWhere(whereSql, Params().AddString(value))
	End Method

End Type

Type TOrmDao<T> Where T Extends Object Extends TOrmDaoBase

	Method Init:TOrmDao<T>(orm:TOrm, typeName:String)
		Self.orm = orm
		Self.model = orm.GetOrBuildModelForName(typeName)
		Return Self
	End Method

	Method Save(obj:T)
		SaveObject(obj)
	End Method

	Method Update(obj:T)
		UpdateObject(obj)
	End Method

	Method Remove(obj:T)
		RemoveObject(obj)
	End Method

	Method FindById:T(id:Int)
		Return T(FindByIdObject(id))
	End Method

	Method FindById:T(id:Long)
		Return T(FindByIdObject(id))
	End Method

	Method FindById:T(id:String)
		Return T(FindByIdObject(id))
	End Method

	Method FindAll:TArrayList<T>(orderBy:TOrmOrder = Null, limit:Int = 0, offset:Int = 0)
		Local results:TArrayList<T> = New TArrayList<T>
		Local collector:TOrmTypedResultCollector<T> = New TOrmTypedResultCollector<T>(results)
		PopulateFindAll(collector, orderBy, limit, offset)
		Return results
	End Method

	Method FindWhere:TArrayList<T>(whereSql:String, params:TOrmParams = Null, orderBy:TOrmOrder = Null, limit:Int = 0, offset:Int = 0)
		Local results:TArrayList<T> = New TArrayList<T>
		Local collector:TOrmTypedResultCollector<T> = New TOrmTypedResultCollector<T>(results)
		
		PopulateFindWhere(whereSql, params, collector, orderBy, limit, offset)

		Return results
	End Method

	Method FindWhere:TArrayList<T>(whereSql:String, value:Int, orderBy:TOrmOrder = Null, limit:Int = 0, offset:Int = 0)
		Return FindWhere(whereSql, Params().AddInt(value), orderBy, limit, offset)
	End Method

	Method FindWhere:TArrayList<T>(whereSql:String, value:Long, orderBy:TOrmOrder = Null, limit:Int = 0, offset:Int = 0)
		Return FindWhere(whereSql, Params().AddLong(value), orderBy, limit, offset)
	End Method

	Method FindWhere:TArrayList<T>(whereSql:String, value:UInt, orderBy:TOrmOrder = Null, limit:Int = 0, offset:Int = 0)
		Return FindWhere(whereSql, Params().AddUInt(value), orderBy, limit, offset)
	End Method

	Method FindWhere:TArrayList<T>(whereSql:String, value:ULong, orderBy:TOrmOrder = Null, limit:Int = 0, offset:Int = 0)
		Return FindWhere(whereSql, Params().AddULong(value), orderBy, limit, offset)
	End Method

	Method FindWhere:TArrayList<T>(whereSql:String, value:String, orderBy:TOrmOrder = Null, limit:Int = 0, offset:Int = 0)
		Return FindWhere(whereSql, Params().AddString(value), orderBy, limit, offset)
	End Method

	Method FindOneWhere:T(whereSql:String, params:TOrmParams = Null)
		Return T(FindOneWhereObject(whereSql, params))
	End Method

	Method FindOneWhere:T(whereSql:String, value:Int)
		Return FindOneWhere(whereSql, Params().AddInt(value))
	End Method

	Method FindOneWhere:T(whereSql:String, value:Long)
		Return FindOneWhere(whereSql, Params().AddLong(value))
	End Method

	Method FindOneWhere:T(whereSql:String, value:UInt)
		Return FindOneWhere(whereSql, Params().AddUInt(value))
	End Method

	Method FindOneWhere:T(whereSql:String, value:ULong)
		Return FindOneWhere(whereSql, Params().AddULong(value))
	End Method

	Method FindOneWhere:T(whereSql:String, value:String)
		Return FindOneWhere(whereSql, Params().AddString(value))
	End Method

End Type

Type TOrmResultCollector Abstract
	Method Add(obj:Object) Abstract
End Type

Type TOrmTypedResultCollector<T> Where T Extends Object Extends TOrmResultCollector

	Field results:TArrayList<T>

	Method New(results:TArrayList<T>)
		Self.results = results
	End Method

	Method Add(obj:Object)
		results.Add(T(obj))
	End Method

End Type

Type TOrmModelBuilder
	
	Field registry:TOrmRegistry
	Field nameBuilder:TOrmNameBuilder

	Method New(registry:TOrmRegistry, namingStyle:EOrmNamingStyle = EOrmNamingStyle.LowerCaseUnderscore)
		Self.registry = registry
		Self.nameBuilder = New TOrmNameBuilder(namingStyle)
	End Method

	Method BuildModel:TOrmModel(typeName:String)
		Local ty:TTypeId = TTypeId.ForName(typeName)
		If Not ty Then
			Throw New TOrmTypeNotFoundException(typeName)
		End If

		Return BuildModel(ty)
	End Method

	Method BuildModel:TOrmModel(typeId:TTypeId)

		' check if model already exists in registry
		If registry And registry.models.ContainsKey(typeId) Then
			Return TOrmModel(registry.models[typeId])
		End If

		Local model:TOrmModel = New TOrmModel
		model.typeId = typeId
		model.tableName = DetermineTableName(typeId)
		model.fields = New TArrayList<TOrmField>
		model.indexes = New TArrayList<TOrmIndex>

		For Local fld:TField = EachIn typeId.EnumFields()

			If ShouldIgnoreField(fld) Then
				Continue
			End If

			Local ormField:TOrmField = BuildField(fld)

			model.fields.Add(ormField)
			CollectIndexes(model, ormField, fld)

			If ormField.isPrimaryKey Then
				If model.primaryKey Then
					Throw New TOrmMultiplePrimaryKeysException(typeId.Name())
				End If
				model.primaryKey = ormField
			End If
		Next

		If registry Then
			registry.models[typeId] = model
		End If

		Return model
	End Method

	Method CollectIndexes(model:TOrmModel, ormField:TOrmField, fld:TField)
		If fld.HasMetadata("index") Then
			Local indexName:String = fld.Metadata("index")
			If Not indexName Or indexName = "1" Then ' metadata without a value default to "1"
				indexName = AutoIndexName(model.tableName, ormField.columnName, False)
			End If
			AddIndexField(model, indexName, ormField, False)
		End If

		If fld.HasMetadata("unique") Then
			Local uniqueName:String = fld.Metadata("unique")
			' plain { unique } is already handled as column UNIQUE
			' named { unique = "..." } becomes a composite unique index
			If uniqueName AND uniqueName <> "1" Then
				AddIndexField(model, uniqueName, ormField, True)
			End If
		End If
	End Method

	Method AddIndexField(model:TOrmModel, indexName:String, fld:TOrmField, isUnique:Int)
		Local index:TOrmIndex = FindIndex(model, indexName)

		If Not index Then
			index = New TOrmIndex
			index.name = indexName
			index.fields = New TArrayList<TOrmField>
			index.isUnique = isUnique
			model.indexes.Add(index)
		Else If index.isUnique <> isUnique Then
			Throw New TOrmException("Index '" + indexName + "' cannot be both unique and non-unique")
		End If

		index.fields.Add(fld)
	End Method

	Method FindIndex:TOrmIndex(model:TOrmModel, indexName:String)
		For Local index:TOrmIndex = EachIn model.indexes
			If index.name = indexName Then
				Return index
			End If
		Next

		Return Null
	End Method

	Method AutoIndexName:String(tableName:String, columnName:String, isUnique:Int)
		Local prefix:String

		If isUnique Then
			prefix = "uq_"
		Else
			prefix = "idx_"
		End If
		Local base:String = prefix + tableName + "_" + columnName

		Local hash:UInt = base.HashCode()
		Local hex:String = String.FromBytesAsHex(VarPtr hash, 4, False)

		Local indexHash:String = hex[0..4]

		Return base + "_orm" + indexHash
	End Method

	Method ShouldIgnoreField:Int(fld:TField)

		If fld.HasMetadata("transient") Then
			Return True
		End If
		Return False

	End Method

	Method BuildField:TOrmField(fld:TField)
		Local ormField:TOrmField = New TOrmField
		ormField.typeField = fld
		ormField.name = fld.Name()
		ormField.columnName = DetermineColumnName(fld)
		ormField.isPrimaryKey = fld.HasMetadata("pk")
		ormField.isAuto = fld.HasMetadata("auto")
		ormField.nullable = fld.HasMetadata("nullable")
		ormField.isUnique = fld.HasMetadata("unique")
		ormField.isJson = fld.HasMetadata("json")
		ormField.isBool = fld.HasMetadata("bool")
		If fld.TypeId().Name() = "TDecimal" Then
			ormField.isDecimal = True
		End If
		ormField.isEnum = fld.TypeId().IsEnum() Or fld.TypeId().IsFlagsEnum()
		ormField.isEnumString = ormField.isEnum And fld.HasMetadata("enum_string")
		Return ormField
	End Method

	Method DetermineTableName:String(typeId:TTypeId)
		If typeId.HasMetadata("table") Then
			Return typeId.Metadata("table")
		End If

		Return nameBuilder.ApplyNamingStyle(typeId.Name())
	End Method

	Method DetermineColumnName:String(fld:TField)
		If fld.HasMetadata("column") Then
			Return fld.Metadata("column")
		End If

		Return nameBuilder.ApplyNamingStyle(fld.Name())
	End Method

	Method ApplyNamingStyle:String(name:String)
		Return nameBuilder.ApplyNamingStyle(name)
	End Method

End Type

Type TOrmNameBuilder

	Field namingStyle:EOrmNamingStyle

	Method New(namingStyle:EOrmNamingStyle)
		Self.namingStyle = namingStyle
	End Method

	Method ApplyNamingStyle:String(name:String)

		Local words:String[] = SplitIdentifierWords(name)
		If words.Length = 0 Then
			Return ""
		End If
		Select namingStyle
			Case EOrmNamingStyle.LowerCase
				Return JoinWords(words, "").ToLower()
			Case EOrmNamingStyle.UpperCase
				Return JoinWords(words, "").ToUpper()
			Case EOrmNamingStyle.CamelCase
				Return ToCamelCase(words)
			Case EOrmNamingStyle.PascalCase
				Return ToPascalCase(words)
			Case EOrmNamingStyle.LowerCaseUnderscore
				Return JoinWords(words, "_").ToLower()
			Case EOrmNamingStyle.UpperCaseUnderscore
				Return JoinWords(words, "_").ToUpper()
		End Select
		Return name

	End Method

	Function SplitIdentifierWords:String[](name:String)

		Local words:String[] = New String[0]
		Local current:TStringBuilder = New TStringBuilder

		For Local i:Int = 0 Until name.Length

			Local ch:Int = name[i]

			If ch = Asc("_") Then
				FlushWord(words, current)
				Continue
			End If

			Local prev:Int = 0
			Local nextCh:Int = 0

			If i > 0 Then prev = name[i - 1]
			If i < name.Length - 1 Then nextCh = name[i + 1]

			Local shouldSplit:Int = False

			If current.Length() > 0 Then

				If IsLower(prev) And IsUpper(ch) Then
					shouldSplit = True
				End If

				If IsDigit(prev) <> IsDigit(ch) Then
					shouldSplit = True
				End If

				If IsUpper(prev) And IsUpper(ch) And IsLower(nextCh) Then
					shouldSplit = True
				End If

			End If

			If shouldSplit Then
				FlushWord(words, current)
			End If

			current.AppendChar(ch)

		Next

		FlushWord(words, current)

		Return words

	End Function

	Function FlushWord(words:String[] Var, current:TStringBuilder)
		If current.Length() = 0 Then
			Return
		End If
		words :+ [current.ToLower().ToString()]
		current.SetLength(0)
	End Function

	Function IsUpper:Int(ch:Int)
		Return ch >= Asc("A") And ch <= Asc("Z")
	End Function

	Function IsLower:Int(ch:Int)
		Return ch >= Asc("a") And ch <= Asc("z")
	End Function

	Function IsDigit:Int(ch:Int)
		Return ch >= Asc("0") And ch <= Asc("9")
	End Function

	Function JoinWords:String(words:String[], separator:String)

		Local builder:TStringBuilder = New TStringBuilder
		For Local i:Int = 0 Until words.Length
			If i > 0 Then
				builder.Append(separator)
			End If
			builder.Append(words[i])
		Next
		Return builder.ToString()

	End Function

	Function ToCamelCase:String(words:String[])

		Local builder:TStringBuilder = New TStringBuilder
		For Local i:Int = 0 Until words.Length
			If i = 0 Then
				builder.Append(words[i].ToLower())
			Else
				builder.Append(CapitaliseWord(words[i]))
			End If
		Next
		Return builder.ToString()

	End Function

	Function ToPascalCase:String(words:String[])

		Local builder:TStringBuilder = New TStringBuilder
		For Local word:String = EachIn words
			builder.Append(CapitaliseWord(word))
		Next
		Return builder.ToString()

	End Function

	Function CapitaliseWord:String(word:String)

		If word.Length = 0 Then
			Return ""
		End If
		If word.Length = 1 Then
			Return word.ToUpper()
		End If
		Return word[..1].ToUpper() + word[1..].ToLower()

	End Function

End Type

Type TOrmTransaction Implements ICloseable

	Field orm:TOrm
	Field completed:Int
	Field isStrict:Int = True

	Method New(orm:TOrm, isStrict:Int = True)
		Self.orm = orm
		Self.isStrict = isStrict

		If Not orm.db.HasTransactionSupport() Then
			Throw New TOrmException("Database does not support transactions")
		End If

		If Not orm.db.StartTransaction() Then
			Throw New TOrmException("Failed to start transaction")
		End If
	End Method

	Method Commit()
		If completed Then Return

		If Not orm.db.Commit() Then
			Throw New TOrmException("Failed to commit transaction")
		End If

		completed = True
	End Method

	Method Rollback()
		If completed Then Return

		If Not orm.db.Rollback() Then
			Throw New TOrmException("Failed to rollback transaction")
		End If

		completed = True
	End Method

	Method Close()
		If completed Then Return

		orm.db.Rollback()
		completed = True

		If isStrict Then
			Throw New TOrmException("Transaction closed without Commit()")
		End If
	End Method

End Type

Rem
bbdoc: Returns a new instance of TOrmParams.
End Rem
Function Params:TOrmParams()
	Return New TOrmParams
End Function

Type TOrmParams

	Field values:TArrayList<TDBType> = New TArrayList<TDBType>

	Method Add:TOrmParams(value:TDBType)
		values.Add(value)
		Return Self
	End Method

	Method AddNull:TOrmParams()
		values.Add(Null)
		Return Self
	End Method

	Method AddString:TOrmParams(value:String)
		values.Add(TDBString.Set(value))
		Return Self
	End Method

	Method Add:TOrmParams(value:String)
		values.Add(TDBString.Set(value))
		Return Self
	End Method

	Method AddByte:TOrmParams(value:Byte)
		values.Add(TDBByte.Set(value))
		Return Self
	End Method

	Method Add:TOrmParams(value:Byte)
		values.Add(TDBByte.Set(value))
		Return Self
	End Method

	Method AddShort:TOrmParams(value:Short)
		values.Add(TDBShort.Set(value))
		Return Self
	End Method

	Method Add:TOrmParams(value:Short)
		values.Add(TDBShort.Set(value))
		Return Self
	End Method

	Method AddInt:TOrmParams(value:Int)
		values.Add(TDBInt.Set(value))
		Return Self
	End Method

	Method Add:TOrmParams(value:Int)
		values.Add(TDBInt.Set(value))
		Return Self
	End Method

	Method AddUInt:TOrmParams(value:UInt)
		values.Add(TDBUInt.Set(value))
		Return Self
	End Method

	Method Add:TOrmParams(value:UInt)
		values.Add(TDBUInt.Set(value))
		Return Self
	End Method

	Method AddLong:TOrmParams(value:Long)
		values.Add(TDBLong.Set(value))
		Return Self
	End Method

	Method Add:TOrmParams(value:Long)
		values.Add(TDBLong.Set(value))
		Return Self
	End Method

	Method AddULong:TOrmParams(value:ULong)
		values.Add(TDBULong.Set(value))
		Return Self
	End Method

	Method Add:TOrmParams(value:ULong)
		values.Add(TDBULong.Set(value))
		Return Self
	End Method

	Method AddFloat:TOrmParams(value:Float)
		values.Add(TDBFloat.Set(value))
		Return Self
	End Method

	Method Add:TOrmParams(value:Float)
		values.Add(TDBFloat.Set(value))
		Return Self
	End Method

	Method AddDouble:TOrmParams(value:Double)
		values.Add(TDBDouble.Set(value))
		Return Self
	End Method

	Method Add:TOrmParams(value:Double)
		values.Add(TDBDouble.Set(value))
		Return Self
	End Method

	Method AddDecimal:TOrmParams(value:TDecimal)
		values.Add(TDBDecimal.Set(value))
		Return Self
	End Method

	Method Add:TOrmParams(value:TDecimal)
		values.Add(TDBDecimal.Set(value))
		Return Self
	End Method

	Method AddBool:TOrmParams(value:Int)
		values.Add(TDBBool.Set(value))
		Return Self
	End Method

	Method BindTo(query:TDatabaseQuery, dialect:TOrmDialect)
		For Local value:TDBType = EachIn values
			dialect.AddBindValue(query, value)
		Next
	End Method

End Type

Type TOrmSchemaValidationReport

	Field issues:TArrayList<TOrmSchemaValidationIssue> = New TArrayList<TOrmSchemaValidationIssue>

	Method AddIssue(model:TOrmModel, message:String)
		Local issue:TOrmSchemaValidationIssue = New TOrmSchemaValidationIssue
		issue.model = model
		issue.message = message
		issues.Add(issue)
	End Method

	Method IsValid:Int()
		Return issues.Count() = 0
	End Method

	Method ToString:String()
		Local sb:TStringBuilder = New TStringBuilder
		For Local issue:TOrmSchemaValidationIssue = EachIn issues
			sb.Append(issue.model.typeId.Name())
			sb.Append(": ")
			sb.Append(issue.message)
			sb.Append("~n")
		Next
		Return sb.ToString()
	End Method

End Type

Type TOrmSchemaValidationIssue

	Field model:TOrmModel
	Field message:String

End Type

Type TOrmOrder

	Field items:TArrayList<TOrmOrderItem> = New TArrayList<TOrmOrderItem>

	Function By:TOrmOrder(fieldName:String)
		Local order:TOrmOrder = New TOrmOrder
		order.items.Add(New TOrmOrderItem(fieldName, True))
		Return order
	End Function

	Method Asc:TOrmOrder()
		TOrmOrderItem(items.Get(items.Count() - 1)).ascending = True
		Return Self
	End Method

	Method Desc:TOrmOrder()
		TOrmOrderItem(items.Get(items.Count() - 1)).ascending = False
		Return Self
	End Method

	Method ThenBy:TOrmOrder(fieldName:String)
		items.Add(New TOrmOrderItem(fieldName, True))
		Return Self
	End Method

End Type

Type TOrmOrderItem

	Field fieldName:String
	Field ascending:Int

	Method New(fieldName:String, ascending:Int = True)
		Self.fieldName = fieldName
		Self.ascending = ascending
	End Method

End Type

' exceptions

Type TOrmException Extends TRuntimeException
	Method New(message:String)
		Super.New(message)
	End Method
End Type

Type TOrmTypeNotFoundException Extends TOrmException
	Method New(typeName:String)
		Super.New("Type not found: " + typeName)
	End Method
End Type

Type TOrmMultiplePrimaryKeysException Extends TOrmException
	Method New(typeName:String)
		Super.New("Multiple primary keys defined in type: " + typeName)
	End Method
End Type

Type TOrmSchemaValidationException Extends TOrmException
	Method New(report:TOrmSchemaValidationReport)
		Super.New("Schema validation failed:~n" + report.ToString())
	End Method
End Type

Type TOrmDatabaseException Extends TOrmException

	Field sql:String
	Field dbError:TDatabaseError

	Method New(sql:String, dbError:TDatabaseError, msg:String = Null)
		Super.New(msg)
		Self.sql = sql
		Self.dbError = dbError		
	End Method

	Function Create:TOrmDatabaseException(sql:String, dbError:TDatabaseError, msg:String = Null)
		If Not msg Then
			msg = "Database error"
		End If

		If dbError And dbError.IsSet() Then
			msg :+ ": " + dbError.ToString()
		End If

		If sql Then
			msg :+ "~nSQL: " + sql
		End If

		Return New TOrmDatabaseException(sql, dbError, msg)
	End Function

End Type
