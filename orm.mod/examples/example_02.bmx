SuperStrict

Framework BRL.standardio
Import Database.OrmSQLite
import math.decimal

' This example demonstrates supported types and ranges for SQLite.
' It will attempt to save values of various types and then read them back to verify they were stored and retrieved correctly.

Local orm:TOrm = TOrm.Create("SQLITE", "maxtest.db")

Local entities:TOrmDao<TTestEntity> = New TOrmDao<TTestEntity>.Init(orm, "TTestEntity")

orm.CreateTable("TTestEntity")

entities.Save(MakeMinValueEntity())
entities.Save(MakeMaxValueEntity())

Local list:TArrayList<TTestEntity> = entities.FindAll()

For Local ent:TTestEntity = EachIn list
	Print "ID: " + ent.id
	Print "Byte Value: " + ent.byteValue
	Print "Short Value: " + ent.shortValue
	Print "Int Value: " + ent.intValue
	Print "Long Value: " + ent.longValue
	Print "UInt Value: " + ent.uIntValue
	Print "ULong Value: " + ent.uLongValue
	Print "Float Value: " + ent.floatValue
	Print "Double Value: " + ent.doubleValue
	Print "Decimal Value: " + ent.decimalValue.ToString()
	Print "String Value: " + ent.stringValue
	Print "Bool Value: " + ent.boolValue
	Print ""
Next


Type TTestEntity { table = "test_entity" }

	Field id:Long { pk auto }
	Field byteValue:Byte
	Field shortValue:Short
	Field intValue:Int
	Field longValue:Long
	Field uIntValue:UInt
	Field uLongValue:ULong
	Field floatValue:Float
	Field doubleValue:Double
	Field decimalValue:TDecimal
	Field stringValue:String

	Field boolValue:Int { bool }

End Type

Function MakeMinValueEntity:TTestEntity()
	Local ent:TTestEntity = New TTestEntity()
	ent.byteValue = 0
	ent.shortValue = 0
	ent.intValue = -2147483648:Int
	ent.longValue = -9223372036854775808:Long
	ent.uIntValue = 0
	ent.uLongValue = 0
	ent.floatValue = -3.4028235e+38:Float
	ent.doubleValue = 4.94065645841246544E-324:Double
	ent.decimalValue = Decimal("-7922816251426433759354395033559088")
	ent.stringValue = ""
	ent.boolValue = False
	Return ent
End Function

Function MakeMaxValueEntity:TTestEntity()
	Local ent:TTestEntity = New TTestEntity()
	ent.byteValue = 255
	ent.shortValue = 32767
	ent.intValue = 2147483647:Int
	ent.longValue = 9223372036854775807:Long
	ent.uIntValue = 4294967295:UInt
	ent.uLongValue = 18446744073709551615:ULong
	ent.floatValue = 3.4028235e+38:Float
	ent.doubleValue = 1.7976931348623157e+308:Double
	ent.decimalValue = Decimal("7922816251426433759354395033559087")
	ent.stringValue = "Test string with max values"
	ent.boolValue = True
	Return ent
End Function
