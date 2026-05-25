SuperStrict

Framework brl.standardio
Import BRL.MaxUnit
Import Database.OrmSQLite

New TTestSuite.run()

Type TOrmSqliteBasicCrudTest Extends TTest

	Method Test_SaveFindUpdateRemove_Works() { test }

		Local orm:TOrm = TOrm.Create("SQLITE", ":memory:")

		Local users:TOrmDao<TOrmTestUser> = New TOrmDao<TOrmTestUser>.Init(orm, "TOrmTestUser")

		orm.CreateTable("TOrmTestUser")

		Local user:TOrmTestUser = New TOrmTestUser
		user.name = "Alice"
		user.email = "alice@example.com"
		user.age = 30
		user.isActive = True

		users.Save(user)

		AssertTrue(user.id > 0, "Save should assign generated id to object")

		Local found:TOrmTestUser = users.FindById(user.id)

		AssertNotNull(found, "FindById should return saved user")
		AssertEquals(user.id, found.id, "Found user id should match saved id")
		AssertEquals("Alice", found.name, "Found user name should match saved name")
		AssertEquals("alice@example.com", found.email, "Found user email should match saved email")
		AssertEquals(30, found.age, "Found user age should match saved age")
		AssertTrue(found.isActive, "Found user active flag should match saved value")

		found.name = "Alice Green"
		found.age = 31
		users.Update(found)

		Local updated:TOrmTestUser = users.FindById(user.id)

		AssertNotNull(updated, "FindById should return updated user")
		AssertEquals("Alice Green", updated.name, "Updated user name should be persisted")
		AssertEquals(31, updated.age, "Updated user age should be persisted")

		AssertTrue(users.ExistsWhere("email = ?", Params().AddString("alice@example.com")), "ExistsWhere should find saved user by email")
		AssertEquals(1:Long, users.CountAll(), "CountAll should return one saved user")

		users.Remove(updated)

		Local removed:TOrmTestUser = users.FindById(user.id)

		AssertNull(removed, "FindById should return Null after user is removed")
		AssertEquals(0:Long, users.CountAll(), "CountAll should return zero after removal")

	End Method

End Type

Type TOrmSqliteQueryTest Extends TTest

	Method Test_FindWhere_ReturnsMatchingRows() { test }

		Local orm:TOrm = TOrm.Create("SQLITE", ":memory:")
		Local users:TOrmDao<TOrmTestUser> = New TOrmDao<TOrmTestUser>.Init(orm, "TOrmTestUser")
		orm.CreateTable("TOrmTestUser")
		Local alice:TOrmTestUser = New TOrmTestUser
		alice.name = "Alice"
		alice.email = "alice@example.com"
		alice.age = 30
		alice.isActive = True
		users.Save(alice)
		Local bob:TOrmTestUser = New TOrmTestUser
		bob.name = "Bob"
		bob.email = "bob@example.com"
		bob.age = 20
		bob.isActive = True
		users.Save(bob)
		Local results:TArrayList<TOrmTestUser> = users.FindWhere("age > ?", Params().AddInt(25))
		AssertEquals(1, results.Count(), "FindWhere should return one matching user")
		AssertEquals("Alice", results.Get(0).name, "FindWhere should return the expected user")
	End Method

	Method Test_FindOneWhere_ReturnsFirstMatchingRow() { test }
		Local orm:TOrm = TOrm.Create("SQLITE", ":memory:")
		Local users:TOrmDao<TOrmTestUser> = New TOrmDao<TOrmTestUser>.Init(orm, "TOrmTestUser")
		orm.CreateTable("TOrmTestUser")
		Local user:TOrmTestUser = New TOrmTestUser
		user.name = "Alice"
		user.email = "alice@example.com"
		user.age = 30
		user.isActive = True
		users.Save(user)
		Local found:TOrmTestUser = users.FindOneWhere("email = ?", Params().AddString("alice@example.com"))
		AssertNotNull(found, "FindOneWhere should return a matching user")
		AssertEquals(user.id, found.id, "FindOneWhere should return the saved user")
	End Method

	Method Test_RemoveWhere_RemovesMatchingRows() { test }

		Local orm:TOrm = TOrm.Create("SQLITE", ":memory:")
		Local users:TOrmDao<TOrmTestUser> = New TOrmDao<TOrmTestUser>.Init(orm, "TOrmTestUser")
		orm.CreateTable("TOrmTestUser")
		Local alice:TOrmTestUser = New TOrmTestUser
		alice.name = "Alice"
		alice.email = "alice@example.com"
		alice.age = 30
		users.Save(alice)
		Local bob:TOrmTestUser = New TOrmTestUser
		bob.name = "Bob"
		bob.email = "bob@example.com"
		bob.age = 17
		users.Save(bob)
		Local removed:Int = users.RemoveWhere("age < ?", Params().AddInt(18))
		AssertEquals(1, removed, "RemoveWhere should report one removed row")
		AssertEquals(1:Long, users.CountAll(), "CountAll should return one remaining row")
		AssertFalse(users.ExistsWhere("email = ?", Params().AddString("bob@example.com")), "Removed user should no longer exist")
	End Method
