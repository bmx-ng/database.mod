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
' DISCLAIMED. IN NO EVENT SHALL <copyright holder> BE LIABLE FOR ANY
' DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
' (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
' LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
' ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
' (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
' SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
'
SuperStrict

Extern
	Function isspace:Int(char:Int)
	Function isdigit:Int(char:Int)
End Extern

Function dbStrptime:Int(date:String, format:String, y:Int Var, m:Int Var, d:Int Var, hh:Int Var, mm:Int Var, ss:Int Var, micros:Int Var)

	Local b:Int = 0
	Local c:Int = 0
	Local p:Int = 0

	While p < format.length
	
		c = p
		p:+1
	
		If format[c] <> 37 Then ' "%"
		
			If isspace(format[c]) Then
				While b < date.length And isspace(date[b])
					b:+1
				Wend
			Else
				If format[c] <> date[b] Then
					Return False
				End If

				b:+ 1

			End If
			
			Continue
			
		End If
	
		c = p
		p:+ 1
		
		If c >= format.length Then
			Return 0
		End If
	
		Select format[c]
			Case 37 ' "%"
				If b >= date.length Or date[b] <> 37 Then
					Return False
				End If
				b:+ 1
				Continue
			Case 77, 83  ' "M", "S"
				If b < date.length And Not isspace(date[b]) Then
				
					If Not isdigit(date[b]) Then
						Return False
					End If
					
					Local i:Int = 0
					While b < date.length And isdigit(date[b])
						i:* 10 
						i:+ date[b] - 48 ' "0"
						b:+ 1
					Wend
					
					If i > 59 Then
						Return False
					End If
					
					If format[c] = 77 Then ' "M"
						mm = i
					Else
						ss = i
					End If
					
				Else
					Continue
				End If
			Case 72   ' "H"

				If Not isdigit(date[b]) Then
					Return False
				End If

				Local i:Int = 0
				While b < date.length And isdigit(date[b])
					i:* 10 
					i:+ date[b] - 48 ' "0"
					b:+ 1
				Wend

				If i > 23 Then
					Return False
				End If
				
				hh = i

			Case 100  ' "d"

				If Not isdigit(date[b]) Then
					Return False
				End If

				Local i:Int = 0
				While b < date.length And isdigit(date[b])
					i:* 10 
					i:+ date[b] - 48 ' "0"
					b:+ 1
				Wend
				
				If i > 31 Then
					Return False
				End If
				
				d = i

			Case 109  ' "m"
			
				If Not isdigit(date[b]) Then
					Return False
				End If
				
				Local i:Int = 0
				While b < date.length And isdigit(date[b])
					i:* 10 
					i:+ date[b] - 48 ' "0"
					b:+ 1
				Wend
				
				If i < 1 Or i > 12 Then
					Return False
				End If
				
				m = i
				
			Case 89   ' "Y"
				If b < date.length And Not isspace(date[b]) Then
				
					If Not isdigit(date[b]) Then
						Return False
					End If
				
					Local i:Int = 0
					While b < date.length And isdigit(date[b])
						i:* 10 
						i:+ date[b] - 48 ' "0"
						b:+ 1
					Wend
					
					y = i
					
				End If

			Case 102 ' "f"

				If Not isdigit(date[b]) Then
					Return False
				End If

				Local i:Int = 0
				Local digits:Int = 0

				While b < date.length And isdigit(date[b]) And digits < 6
					i:* 10
					i:+ date[b] - 48
					b:+ 1
					digits:+ 1
				Wend

				' Reject more than 6 fractional digits.
				If b < date.length And isdigit(date[b]) Then
					Return False
				End If

				' Right-pad to microseconds.
				While digits < 6
					i:* 10
					digits:+ 1
				Wend

				micros = i
		End Select

		If b < date.length And isspace(date[b]) Then
			While p < format.length And Not isspace(format[p])
				p:+ 1
			Wend
		End If
	
	Wend

	While b < date.length And isspace(date[b])
		b:+ 1
	Wend

	If b < date.length Then
		Return False
	End If

	Return True
	
End Function

Function dbIsLeapYear:Int(y:Int)

	If y Mod 400 = 0 Then Return True
	If y Mod 100 = 0 Then Return False
	Return y Mod 4 = 0

End Function

Function dbDaysInMonth:Int(y:Int, m:Int)

	Select m
		Case 1, 3, 5, 7, 8, 10, 12
			Return 31
		Case 4, 6, 9, 11
			Return 30
		Case 2
			If dbIsLeapYear(y) Then Return 29
			Return 28
	End Select
	Return 0

End Function

Function dbIsValidDate:Int(y:Int, m:Int, d:Int)

	If y < 1 Then Return False
	If m < 1 Or m > 12 Then Return False
	Local maxDay:Int = dbDaysInMonth(y, m)
	If d < 1 Or d > maxDay Then Return False
	Return True

End Function

Function dbIsValidTime:Int(hh:Int, mm:Int, ss:Int, micros:Int = 0)

	If hh < 0 Or hh > 23 Then Return False
	If mm < 0 Or mm > 59 Then Return False
	If ss < 0 Or ss > 59 Then Return False
	If micros < 0 Or micros > 999999 Then Return False
	Return True

End Function
