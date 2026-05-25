SuperStrict

Framework BRL.standardio
Import Database.OrmSQLite

Local orm:TOrm = TOrm.Create("SQLITE", "maxtest.db")

Local users:TOrmDao<TUser> = New TOrmDao<TUser>.Init(orm, "TUser")

Local report:TOrmSchemaValidationReport = orm.ValidateOnStartup()
If Not report.IsValid() Then
	Print report.ToString()
End If

orm.CreateTable("TUser")

If users.CountAll() = 0 Then
	
	Using
		Local tx:TOrmTransaction = orm.StartTransaction()
	Do
		users.Save(NewUser("Alice", "alice@example.com", 30, True, "dark", True))
		users.Save(NewUser("Bob", "bob@example.com", 25, False, "light", False))
		users.Save(NewUser("Charlie", "charlie@example.com", 28, True))

		tx.Commit()
	End Using

End If

Local list:TArrayList<TUser> = users.FindAll(TOrmOrder.By("age"))

For Local u:TUser = EachIn list
	Local p:String = "User: " + u.name + ", Email: " + u.email + ", Age: " + u.age + ", Active: " + u.isActive
	If u.settings Then
		p :+ ", Theme: " + u.settings.theme + ", Notifications Enabled: " + u.settings.notificationsEnabled
	End If

	Print p
Next

' Find users older than 26
list = users.FindWhere("age > ?", 26)
Print "Users older than 26:"
For Local u:TUser = EachIn list
	Print " - " + u.name + " (" + u.age + " years old)"
Next

' active users
list = users.FindWhere("is_active = ?", Params().AddBool(True))
Print "Active users:"
For Local u:TUser = EachIn list
	Print " - " + u.name
Next


Type TUser { table = "users" }
	Field id:Long { pk auto }
	Field name:String { index="idx_name_age" }
	Field email:String { unique }
	Field age:Int { index="idx_name_age" }
	Field isActive:Int { bool index }
	Field settings:TUserSettings { json nullable }
End Type

Type TUserSettings
	Field theme:String
	Field notificationsEnabled:Int
End Type

Function NewUser:TUser(name:String, email:String, age:Int, isActive:Int, theme:String = "", notificationsEnabled:Int = 0)
	Local user:TUser = New TUser()
	user.name = name
	user.email = email
	user.age = age
	user.isActive = isActive
	If theme Then
		user.settings = New TUserSettings()
		user.settings.theme = theme
		user.settings.notificationsEnabled = notificationsEnabled
	End If
	Return user
End Function