End Type

Type TOrmSqliteJsonTest Extends TTest

	Method Test_JsonField_RoundTripsObject() { test }
		Local orm:TOrm = TOrm.Create("SQLITE", ":memory:")
		Local users:TOrmDao<TOrmJsonUser> = New TOrmDao<TOrmJsonUser>.Init(orm, "TOrmJsonUser")

		orm.CreateTable("TOrmJsonUser")

		Local user:TOrmJsonUser = New TOrmJsonUser
		user.name = "Alice"
		user.settings = New TOrmUserSettings
		user.settings.theme = "dark"
		user.settings.notificationsEnabled = True

		users.Save(user)

		Local found:TOrmJsonUser = users.FindById(user.id)

		AssertNotNull(found, "FindById should return saved user")
		AssertNotNull(found.settings, "JSON settings should be deserialised")
		AssertEquals("dark", found.settings.theme, "JSON theme should round-trip")
		AssertTrue(found.settings.notificationsEnabled, "JSON boolean should round-trip")
	End Method

	Method Test_JsonField_UpdatePersistsChanges() { test }
		Local orm:TOrm = TOrm.Create("SQLITE", ":memory:")
		Local users:TOrmDao<TOrmJsonUser> = New TOrmDao<TOrmJsonUser>.Init(orm, "TOrmJsonUser")

		orm.CreateTable("TOrmJsonUser")

		Local user:TOrmJsonUser = New TOrmJsonUser
		user.name = "Alice"
		user.settings = New TOrmUserSettings
		user.settings.theme = "dark"
		user.settings.notificationsEnabled = True
		users.Save(user)

		user.settings.theme = "light"
		user.settings.notificationsEnabled = False
		users.Update(user)

		Local found:TOrmJsonUser = users.FindById(user.id)

		AssertNotNull(found.settings, "Updated JSON settings should be deserialised")
		AssertEquals("light", found.settings.theme, "Updated JSON theme should be persisted")
		AssertFalse(found.settings.notificationsEnabled, "Updated JSON boolean should be persisted")
	End Method

End Type

