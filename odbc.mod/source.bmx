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

Import "iodbc/include/*.h"
Import "iodbc/iodbcinst/*.h"
Import "iodbc/iodbcadm/*.h"
Import "iodbc/iodbc/*.h"
Import "iodbc/iodbc/trace/*.h"
Import "include/*.h"

Import "iodbc/iodbcinst/SQLGetConfigMode.c"
Import "iodbc/iodbcinst/SQLGetPrivateProfileString.c"
Import "iodbc/iodbcinst/SQLSetConfigMode.c"
Import "iodbc/iodbcinst/SQLValidDSN.c"
Import "iodbc/iodbcinst/SQLWritePrivateProfileString.c"
Import "iodbc/iodbcinst/SQLReadFileDSN.c"
Import "iodbc/iodbcinst/SQLWriteFileDSN.c"
Import "iodbc/iodbcinst/dlf.c"
Import "iodbc/iodbcinst/inifile.c"
Import "iodbc/iodbcinst/iodbc_error.c"
Import "iodbc/iodbcinst/misc.c"
Import "iodbc/iodbcinst/unicode.c"

Import "iodbc/iodbcinst/SQLConfigDataSource.c"
Import "iodbc/iodbcinst/SQLConfigDriver.c"
Import "iodbc/iodbcinst/SQLGetAvailableDrivers.c"
Import "iodbc/iodbcinst/SQLGetInstalledDrivers.c"
Import "iodbc/iodbcinst/SQLInstallDriver.c"
Import "iodbc/iodbcinst/SQLRemoveDSNFromIni.c"
Import "iodbc/iodbcinst/SQLRemoveDriver.c"
Import "iodbc/iodbcinst/SQLWriteDSNToIni.c"
Import "iodbc/iodbcinst/SQLInstallDriverEx.c"
Import "iodbc/iodbcinst/SQLInstallODBC.c"
Import "iodbc/iodbcinst/SQLInstallTranslator.c"
Import "iodbc/iodbcinst/SQLCreateDataSource.c"
Import "iodbc/iodbcinst/SQLManageDataSource.c"
Import "iodbc/iodbcinst/SQLRemoveTranslator.c"
Import "iodbc/iodbcinst/SQLRemoveDefaultDataSource.c"
Import "iodbc/iodbcinst/SQLInstallDriverManager.c"
Import "iodbc/iodbcinst/SQLRemoveDriverManager.c"
Import "iodbc/iodbcinst/SQLInstallTranslatorEx.c"
Import "iodbc/iodbcinst/SQLInstallerError.c"
Import "iodbc/iodbcinst/SQLPostInstallerError.c"
Import "iodbc/iodbcinst/SQLGetTranslator.c"
Import "iodbc/iodbcinst/Info.c"

