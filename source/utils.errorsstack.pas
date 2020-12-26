(******************************************************************************)
(*                                PascalUtils                                 *)
(*          delphi and object pascal library of utils data structures         *)
(*                                                                            *)
(* Copyright (c) 2020                                       Ivan Semenkov     *)
(* https://github.com/isemenkov/pascalutils                 ivan@semenkov.pro *)
(*                                                          Ukraine           *)
(******************************************************************************)
(*                                                                            *)
(* This source  is free software;  you can redistribute  it and/or modify  it *)
(* under the terms of the GNU General Public License as published by the Free *)
(* Software Foundation; either version 3 of the License.                      *)
(*                                                                            *)
(* This code is distributed in the  hope that it will  be useful, but WITHOUT *)
(* ANY  WARRANTY;  without even  the implied  warranty of MERCHANTABILITY  or *)
(* FITNESS FOR A PARTICULAR PURPOSE.  See the  GNU General Public License for *)
(* more details.                                                              *)
(*                                                                            *)
(* A copy  of the  GNU General Public License is available  on the World Wide *)
(* Web at <http://www.gnu.org/copyleft/gpl.html>. You  can also obtain  it by *)
(* writing to the Free Software Foundation, Inc., 51  Franklin Street - Fifth *)
(* Floor, Boston, MA 02110-1335, USA.                                         *)
(*                                                                            *)
(******************************************************************************)

unit utils.errorsstack;

{$IFDEF FPC}
  {$mode objfpc}{$H+}
{$ENDIF}
{$IFOPT D+}
  {$DEFINE DEBUG}
{$ENDIF}

interface

uses
  SysUtils {$IFDEF USE_OPTIONAL}, utils.optional{$ENDIF};

type
  {$IFNDEF USE_OPTIONAL}
  { ErrorStack is empty }
  EErrorNotExists = class(Exception);
  {$ENDIF}

  { TArrayErrorsStack is generic stack over array of T which contains errors 
    codes. }
  {$IFDEF FPC}generic{$ENDIF} TArrayErrorsStack<T> = class
  public
    type
      {$IFDEF USE_OPTIONAL}
      TOptionalError = {$IFDEF FPC}specialize{$ENDIF} TOptional<T>;
      {$ENDIF}

      PErrorsDynArray = ^TErrorsDynArray;
      TErrorsDynArray = array of T;

      { TArrayErrorsStack enumerator } 
      TErrorsEnumerator = class
      protected
        { Return enumerator for in operator }
        function GetEnumerator : TErrorsEnumerator;

        { Get error }
        function GetCurrent : {$IFNDEF USE_OPTIONAL}T{$ELSE}TOptionalError
          {$ENDIF};
      public
        constructor Create (Arr : PErrorsDynArray; Len : Cardinal);

        { Return True if can move to next item }
        function MoveNext : Boolean;

        { Return current item and move pointer to next item. }
        property Current : {$IFNDEF USE_OPTIONAL}T{$ELSE}TOptionalError{$ENDIF}
          read GetCurrent;
      protected
        FErrors : PErrorsDynArray;
        FLength : LongInt;
        FPosition : LongInt;
      end;
  public
    constructor Create;
    destructor Destroy; override;

    { Push error to stack }
    procedure Push (AError : T);

    { Return top error and remove it from stack. Raise EErrorNotExists exception
      if stack is empty. }
    function Pop : {$IFNDEF USE_OPTIONAL}T{$ELSE}TOptionalError{$ENDIF};

    { Stack count elements }
    function Count : LongInt;

    { Return enumerator for in operator. }
    function GetEnumerator : TErrorsEnumerator;
  protected
    { Reallocate the array to the new size }
    function Enlarge : Boolean;
  protected
    FData : array of T;
    FLength : LongInt;
    FAlloced : LongInt;
  end;

  { TListErrorsStack is generic stack over list of T which contains errors 
    codes. }
  {$IFDEF FPC}generic{$ENDIF} TListErrorsStack<T> = class
  protected
    type
      { Item enty type }
      PListEntry = ^TListEntry;
      TListEntry = record
        Value : T;
        Next : PListEntry;
      end;
  public
    type
      {$IFDEF USE_OPTIONAL}
      TOptionalError = {$IFDEF FPC}specialize{$ENDIF} TOptional<T>;
      {$ENDIF}

      { TListErrorsStack enumerator }  
      TErrorsEnumerator = class
      protected
        { Return enumerator for in operator }
        function GetEnumerator : TErrorsEnumerator;

        { Get error }
        function GetCurrent : {$IFNDEF USE_OPTIONAL}T{$ELSE}TOptionalError
          {$ENDIF};
      public
        constructor Create (FirstEntry : PListEntry);

        { Return True if can move to next item }
        function MoveNext : Boolean;

        { Return current item and move pointer to next item. }
        property Current : {$IFNDEF USE_OPTIONAL}T{$ELSE}TOptionalError{$ENDIF}
          read GetCurrent;
      protected
        FNode : PListEntry;
      end;
  public
    constructor Create;
    destructor Destroy; override;

    { Push error to stack }
    procedure Push (AError : T);

    { Return top error and remove it from stack. Raise EErrorNotExists exception
      if stack is empty. }
    function Pop : {$IFNDEF USE_OPTIONAL}T{$ELSE}TOptionalError{$ENDIF};

    { Stack count elements }
    function Count : LongInt;

    { Return enumerator for in operator. }
    function GetEnumerator : TErrorsEnumerator;
  protected
    FFirstNode : PListEntry;
    FLength : LongInt;
  end;

implementation

{ TArrayErrorsStack.TErrorsEnumerator }

constructor TArrayErrorsStack{$IFNDEF FPC}<T>{$ENDIF}.TErrorsEnumerator.Create 
  (Arr : PErrorsDynArray; Len : Cardinal);
begin
  FErrors := Arr;
  FLength := Len;
  FPosition := 0;
end;

function TArrayErrorsStack{$IFNDEF FPC}<T>{$ENDIF}
  .TErrorsEnumerator.GetEnumerator : TErrorsEnumerator;
begin
  Result := Self;
end;

function TArrayErrorsStack{$IFNDEF FPC}<T>{$ENDIF}
  .TErrorsEnumerator.GetCurrent : 
  {$IFNDEF USE_OPTIONAL}T{$ELSE}TOptionalError{$ENDIF};
begin
  if FPosition > FLength then
  begin
    {$IFNDEF USE_OPTIONAL}
    raise EErrorNotExists.Create('Errors not exists.');
    {$ELSE}
    Exit(TOptionalError.Create);
    {$ENDIF}
  end;

  Result := FErrors^[FPosition];
  Inc(FPosition);
end;

function TArrayErrorsStack{$IFNDEF FPC}<T>{$ENDIF}.TErrorsEnumerator.MoveNext : 
  Boolean;
begin
  Result := FPosition < FLength;
end;

{ TArrayErrorsStack }

constructor TArrayErrorsStack{$IFNDEF FPC}<T>{$ENDIF}.Create;
begin
  SetLength(FData, 16);
  FAlloced := 16;
  FLength := 0;
end;

destructor TArrayErrorsStack{$IFNDEF FPC}<T>{$ENDIF}.Destroy;
begin
  SetLength(FData, 0);
  inherited Destroy;
end;

function TArrayErrorsStack{$IFNDEF FPC}<T>{$ENDIF}.Enlarge : Boolean;
var
  NewSize : Cardinal;
begin
  { Double the allocated size }
  NewSize := FAlloced * 2;

  { Reallocate the array to the new size }
  SetLength(FData, NewSize);
  FAlloced := NewSize;
  
  Result := True;  
end;

procedure TArrayErrorsStack{$IFNDEF FPC}<T>{$ENDIF}.Push (AError : T);
begin
  if FLength + 1 > FAlloced then
  begin
    if not Enlarge then
    begin
      Exit;
    end;
  end;

  FData[FLength] := AError;
  Inc(FLength);
end;

function TArrayErrorsStack{$IFNDEF FPC}<T>{$ENDIF}.Pop : 
  {$IFNDEF USE_OPTIONAL}T{$ELSE}TOptionalError{$ENDIF};
begin
  if FLength = 0 then
  begin
    {$IFNDEF USE_OPTIONAL}
    raise EErrorNotExists.Create('Errors not exists.');
    {$ELSE}
    Exit(TOptionalError.Create);
    {$ENDIF}
  end;

  Result := FData[FLength];
  Dec(FLength);
end;

function TArrayErrorsStack{$IFNDEF FPC}<T>{$ENDIF}.Count : LongInt;
begin
  Result := FLength;
end;

function TArrayErrorsStack{$IFNDEF FPC}<T>{$ENDIF}.GetEnumerator : 
  TErrorsEnumerator;
begin
  Result := TErrorsEnumerator.Create(@FData, FLength);
end;

{ TListErrorsStack.TErrorsEnumerator }

constructor TListErrorsStack{$IFNDEF FPC}<T>{$ENDIF}.TErrorsEnumerator.Create 
  (FirstEntry : PListEntry);
begin
  FNode := FirstEntry;
end;

function TListErrorsStack{$IFNDEF FPC}<T>{$ENDIF}
  .TErrorsEnumerator.GetEnumerator : TErrorsEnumerator;
begin
  Result := Self;
end;

function TListErrorsStack{$IFNDEF FPC}<T>{$ENDIF}.TErrorsEnumerator.GetCurrent : 
  {$IFNDEF USE_OPTIONAL}T{$ELSE}TOptionalError{$ENDIF};
begin
  if FNode = nil then
  begin
    {$IFNDEF USE_OPTIONAL}
    raise EErrorNotExists.Create('Errors not exists.');
    {$ELSE}
    Exit(TOptionalError.Create);
    {$ENDIF}
  end;

  Result := FNode^.Value;
  FNode := FNode^.Next;
end;

function TListErrorsStack{$IFNDEF FPC}<T>{$ENDIF}.TErrorsEnumerator.MoveNext : 
  Boolean;
begin
  Result := FNode <> nil;
end;

{ TListErrorsStack }

constructor TListErrorsStack{$IFNDEF FPC}<T>{$ENDIF}.Create;
begin
  FFirstNode := nil;
  FLength := 0;
end;

destructor TListErrorsStack{$IFNDEF FPC}<T>{$ENDIF}.Destroy;
var
  NextNode : PListEntry;
begin
  while FFirstNode <> nil do
  begin
    NextNode := FFirstNode^.Next;
    Dispose(FFirstNode);
    FFirstNode := NextNode;
  end;
end;

procedure TListErrorsStack{$IFNDEF FPC}<T>{$ENDIF}.Push (AError : T);
var
  NewNode : PListEntry;
begin
  New(NewNode);
  NewNode^.Value := AError;
  NewNode^.Next := FFirstNode;
  FFirstNode := NewNode;
  Inc(FLength);  
end;

function TListErrorsStack{$IFNDEF FPC}<T>{$ENDIF}.Pop : 
  {$IFNDEF USE_OPTIONAL}T{$ELSE}TOptionalError{$ENDIF};
var
  CurrNode : PListEntry;
begin
  if FFirstNode = nil then
  begin
    {$IFNDEF USE_OPTIONAL}
    raise EErrorNotExists.Create('Errors not exists.');
    {$ELSE}
    Exit(TOptionalError.Create);
    {$ENDIF}
  end;

  Result := FFirstNode^.Value;
  CurrNode := FFirstNode;
  FFirstNode := FFirstNode^.Next;
  Dispose(CurrNode);
  Dec(FLength);
end;

function TListErrorsStack{$IFNDEF FPC}<T>{$ENDIF}.Count : LongInt;
begin
  Result := FLength;
end;

function TListErrorsStack{$IFNDEF FPC}<T>{$ENDIF}.GetEnumerator : 
  TErrorsEnumerator;
begin
  Result := TErrorsEnumerator.Create(FFirstNode);
end;

end.