Type TOrmSqliteTransactionTest Extends TTest

	Method Test_TransactionCommit_PersistsChanges() { test }
		Local orm:TOrm = TOrm.Create("SQLITE", ":memory:")
		Local users:TOrmDao<TOrmTestUser> = New TOrmDao<TOrmTestUser>.Init(orm, "TOrmTestUser")

		orm.CreateTable("TOrmTestUser")

		Using Local tx:TOrmTransaction = orm.StartTransaction()
		Do
			Local user:TOrmTestUser = New TOrmTestUser
			user.name = "Alice"
			user.email = "alice@example.com"
			user.age = 30

			users.Save(user)

			tx.Commit()
		End Using

		AssertEquals(1:Long, users.CountAll(), "Committed transaction should persist saved row")
	End Method

	Method Test_TransactionRollback_RemovesChanges() { test }
		Local orm:TOrm = TOrm.Create("SQLITE", ":memory:")
		Local users:TOrmDao<TOrmTestUser> = New TOrmDao<TOrmTestUser>.Init(orm, "TOrmTestUser")

		orm.CreateTable("TOrmTestUser")

		Using Local tx:TOrmTransaction = orm.StartTransaction(False)
		Do
			Local user:TOrmTestUser = New TOrmTestUser
			user.name = "Alice"
			user.email = "alice@example.com"
			user.age = 30

			users.Save(user)

			tx.Rollback()
		End Using

		AssertEquals(0:Long, users.CountAll(), "Rolled back transaction should not persist saved row")
	End Method

End Type

Type TOrmSqliteSchemaValidationTest Extends TTest

	Method Test_ValidateOnStartup_PassesForCreatedTable() { test }
		Local orm:TOrm = TOrm.Create("SQLITE", ":memory:")
		'New TOrmDao<TOrmTestUser>.Init(orm, "TOrmTestUser")
		Local users:TOrmDao<TOrmTestUser> = New TOrmDao<TOrmTestUser>.Init(orm, "TOrmTestUser")


		orm.CreateTable("TOrmTestUser")

		Local report:TOrmSchemaValidationReport = orm.ValidateOnStartup()

		AssertTrue(report.IsValid(), "Validation should pass for ORM-created table")
	End Method

	Method Test_ValidateOnStartup_ReportsMissingTable() { test }
		Local orm:TOrm = TOrm.Create("SQLITE", ":memory:")
		'New TOrmDao<TOrmTestUser>.Init(orm, "TOrmTestUser")
		Local users:TOrmDao<TOrmTestUser> = New TOrmDao<TOrmTestUser>.Init(orm, "TOrmTestUser")


		Local report:TOrmSchemaValidationReport = orm.ValidateOnStartup()

		AssertFalse(report.IsValid(), "Validation should fail when table is missing")
		AssertTrue(report.ToString().Contains("orm_test_users"), "Validation report should mention missing table")
	End Method

	Method Test_FindWhere_WithInvalidOrderField_Throws() { test }
		Local orm:TOrm = TOrm.Create("SQLITE", ":memory:")
		Local users:TOrmDao<TOrmTestUser> = New TOrmDao<TOrmTestUser>.Init(orm, "TOrmTestUser")

		orm.CreateTable("TOrmTestUser")

		Try
			users.FindWhere(Null, Int(Null), TOrmOrder.By("doesNotExist"))
			Fail("FindWhere should throw for invalid order field")
		Catch ex:TOrmException
			AssertTrue(ex.ToString().Contains("doesNotExist"), "Exception should mention invalid order field")
		End Try
	End Method
End Type

Type TOrmSqliteIndexTest Extends TTest

	Method Test_CreateTable_CreatesSingleColumnIndex() { test }
		Local orm:TOrm = TOrm.Create("SQLITE", ":memory:")
		Local indexesUsers:TOrmDao<TOrmIndexedUser> = New TOrmDao<TOrmIndexedUser>.Init(orm, "TOrmIndexedUser")

		orm.CreateTable("TOrmIndexedUser")

		AssertTrue(IndexExists(orm, "orm_indexed_users", "idx_orm_indexed_users_username_orm"), "Single-column index should be created")
	End Method

	Method Test_CreateTable_CreatesCompositeIndex() { test }
		Local orm:TOrm = TOrm.Create("SQLITE", ":memory:")
		Local indexesUsers:TOrmDao<TOrmIndexedUser> = New TOrmDao<TOrmIndexedUser>.Init(orm, "TOrmIndexedUser")

		orm.CreateTable("TOrmIndexedUser")

		AssertTrue(IndexExists(orm, "orm_indexed_users", "idx_user_name"), "Composite index should be created")
	End Method

	Method Test_CreateTable_CreatesCompositeUniqueIndex() { test }
		Local orm:TOrm = TOrm.Create("SQLITE", ":memory:")
		Local indexesUsers:TOrmDao<TOrmIndexedUser> = New TOrmDao<TOrmIndexedUser>.Init(orm, "TOrmIndexedUser")

		orm.CreateTable("TOrmIndexedUser")

		AssertTrue(IndexExists(orm, "orm_indexed_users", "uq_tenant_email"), "Composite unique index should be created")
	End Method

	Method IndexExists:Int(orm:TOrm, tableName:String, indexName:String)
		Local query:TDatabaseQuery = TDatabaseQuery.Create(orm.db)

		query.Prepare("PRAGMA index_list(" + tableName + ")")
		query.Execute()

		While query.NextRow()
			If query.Value(1).GetString() = indexName Or query.Value(1).GetString().StartsWith(indexName) Then
				query.Free()
				Return True
			End If
		Wend

		query.Free()
		Return False
	End Method