Import "iodbc/iodbc/trace/AllocConnect.c"
Import "iodbc/iodbc/trace/AllocEnv.c"
Import "iodbc/iodbc/trace/AllocHandle.c"
Import "iodbc/iodbc/trace/AllocStmt.c"
Import "iodbc/iodbc/trace/BindCol.c"
Import "iodbc/iodbc/trace/BindParameter.c"
Import "iodbc/iodbc/trace/BrowseConnect.c"
Import "iodbc/iodbc/trace/BulkOperations.c"
Import "iodbc/iodbc/trace/Cancel.c"
Import "iodbc/iodbc/trace/CloseCursor.c"
Import "iodbc/iodbc/trace/ColAttribute.c"
Import "iodbc/iodbc/trace/ColumnPrivileges.c"
Import "iodbc/iodbc/trace/Columns.c"
Import "iodbc/iodbc/trace/Connect.c"
Import "iodbc/iodbc/trace/CopyDesc.c"
Import "iodbc/iodbc/trace/DataSources.c"
Import "iodbc/iodbc/trace/DescribeCol.c"
Import "iodbc/iodbc/trace/DescribeParam.c"
Import "iodbc/iodbc/trace/Disconnect.c"
Import "iodbc/iodbc/trace/DriverConnect.c"
Import "iodbc/iodbc/trace/Drivers.c"
Import "iodbc/iodbc/trace/EndTran.c"
Import "iodbc/iodbc/trace/Error.c"
Import "iodbc/iodbc/trace/ExecDirect.c"
Import "iodbc/iodbc/trace/Execute.c"
Import "iodbc/iodbc/trace/ExtendedFetch.c"
Import "iodbc/iodbc/trace/Fetch.c"
Import "iodbc/iodbc/trace/FetchScroll.c"
Import "iodbc/iodbc/trace/ForeignKeys.c"
Import "iodbc/iodbc/trace/FreeConnect.c"
Import "iodbc/iodbc/trace/FreeEnv.c"
Import "iodbc/iodbc/trace/FreeHandle.c"
Import "iodbc/iodbc/trace/FreeStmt.c"
Import "iodbc/iodbc/trace/GetConnectAttr.c"
Import "iodbc/iodbc/trace/GetConnectOption.c"
Import "iodbc/iodbc/trace/GetCursorName.c"
Import "iodbc/iodbc/trace/GetData.c"
Import "iodbc/iodbc/trace/GetDescField.c"
Import "iodbc/iodbc/trace/GetDescRec.c"
Import "iodbc/iodbc/trace/GetDiagField.c"
Import "iodbc/iodbc/trace/GetDiagRec.c"
Import "iodbc/iodbc/trace/GetEnvAttr.c"
Import "iodbc/iodbc/trace/GetFunctions.c"
Import "iodbc/iodbc/trace/GetStmtAttr.c"
Import "iodbc/iodbc/trace/GetStmtOption.c"
Import "iodbc/iodbc/trace/GetTypeInfo.c"
Import "iodbc/iodbc/trace/Info.c" ' note : name change! (because of object name clashing)
Import "iodbc/iodbc/trace/MoreResults.c"
Import "iodbc/iodbc/trace/NativeSql.c"
Import "iodbc/iodbc/trace/NumParams.c"
Import "iodbc/iodbc/trace/NumResultCols.c"
Import "iodbc/iodbc/trace/ParamData.c"
Import "iodbc/iodbc/trace/ParamOptions.c"
Import "iodbc/iodbc/trace/Prepare.c"
Import "iodbc/iodbc/trace/PrimaryKeys.c"
Import "iodbc/iodbc/trace/ProcedureColumns.c"
Import "iodbc/iodbc/trace/Procedures.c"
Import "iodbc/iodbc/trace/PutData.c"
Import "iodbc/iodbc/trace/RowCount.c"
Import "iodbc/iodbc/trace/SetConnectAttr.c"
Import "iodbc/iodbc/trace/SetConnectOption.c"
Import "iodbc/iodbc/trace/SetCursorName.c"
Import "iodbc/iodbc/trace/SetDescField.c"
Import "iodbc/iodbc/trace/SetDescRec.c"
Import "iodbc/iodbc/trace/SetEnvAttr.c"
Import "iodbc/iodbc/trace/SetPos.c"
Import "iodbc/iodbc/trace/SetScrollOptions.c"
Import "iodbc/iodbc/trace/SetStmtAttr.c"
Import "iodbc/iodbc/trace/SetStmtOption.c"
Import "iodbc/iodbc/trace/SpecialColumns.c"
Import "iodbc/iodbc/trace/Statistics.c"
Import "iodbc/iodbc/trace/TablePrivileges.c"
Import "iodbc/iodbc/trace/Tables.c"
Import "iodbc/iodbc/trace/Transact.c"
Import "iodbc/iodbc/trace/trace.c"

Import "iodbc/iodbc/bmx_misc.c" ' note : name change! (because of object name clashing)
Import "iodbc/iodbc/catalog.c"
Import "iodbc/iodbc/connect.c"
Import "iodbc/iodbc/dlproc.c"
Import "iodbc/iodbc/execute.c"
Import "iodbc/iodbc/fetch.c"
Import "iodbc/iodbc/hdbc.c"
Import "iodbc/iodbc/henv.c"
Import "iodbc/iodbc/herr.c"
Import "iodbc/iodbc/hstmt.c"
Import "iodbc/iodbc/info.c"
Import "iodbc/iodbc/prepare.c"
Import "iodbc/iodbc/result.c"
Import "iodbc/iodbc/odbc3.c"

Import "odbchelper.c"
