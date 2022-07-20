/*
  Copyright (c) 2007-2022 Bruce A Henderson
  All rights reserved.
 
  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:
      * Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.
      * Redistributions in binary form must reproduce the above copyright
        notice, this list of conditions and the following disclaimer in the
        documentation and/or other materials provided with the distribution.
      * Neither the auther nor the names of its contributors may be used to 
        endorse or promote products derived from this software without specific
        prior written permission.
 
  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY
  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
#include <brl.mod/blitz.mod/blitz.h>

#ifdef _WIN32
#include <winsock.h>
#else
//#include <ma_global.h>
#endif
#include <mysql.h>
#include <stdio.h>

BBString * bmx_mysql_field_name(MYSQL_FIELD * field) {
	return bbStringFromUTF8String(field->name);
}

char * bmx_mysql_field_org_name(MYSQL_FIELD * field) {
	return field->org_name;
}

char * bmx_mysql_field_table(MYSQL_FIELD * field) {
	return field->table;
}

char * bmx_mysql_field_org_table(MYSQL_FIELD * field) {
	return field->org_table;
}

char * bmx_mysql_field_db(MYSQL_FIELD * field) {
	return field->db;
}

char * bmx_mysql_field_catalog(MYSQL_FIELD * field) {
	return field->catalog;
}

char * bmx_mysql_field_def(MYSQL_FIELD * field) {
	return field->def;
}

unsigned long bmx_mysql_field_length(MYSQL_FIELD * field) {
	return field->length;
}

unsigned long bmx_mysql_field_max_length(MYSQL_FIELD * field) {
	return field->max_length;
}

int bmx_mysql_field_flags(MYSQL_FIELD * field) {
	return field->flags;
}

int bmx_mysql_field_type(MYSQL_FIELD * field) {
	return field->type;
}

int bmx_mysql_field_decimals(MYSQL_FIELD * field) {
	return field->decimals;
}


MYSQL_BIND * bmx_mysql_makeBindings(int size) {
	MYSQL_BIND * bindings = malloc(sizeof(MYSQL_BIND) * size);
	// important that we clear the memory... otherwise it nukes when we try to "fetch"!!
	memset(bindings, 0, size * sizeof(MYSQL_BIND));
	return bindings;
}

// tidy up our memory
void bmx_mysql_deleteBindings(MYSQL_BIND * bindings) {
	free(bindings);
}

MYSQL_TIME * bmx_mysql_makeTime() {
	MYSQL_TIME * time = (MYSQL_TIME *)malloc(sizeof(MYSQL_TIME));
	memset(time, 0, sizeof(MYSQL_TIME));
	return time;
}

void bmx_mysql_deleteTime(MYSQL_TIME * time) {
	free(time);
}

void bmx_mysql_deleteBools(my_bool * bools) {
	free(bools);
}

void bmx_mysql_setBool(my_bool * bools, int index, int isNull) {
	bools[index] = isNull;
}

char ** bmx_mysql_makeVals(int size) {
	return malloc(sizeof(char*) * size);
}

void bmx_mysql_deleteVals(char ** vals) {
	free(vals);
}

void bmx_mysql_bind_null(MYSQL_BIND* bindings, int index) {
	MYSQL_BIND* bind = &bindings[index];
	bind->buffer_type = MYSQL_TYPE_NULL;
}

void bmx_mysql_bind_int(MYSQL_BIND* bindings, int index, int * value, my_bool * isNull) {

	MYSQL_BIND* bind = &bindings[index];
	bind->is_null = (my_bool*)isNull;
	bind->length = 0;
	
	bind->buffer_type = MYSQL_TYPE_LONG;
	if (!isNull) {
		bind->buffer = value;
		bind->buffer_length = sizeof(int);
		bind->is_unsigned = 0;
	}
}

void bmx_mysql_bind_float(MYSQL_BIND* bindings, int index, float * value, my_bool * isNull) {

	MYSQL_BIND* bind = &bindings[index];
	bind->is_null = (my_bool*)isNull;
	bind->length = 0;

	bind->buffer_type = MYSQL_TYPE_FLOAT;
	if (!isNull) {
		bind->buffer = value;
		bind->buffer_length = sizeof(float);
		bind->is_unsigned = 0;
	}
}

void bmx_mysql_bind_double(MYSQL_BIND* bindings, int index, double * value, my_bool * isNull) {

	MYSQL_BIND* bind = &bindings[index];
	bind->is_null = (my_bool*)isNull;
	bind->length = 0;

	bind->buffer_type = MYSQL_TYPE_DOUBLE;
	if (!isNull) {
		bind->buffer = value;
		bind->buffer_length = sizeof(double);
		bind->is_unsigned = 0;
	}
}

void bmx_mysql_bind_long(MYSQL_BIND* bindings, int index, long * value, my_bool * isNull) {

	MYSQL_BIND* bind = &bindings[index];
	bind->is_null = (my_bool*)isNull;
	bind->length = 0;

	bind->buffer_type = MYSQL_TYPE_LONGLONG;
	if (!isNull) {
		bind->buffer = value;
		bind->buffer_length = 8;
		bind->is_unsigned = 0;
	}
}

void bmx_mysql_bind_string(MYSQL_BIND* bindings, int index, char * value, int size, my_bool * isNull) {

	MYSQL_BIND* bind = &bindings[index];
	bind->is_null = (my_bool*)isNull;
	bind->length = 0;
	bind->buffer_type = MYSQL_TYPE_STRING;

	if (!isNull) {
		bind->buffer = value;
		bind->buffer_length = size;

		bind->is_unsigned = 0;
	}
}

void bmx_mysql_bind_blob(MYSQL_BIND* bindings, int index, char * value, int size, my_bool * isNull) {

	MYSQL_BIND* bind = &bindings[index];
	bind->is_null = (my_bool*)isNull;
	bind->length = 0;

	bind->buffer_type = MYSQL_TYPE_BLOB;

	if (!isNull) {
		bind->buffer = value;
		bind->buffer_length = size;

		bind->is_unsigned = 0;
	}
}

void bmx_mysql_bind_date(MYSQL_BIND* bindings, int index, MYSQL_TIME * date, unsigned int year, unsigned int month, unsigned int day, my_bool * isNull) {

	date->year = year;
	date->month = month;
	date->day = day;

	MYSQL_BIND* bind = &bindings[index];
	bind->is_null = (my_bool*)isNull;
	bind->length = 0;

	bind->buffer_type = MYSQL_TYPE_DATE;

	if (!isNull) {
		bind->buffer = (char *)date;
		bind->buffer_length = sizeof(MYSQL_TIME);
	}
}

void bmx_mysql_bind_time(MYSQL_BIND* bindings, int index, MYSQL_TIME * time, unsigned int hour, unsigned int minute, unsigned int second, my_bool * isNull) {

	time->hour = hour;
	time->minute = minute;
	time->second = second;

	MYSQL_BIND* bind = &bindings[index];
	bind->is_null = (my_bool*)isNull;
	bind->length = 0;

	bind->buffer_type = MYSQL_TYPE_TIME;
	if (!isNull) {
		bind->buffer = (char *)time;
		bind->buffer_length = sizeof(MYSQL_TIME);
	}
}

void bmx_mysql_bind_datetime(MYSQL_BIND* bindings, int index, MYSQL_TIME  * datetime,
		unsigned int year, unsigned int month, unsigned int day, unsigned int hour, unsigned int minute, unsigned int second, my_bool * isNull) {

	datetime->year = year;
	datetime->month = month;
	datetime->day = day;
	datetime->hour = hour;
	datetime->minute = minute;
	datetime->second = second;

	MYSQL_BIND* bind = &bindings[index];
	bind->is_null = (my_bool*)isNull;
	bind->length = 0;

	bind->buffer_type = MYSQL_TYPE_DATETIME;

	if (!isNull) {
		bind->buffer = (char *)datetime;
		bind->buffer_length = sizeof(MYSQL_TIME);
	}
}

void examine_bindings(MYSQL_BIND* bindings, int size, MYSQL_STMT *stmt) {
	for (int i = 0; i < size; i++) {
		MYSQL_BIND* bind = &bindings[i];
		printf("Number = %d\n", i);fflush(stdout);
		printf("type = %d\n", bind->buffer_type);fflush(stdout);
		printf("lgth = %d\n", bind->buffer_length);fflush(stdout);
		if (MYSQL_TYPE_STRING == bind->buffer_type) {
			printf("data = %s\n", bind->buffer);fflush(stdout);
		}
	}
}

int bmx_mysql_rowField_isNull(MYSQL_ROW row, int index) {
	return ((row[index] == NULL) || (!row[index])) ? 1 : 0;
}

unsigned long bmx_mysql_getLength(unsigned long * lengths, int index) {
	return lengths[index];
}

char * bmx_mysql_rowField_chars(MYSQL_ROW row, int index) {
	return row[index];
}

void bmx_mysql_inbind(MYSQL_BIND* bindings, int index, MYSQL_FIELD * field, char * dataValue, long unsigned * dataLength, my_bool * isNull, int type) {

	MYSQL_BIND* bind = &bindings[index];
	bind->buffer_type = type;
	bind->buffer_length = field->length + 1;
	bind->is_null = isNull;
	bind->length = dataLength;

	bind->buffer = dataValue;
}

MYSQL_BIND * bmx_mysql_getBindings(MYSQL_STMT *stmt) {
	return stmt->bind;
}

MYSQL_BIND * bmx_mysql_getParams(MYSQL_STMT *stmt) {
	return stmt->params;
}

int bmx_mysql_stmt_fetch(MYSQL_STMT *stmt) {
	int result = mysql_stmt_fetch(stmt);
	return result;
}

void bmx_mysql_stmt_insert_id(MYSQL_STMT *stmt, BBInt64 * id) {
	*id = mysql_stmt_insert_id(stmt);
}

void bmx_mysql_insert_id(MYSQL * mysql, BBInt64 * id) {
	*id = mysql_insert_id(mysql);
}

int bmx_mysql_stmt_close(MYSQL_STMT *stmt) {
	return mysql_stmt_close(stmt);
}

void bmx_mysql_affected_rows(MYSQL *mysql, BBInt64 * rows) {
	*rows = mysql_affected_rows(mysql);
}

int bmx_mysql_stmt_reset(MYSQL_STMT *stmt) {
	return mysql_stmt_reset(stmt);
}

int bmx_mysql_stmt_bind_param(MYSQL_STMT *stmt, MYSQL_BIND * bind) {
	return mysql_stmt_bind_param(stmt, bind);
}

void bmx_mysql_stmt_affected_rows(MYSQL_STMT *stmt, BBInt64 * rows) {
	*rows = mysql_stmt_affected_rows(stmt);
}

int bmx_mysql_stmt_bind_result(MYSQL_STMT *stmt, MYSQL_BIND * bind) {
	return mysql_stmt_bind_result(stmt, bind);
}

int bmx_mysql_char_to_int(char * data) {
	return *(int*)data;
}

BBInt64 bmx_mysql_char_to_long(char * data) {
	return *(BBInt64*)data;
}

float bmx_mysql_char_to_float(char * data) {
	return *(float*)data;
}

double bmx_mysql_char_to_double(char * data) {
	return *(double*)data;
}