End Type

Type TOrmSqliteFailureTest Extends TTest

	Method Test_BuildModel_WithDuplicatePrimaryKeys_Throws() { test }
		Local orm:TOrm = TOrm.Create("SQLITE", ":memory:")

		Try
			Local dao:TOrmDao<TOrmDuplicatePkEntity> = New TOrmDao<TOrmDuplicatePkEntity>.Init(orm, "TOrmDuplicatePkEntity")
			Fail("Model building should throw when multiple primary keys are declared")
		Catch ex:TOrmMultiplePrimaryKeysException
			AssertTrue(ex.ToString().Contains("TOrmDuplicatePkEntity"), "Exception should mention duplicate primary key entity")
		End Try
	End Method

	Method Test_Update_WithoutPrimaryKey_Throws() { test }
		Local orm:TOrm = TOrm.Create("SQLITE", ":memory:")
		Local dao:TOrmDao<TOrmNoPkEntity> = New TOrmDao<TOrmNoPkEntity>.Init(orm, "TOrmNoPkEntity")

		orm.CreateTable("TOrmNoPkEntity")

		Local entity:TOrmNoPkEntity = New TOrmNoPkEntity
		entity.name = "Alice"

		Try
			dao.Update(entity)
			Fail("Update should throw when model has no primary key")
		Catch ex:TOrmException
			AssertTrue(ex.ToString().Contains("primary key"), "Exception should mention missing primary key")
		End Try
	End Method

	Method Test_Remove_WithoutPrimaryKey_Throws() { test }
		Local orm:TOrm = TOrm.Create("SQLITE", ":memory:")
		Local dao:TOrmDao<TOrmNoPkEntity> = New TOrmDao<TOrmNoPkEntity>.Init(orm, "TOrmNoPkEntity")

		orm.CreateTable("TOrmNoPkEntity")

		Local entity:TOrmNoPkEntity = New TOrmNoPkEntity
		entity.name = "Alice"

		Try
			dao.Remove(entity)
			Fail("Remove should throw when model has no primary key")
		Catch ex:TOrmException
			AssertTrue(ex.ToString().Contains("primary key"), "Exception should mention missing primary key")
		End Try
	End Method

	Method Test_FindById_WithoutPrimaryKey_Throws() { test }
		Local orm:TOrm = TOrm.Create("SQLITE", ":memory:")
		Local dao:TOrmDao<TOrmNoPkEntity> = New TOrmDao<TOrmNoPkEntity>.Init(orm, "TOrmNoPkEntity")

		orm.CreateTable("TOrmNoPkEntity")

		Try
			dao.FindById(1)
			Fail("FindById should throw when model has no primary key")
		Catch ex:TOrmException
			AssertTrue(ex.ToString().Contains("primary key"), "Exception should mention missing primary key")
		End Try
	End Method

	Method Test_Save_WithUniqueConstraintViolation_ThrowsDatabaseException() { test }
		Local orm:TOrm = TOrm.Create("SQLITE", ":memory:")
		Local users:TOrmDao<TOrmTestUser> = New TOrmDao<TOrmTestUser>.Init(orm, "TOrmTestUser")

		orm.CreateTable("TOrmTestUser")

		Local first:TOrmTestUser = New TOrmTestUser
		first.name = "Alice"
		first.email = "same@example.com"
		first.age = 30
		users.Save(first)

		Local second:TOrmTestUser = New TOrmTestUser
		second.name = "Bob"
		second.email = "same@example.com"
		second.age = 25

		Try
			users.Save(second)
			Fail("Save should throw when unique constraint is violated")
		Catch ex:TOrmDatabaseException
			AssertTrue(ex.ToString().Contains("same@example.com") Or ex.ToString().Contains("UNIQUE") Or ex.ToString().Contains("unique"), "Database exception should mention unique constraint failure")
		End Try
	End Method

