SuperStrict

Framework brl.standardio
Import BRL.MaxUnit
Import Database.Orm

New TTestSuite.run()

Type TOrmNamingStyleTest Extends TTest

	Method TestDefaultNamingStyleIsLowerCaseUnderscore() { test }
		Local builder:TOrmModelBuilder = New TOrmModelBuilder(Null)

		AssertEquals("user_profile_id", builder.ApplyNamingStyle("UserProfileID"))
		AssertEquals("xml_parser", builder.ApplyNamingStyle("XMLParser"))
		AssertEquals("http_request", builder.ApplyNamingStyle("HTTPRequest"))
	End Method

	Method TestLowerCaseNamingStyle() { test }
		Local builder:TOrmModelBuilder = New TOrmModelBuilder(Null, EOrmNamingStyle.LowerCase)

		AssertEquals("userprofileid", builder.ApplyNamingStyle("UserProfileID"))
		AssertEquals("xmlparser", builder.ApplyNamingStyle("XMLParser"))
		AssertEquals("httprequest", builder.ApplyNamingStyle("HTTPRequest"))
	End Method

	Method TestUpperCaseNamingStyle() { test }
		Local builder:TOrmModelBuilder = New TOrmModelBuilder(Null, EOrmNamingStyle.UpperCase)

		AssertEquals("USERPROFILEID", builder.ApplyNamingStyle("UserProfileID"))
		AssertEquals("XMLPARSER", builder.ApplyNamingStyle("XMLParser"))
		AssertEquals("HTTPREQUEST", builder.ApplyNamingStyle("HTTPRequest"))
	End Method

	Method TestCamelCaseNamingStyle() { test }
		Local builder:TOrmModelBuilder = New TOrmModelBuilder(Null, EOrmNamingStyle.CamelCase)

		AssertEquals("userProfileId", builder.ApplyNamingStyle("UserProfileID"))
		AssertEquals("xmlParser", builder.ApplyNamingStyle("XMLParser"))
		AssertEquals("httpRequest", builder.ApplyNamingStyle("HTTPRequest"))
	End Method

	Method TestPascalCaseNamingStyle() { test }
		Local builder:TOrmModelBuilder = New TOrmModelBuilder(Null, EOrmNamingStyle.PascalCase)

		AssertEquals("UserProfileId", builder.ApplyNamingStyle("UserProfileID"))
		AssertEquals("XmlParser", builder.ApplyNamingStyle("XMLParser"))
		AssertEquals("HttpRequest", builder.ApplyNamingStyle("HTTPRequest"))
	End Method

	Method TestLowerCaseUnderscoreNamingStyle() { test }
		Local builder:TOrmModelBuilder = New TOrmModelBuilder(Null, EOrmNamingStyle.LowerCaseUnderscore)

		AssertEquals("user_profile_id", builder.ApplyNamingStyle("UserProfileID"))
		AssertEquals("xml_parser", builder.ApplyNamingStyle("XMLParser"))
		AssertEquals("http_request", builder.ApplyNamingStyle("HTTPRequest"))
	End Method

	Method TestUpperCaseUnderscoreNamingStyle() { test }
		Local builder:TOrmModelBuilder = New TOrmModelBuilder(Null, EOrmNamingStyle.UpperCaseUnderscore)

		AssertEquals("USER_PROFILE_ID", builder.ApplyNamingStyle("UserProfileID"))
		AssertEquals("XML_PARSER", builder.ApplyNamingStyle("XMLParser"))
		AssertEquals("HTTP_REQUEST", builder.ApplyNamingStyle("HTTPRequest"))
	End Method

End Type

Type TOrmIdentifierSplitTest Extends TTest

	Method TestSplitsPascalCase() { test }
		AssertWords(["user", "profile"], TOrmNameBuilder.SplitIdentifierWords("UserProfile"))
	End Method

	Method TestSplitsCamelCase() { test }
		AssertWords(["user", "profile"], TOrmNameBuilder.SplitIdentifierWords("userProfile"))
	End Method

	Method TestSplitsUnderscore() { test }
		AssertWords(["user", "profile"], TOrmNameBuilder.SplitIdentifierWords("user_profile"))
	End Method

	Method TestSplitsUpperCaseUnderscore() { test }
		AssertWords(["user", "profile"], TOrmNameBuilder.SplitIdentifierWords("USER_PROFILE"))
	End Method

	Method TestNormalisesID() { test }
		AssertWords(["user", "profile", "id"], TOrmNameBuilder.SplitIdentifierWords("UserProfileID"))
	End Method

	Method TestNormalisesAcronyms() { test }
		AssertWords(["xml", "parser"], TOrmNameBuilder.SplitIdentifierWords("XMLParser"))
		AssertWords(["http", "request"], TOrmNameBuilder.SplitIdentifierWords("HTTPRequest"))
	End Method

	Method TestSplitsNumbers() { test }
		AssertWords(["user", "2", "profile"], TOrmNameBuilder.SplitIdentifierWords("user2Profile"))
	End Method

	Method AssertWords(expected:String[], actual:String[])
		AssertEquals(expected.Length, actual.Length, "Word count should match")

		For Local i:Int = 0 Until expected.Length
			AssertEquals(expected[i], actual[i], "Word at index " + i + " should match")
		Next
	End Method

End Type