End Type

Type TOrmSqlitePrimitiveRangeTest Extends TTest

	Method Test_PrimitiveValues_RoundTrip() { test }
		Local orm:TOrm = TOrm.Create("SQLITE", ":memory:")
		Local dao:TOrmDao<TOrmPrimitiveRangeEntity> = New TOrmDao<TOrmPrimitiveRangeEntity>.Init(orm, "TOrmPrimitiveRangeEntity")

		orm.CreateTable("TOrmPrimitiveRangeEntity")

		Local entity:TOrmPrimitiveRangeEntity = New TOrmPrimitiveRangeEntity
		entity.byteValue = 255
		entity.shortValue = 65535
		entity.intValue = 2147483647
		entity.longValue = 9223372036854775807:Long
		entity.uIntValue = 4294967295:UInt
		entity.uLongValue = 18446744073709551615:ULong
		entity.floatValue = 123.5:Float
		entity.doubleValue = 123456789.125:Double
		entity.decimalValue = Decimal("12345678901234567890.12345")
		entity.stringValue = "hello"
		entity.boolValue = True

		dao.Save(entity)

		Local found:TOrmPrimitiveRangeEntity = dao.FindById(entity.id)

		AssertNotNull(found, "FindById should return primitive range entity")

		AssertEquals(entity.byteValue, found.byteValue, "Byte value should round-trip")
		AssertEquals(entity.shortValue, found.shortValue, "Short value should round-trip")
		AssertEquals(entity.intValue, found.intValue, "Int value should round-trip")
		AssertEquals(entity.longValue, found.longValue, "Long value should round-trip")
		AssertEquals(entity.uIntValue, found.uIntValue, "UInt value should round-trip")
		AssertEquals(entity.uLongValue, found.uLongValue, "ULong value should round-trip")
		AssertEquals(entity.floatValue, found.floatValue, 0.0001, "Float value should round-trip")
		AssertEquals(entity.doubleValue, found.doubleValue, 0.0001, "Double value should round-trip")
		AssertEquals(entity.decimalValue.ToString(), found.decimalValue.ToString(), "Decimal value should round-trip")
		AssertEquals(entity.stringValue, found.stringValue, "String value should round-trip")
		AssertEquals(entity.boolValue, found.boolValue, "Bool value should round-trip")
	End Method

End Type

Type TOrmSqliteOrderLimitTest Extends TTest

	Method Test_FindAll_WithOrderAscending_ReturnsRowsInOrder() { test }
		Local orm:TOrm = TOrm.Create("SQLITE", ":memory:")
		Local users:TOrmDao<TOrmTestUser> = New TOrmDao<TOrmTestUser>.Init(orm, "TOrmTestUser")

		orm.CreateTable("TOrmTestUser")
		SeedUsers(users)

		Local results:TArrayList<TOrmTestUser> = users.FindAll(TOrmOrder.By("age").Asc())

		AssertEquals(3, results.Count(), "FindAll should return all users")
		AssertEquals("Bob", results.Get(0).name, "Youngest user should be first")
		AssertEquals("Alice", results.Get(1).name, "Middle user should be second")
		AssertEquals("Charlie", results.Get(2).name, "Oldest user should be third")
	End Method

	Method Test_FindAll_WithOrderDescending_ReturnsRowsInOrder() { test }
		Local orm:TOrm = TOrm.Create("SQLITE", ":memory:")
		Local users:TOrmDao<TOrmTestUser> = New TOrmDao<TOrmTestUser>.Init(orm, "TOrmTestUser")

		orm.CreateTable("TOrmTestUser")
		SeedUsers(users)

		Local results:TArrayList<TOrmTestUser> = users.FindAll(TOrmOrder.By("age").Desc())

		AssertEquals(3, results.Count(), "FindAll should return all users")
		AssertEquals("Charlie", results.Get(0).name, "Oldest user should be first")
		AssertEquals("Alice", results.Get(1).name, "Middle user should be second")
		AssertEquals("Bob", results.Get(2).name, "Youngest user should be third")
	End Method

	Method Test_FindAll_WithLimit_ReturnsLimitedRows() { test }
		Local orm:TOrm = TOrm.Create("SQLITE", ":memory:")
		Local users:TOrmDao<TOrmTestUser> = New TOrmDao<TOrmTestUser>.Init(orm, "TOrmTestUser")

		orm.CreateTable("TOrmTestUser")
		SeedUsers(users)

		Local results:TArrayList<TOrmTestUser> = users.FindAll(TOrmOrder.By("age").Asc(), 2)

		AssertEquals(2, results.Count(), "FindAll with limit should return two users")
		AssertEquals("Bob", results.Get(0).name, "First limited user should be youngest")
		AssertEquals("Alice", results.Get(1).name, "Second limited user should be next youngest")
	End Method

	Method Test_FindAll_WithLimitAndOffset_ReturnsExpectedPage() { test }
		Local orm:TOrm = TOrm.Create("SQLITE", ":memory:")
		Local users:TOrmDao<TOrmTestUser> = New TOrmDao<TOrmTestUser>.Init(orm, "TOrmTestUser")

		orm.CreateTable("TOrmTestUser")
		SeedUsers(users)

		Local results:TArrayList<TOrmTestUser> = users.FindAll(TOrmOrder.By("age").Asc(), 1, 1)

		AssertEquals(1, results.Count(), "FindAll with limit and offset should return one user")
		AssertEquals("Alice", results.Get(0).name, "Offset should skip the youngest user")
	End Method

	Method Test_FindWhere_WithOrderLimitAndOffset_ReturnsExpectedRows() { test }
		Local orm:TOrm = TOrm.Create("SQLITE", ":memory:")
		Local users:TOrmDao<TOrmTestUser> = New TOrmDao<TOrmTestUser>.Init(orm, "TOrmTestUser")

		orm.CreateTable("TOrmTestUser")
		SeedUsers(users)

		Local results:TArrayList<TOrmTestUser> = users.FindWhere("age >= ?", Params().AddInt(20), TOrmOrder.By("name").Asc(), 2, 1)

		AssertEquals(2, results.Count(), "FindWhere should apply where, order, limit, and offset")
		AssertEquals("Bob", results.Get(0).name, "Offset should skip Alice when ordered by name")
		AssertEquals("Charlie", results.Get(1).name, "Second result should be Charlie")
	End Method

	Method SeedUsers(users:TOrmDao<TOrmTestUser>)
		SaveUser(users, "Charlie", "charlie@example.com", 40)
		SaveUser(users, "Alice", "alice@example.com", 30)
		SaveUser(users, "Bob", "bob@example.com", 20)
	End Method

	Method SaveUser(users:TOrmDao<TOrmTestUser>, name:String, email:String, age:Int)
		Local user:TOrmTestUser = New TOrmTestUser
		user.name = name
		user.email = email
		user.age = age
		user.isActive = True
		users.Save(user)
	End Method

End Type

Type TOrmSqliteCustomJConvSerializerTest Extends TTest

	Method Test_CustomJConvSerializer_RoundTripsJsonField() { test }
		Local jconv:TJConv = New TJConvBuilder ..
			.WithCompact() ..
			.RegisterSerializer("TOrmBox", New TOrmBoxSerializer) ..
			.Build()

		Local orm:TOrm = TOrm.Create("SQLITE", ":memory:")
		orm.SetJConv(jconv)

		Local dao:TOrmDao<TOrmBoxEntity> = New TOrmDao<TOrmBoxEntity>.Init(orm, "TOrmBoxEntity")

		orm.CreateTable("TOrmBoxEntity")

		Local entity:TOrmBoxEntity = New TOrmBoxEntity
		entity.name = "box test"
		entity.box = New TOrmBox(1, 2, 30, 40)

		dao.Save(entity)

		Local found:TOrmBoxEntity = dao.FindById(entity.id)

		AssertNotNull(found, "FindById should return entity")
		AssertNotNull(found.box, "Custom serialized box should be deserialized")
		AssertEquals(1, found.box.x, "Box x should round-trip")
		AssertEquals(2, found.box.y, "Box y should round-trip")
		AssertEquals(30, found.box.w, "Box w should round-trip")
		AssertEquals(40, found.box.h, "Box h should round-trip")
	End Method

End Type

Type TOrmSqliteEnumTest Extends TTest

	Method Test_NumericEnum_RoundTrips() { test }
		Local orm:TOrm = TOrm.Create("SQLITE", ":memory:")
		Local dao:TOrmDao<TOrmEnumEntity> = New TOrmDao<TOrmEnumEntity>.Init(orm, "TOrmEnumEntity")

		orm.CreateTable("TOrmEnumEntity")

		Local entity:TOrmEnumEntity = New TOrmEnumEntity
		entity.name = "Alice"
		entity.status = EOrmTestStatus.Active

		dao.Save(entity)

		Local found:TOrmEnumEntity = dao.FindById(entity.id)

		AssertNotNull(found, "FindById should return enum entity")
		AssertEquals(EOrmTestStatus.Active.Ordinal(), found.status.Ordinal(), "Numeric enum should round-trip")
	End Method

	Method Test_StringEnum_RoundTrips() { test }
		Local orm:TOrm = TOrm.Create("SQLITE", ":memory:")
		Local dao:TOrmDao<TOrmEnumEntity> = New TOrmDao<TOrmEnumEntity>.Init(orm, "TOrmEnumEntity")

		orm.CreateTable("TOrmEnumEntity")

		Local entity:TOrmEnumEntity = New TOrmEnumEntity
		entity.name = "Bob"
		entity.stringStatus = EOrmTestStatus.Disabled

		dao.Save(entity)

		Local found:TOrmEnumEntity = dao.FindById(entity.id)

		AssertNotNull(found, "FindById should return enum entity")
		AssertEquals(EOrmTestStatus.Disabled.Ordinal(), found.stringStatus.Ordinal(), "String enum should round-trip")
	End Method

	Method Test_NumericFlagsEnum_RoundTrips() { test }
		Local orm:TOrm = TOrm.Create("SQLITE", ":memory:")
		Local dao:TOrmDao<TOrmEnumEntity> = New TOrmDao<TOrmEnumEntity>.Init(orm, "TOrmEnumEntity")

		orm.CreateTable("TOrmEnumEntity")

		Local entity:TOrmEnumEntity = New TOrmEnumEntity
		entity.name = "Charlie"
		entity.permissions = EOrmTestPermissions.Read | EOrmTestPermissions.Write

		dao.Save(entity)

		Local found:TOrmEnumEntity = dao.FindById(entity.id)

		AssertNotNull(found, "FindById should return enum entity")
		AssertEquals(entity.permissions.Ordinal(), found.permissions.Ordinal(), "Numeric flags enum should round-trip")
	End Method

	Method Test_StringFlagsEnum_RoundTrips() { test }
		Local orm:TOrm = TOrm.Create("SQLITE", "maxtest.db")
		Local dao:TOrmDao<TOrmEnumEntity> = New TOrmDao<TOrmEnumEntity>.Init(orm, "TOrmEnumEntity")

		orm.CreateTable("TOrmEnumEntity")

		Local entity:TOrmEnumEntity = New TOrmEnumEntity
		entity.name = "Dana"
		entity.stringPermissions = EOrmTestPermissions.Read | EOrmTestPermissions.Execute

		dao.Save(entity)

		Local found:TOrmEnumEntity = dao.FindById(entity.id)

		AssertNotNull(found, "FindById should return enum entity")
		AssertEquals(entity.stringPermissions.Ordinal(), found.stringPermissions.Ordinal(), "String flags enum should round-trip")
	End Method

End Type

Type TOrmTestUser { table = "orm_test_users" }

	Field id:Long { pk auto }
	Field name:String
	Field email:String { unique }
	Field age:Int
	Field isActive:Int { bool }

End Type

Type TOrmUserSettings

	Field theme:String
	Field notificationsEnabled:Int

End Type

Type TOrmJsonUser { table = "orm_json_users" }

	Field id:Long { pk auto }
	Field name:String
	Field settings:TOrmUserSettings { json nullable }

End Type

Type TOrmIndexedUser { table = "orm_indexed_users" }

	Field id:Long { pk auto }

	Field username:String { index }

	Field firstName:String { index = "idx_user_name" }
	Field lastName:String { index = "idx_user_name" }

	Field tenantId:Long { unique = "uq_tenant_email" }
	Field email:String { unique = "uq_tenant_email" }

End Type

Type TOrmDuplicatePkEntity { table = "orm_duplicate_pk_entity" }

	Field id:Long { pk auto }
	Field otherId:Long { pk }
	Field name:String

End Type

Type TOrmNoPkEntity { table = "orm_no_pk_entity" }

	Field name:String

End Type

Type TOrmPrimitiveRangeEntity { table = "orm_primitive_range_entity" }

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

Type TOrmBoxEntity { table = "orm_box_entity" }

	Field id:Long { pk auto }
	Field name:String
	Field box:TOrmBox { json nullable }

End Type

Type TOrmBox

	Field x:Int
	Field y:Int
	Field w:Int
	Field h:Int

	Method New()
	End Method

	Method New(x:Int, y:Int, w:Int, h:Int)
		Self.x = x
		Self.y = y
		Self.w = w
		Self.h = h
	End Method

End Type


Type TOrmBoxSerializer Extends TJConvSerializer

	Method Serialize:TJSON(source:Object, sourceType:String)
		Local box:TOrmBox = TOrmBox(source)

		If Not box Then
			Return New TJSONNull.Create()
		End If

		Return New TJSONString.Create(box.x + "," + box.y + "," + box.w + "," + box.h)
	End Method

	Method Deserialize:Object(json:TJSON, typeId:TTypeId, obj:Object)

		If TJSONString(json) Then
			If Not obj Then
				obj = New TOrmBox
			End If

			Local box:TOrmBox = TOrmBox(obj)
			Local parts:String[] = TJSONString(json).Value().Split(",")

			box.x = parts[0].ToInt()
			box.y = parts[1].ToInt()
			box.w = parts[2].ToInt()
			box.h = parts[3].ToInt()

			Return box
		End If

		Return obj

	End Method

End Type

Enum EOrmTestStatus
	Init
	Active
	Disabled
End Enum

Enum EOrmTestPermissions Flags
	None = 0
	Read = 1
	Write = 2
	Execute = 4
End Enum

Type TOrmEnumEntity { table = "orm_enum_entity" }

	Field id:Long { pk auto }
	Field name:String

	Field status:EOrmTestStatus
	Field stringStatus:EOrmTestStatus { enum_string }

	Field permissions:EOrmTestPermissions
	Field stringPermissions:EOrmTestPermissions { enum_string }

End Type
