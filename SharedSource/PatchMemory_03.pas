unit PatchMemory;


Interface
uses Windows, ImageHlp, SysUtils;

var  BasePointer: pointer;
type TPatchMemory = Class
  Debug: Boolean; //Отладочная печать
  DllNameToPatch: String; //Имя DLL, в секции импорта которой будем производить изменения
  DllNameToFind: String; //Имя DLL, функцию которой мы хотим перехватить (например, 'KERNEL32.dll')
  FuncNameToFind: String; //Функция, которую мы хотим перехватить (например, 'CreateProcessA')
  NewFunctionAddr: Pointer; //Адрес функции - заменителя
  OldFunctionAddr: Pointer; //Старый адрес замещенной функции
  function Patch():Boolean;  //Выполняет замену стандартной функции на нашу
  procedure UnPatch;  //Отменяет патчинг

        Constructor Create;
        Destructor Destroy; Override;

private

  AddrWherePatching: Pointer; //Для UnPatch
  function GetDwordByRVA(rva: dword):dword;
  function GetStringByRVA(rva: dword):pchar;
  function GetPointerByRVA(rva: DWORD):Pointer;
  function GetRVAByPointer(P: Pointer):DWORD;
  procedure WriteDwordToMemory(Kuda: Pointer; Data: DWORD);
  function GetDwordFromMemory(addr: Pointer):DWORD;
//  function GetPointerFromAddr(addr: DWORD):Pointer;
  procedure say(s:String);

end;


//////////////////////////////////////////////////////////
implementation

//////////////////////////////////////////////////////////
procedure TPatchMemory.say(s:String);
//Отладочная печать
begin
  if Debug then
  MessageBox(0,pchar(s),'',0);
end;


//////////////////////////////////////////////////////////////
Constructor TPatchMemory.Create;
begin
     inherited Create;
     debug:=False;
end;

//////////////////////////////////////////////////////////////
destructor TPatchMemory.Destroy;
begin
     say('Destroy');
     inherited Destroy;

end;



//////////////////////////////////////////////////
function TPatchMemory.GetDwordByRVA(rva: dword):dword;
//Получает значение (4 байтовое целое без знака - DWORD) из памяти по
//смещению (RVA)
begin
   asm
     push ebx;

     mov ebx, [rva];
     add ebx, [BasePointer];

     mov eax, [ebx];
     mov Result, eax;

     pop ebx;
   end;
end;

//////////////////////////////////////////////////
function TPatchMemory.GetStringByRVA(rva: dword):pchar;
//Получает строку по указателю RVA
begin
   asm
     mov eax, [rva];
     add eax, [BasePointer];
     mov Result, eax;
   end;
end;

//////////////////////////////////////////////////
function TPatchMemory.GetPointerByRVA(rva: DWORD):Pointer;
//Получает указатель из RVA (т.е. прибавляет к rva значение BasePointer)
begin
   asm
     mov eax, rva;
     add eax, [BasePointer];
     mov Result, eax;
   end;
end;

//////////////////////////////////////////////////
function TPatchMemory.GetDwordFromMemory(addr: Pointer):DWORD;
begin
   asm
     push ebx;

     mov ebx, [addr];
     mov eax, [ebx];
     mov Result, eax;

     pop ebx;
   end;
end;


//////////////////////////////////////////////////
function TPatchMemory.GetRVAByPointer(P: Pointer):DWORD;
//Получает указатель RVA из указателя
//(т.е. вычитает из указателя значение BasePointer)
begin
  asm
    mov eax, [p];
    sub eax, BasePointer;
    mov Result, eax;
  end;
end;

//////////////////////////////////////////////////
Procedure TPatchMemory.WriteDwordToMemory( //Пишем 4 байта в память по указателю.
  Kuda: Pointer; //Адрес куда пишем
  Data: DWORD //Значение которое пишем
);

var  BytesWritten: DWORD;
var  hProcess: THandle;
var old: DWORD;
begin

  hProcess := Windows.GetCurrentProcess();


    //Разрешаем доступ на запись по указанному адресу

    Windows.VirtualProtect(//Функция WinAPI
      kuda, //адрес
      4, //число байт (будут затронуты 1 или 2 страницы памяти размером 4К)
      PAGE_EXECUTE_READWRITE, //атрибуты доступа
      @old); //сюда будут возвращены старые атрибуты

    BytesWritten:=0;

    //Записываем 4 байта
    Windows.WriteProcessMemory(//Функция WinAPI
      hProcess,
      kuda,
      @data,
      4,
      BytesWritten);

 //Восстанавливаем прежние атрибуты доступа
    Windows.VirtualProtect(//Функция WinAPI
      kuda,
      4,
      old,
      @old);

end;



//////////////////////////////////////////////////////////
function TPatchMemory.Patch():boolean;
var ulSize: ULONG;
var rva: DWORD;
var ImportTableOffset: pointer;
var OffsetDllName: DWORD;
var OffsetFuncAddrs: DWORD;
var FunctionAddr: DWORD;
var DllName: String;
//var FuncAddrToFind: DWORD;

var OffsetFuncNames: DWORD;
var pFuncName: pchar;
var dFuncName: DWORD;
var nFuncName: Integer;
var nFuncAddr: Integer;
var ok: Integer;
begin

   Result:=False;

//В Windows 2000 DLL в этот момент, возможно, еще не загружена
   if DWORD(GetModuleHandle(pchar(DllNameToPatch)))=0 then begin
      LoadLibrary(pchar(DllNameToPatch));
   end;

//Получаем адрес функции, который мы хотим найти в таблице IAT
  say(DllNameToFind+' '+FuncNameToFind);
(*
  FuncAddrToFind:= DWORD(
    GetProcAddress(//Функция Windows API
      GetModuleHandle(//Функция Windows API
        pchar(DllNameToFind)
      ),
      pchar(FuncNameToFind)
    ));
*)
//  say('FuncAddrToFind: '+IntToHex(FuncAddrToFind,8));
//  OldFunctionAddr:=Pointer(FuncAddrToFind);

//Получаем адрес, по которому расположена в памяти dll - "жертва".
  BasePointer:=pointer(GetModuleHandle(//Функция Windows API
  pChar(DllNameToPatch)));

//Получаем смещение таблицы импорта
  ImportTableOffset:= ImageDirectoryEntryToData( //Функция Windows API
  BasePointer, TRUE, IMAGE_DIRECTORY_ENTRY_IMPORT, ulSize);

//Переводим смещение таблицы импорта в формат RVA
//(смещение относительно начала DLL)
  rva:=GetRvaByPointer(ImportTableOffset);

  repeat    {Проходим по таблице импорта.
     Каждая запись в таблице импорта имеет длину 20 байт:
     +0 - указатель на таблицу имен функций
     +4 - ?
     +8 - ?
     +12 - Указатель (RVA) на имя DLL
     +16 - указатель на таблицу адресов функций
     }

         OffsetDllName := GetDwordByRVA(rva+12);
         if OffsetDllName = 0 then break; //Если таблица кончилась, выходим

          DllName := GetStringByRVA(OffsetDllName);//Имя DLL
            if LowerCase(Trim(DllName))=LowerCase(Trim(DllNameToFind)) then begin

               OffsetFuncNames:=GetDwordByRVA(rva+0); //Таблица имен функций
               //if LowerCase(DllNameToPatch)='dbeng32.dll' then
               //MessageBox(0, pchar(IntToHex(OffsetFuncNames,8)), pchar(DllNameToFind+' '+DllNameToPatch+' '+FuncNameToFind), 0);

                 nFuncName:=0;
                 ok:=0;
                 repeat //Цикл по списку имен функций DLL
                     dFuncName:=GetDwordByRva(OffsetFuncNames);
                     if dFuncName=0 then break;

                     inc(nFuncName);

                     pFuncName:=GetStringByRva(dFuncName);
                     inc(pFuncName,2);

                     //if debug then
                     //MessageBox(0, pchar(IntToHex(GetDwordByRva(OffsetFuncNames),8)), pchar(DllNameToFind+' '+DllNameToPatch+' '+FuncNameToFind), 0);
                     //MessageBox(0, pFuncName, pchar(DllNameToFind+' '+DllNameToPatch+' '+FuncNameToFind), 0);

                     if LowerCase(Trim(''+pFuncName))=LowerCase(Trim(FuncNameToFind)) then begin
                       ok:=1;
                       break; //нашли
                     end;

                     inc(OffsetFuncNames,4);
                 until False;


               if ok=1 then begin
                 OffsetFuncAddrs:=GetDwordByRva(rva+16);
                 nFuncAddr:=0;
                 repeat //Цикл по списку функций DLL
                   FunctionAddr:=Dword(GetDwordByRva(OffsetFuncAddrs));
                   if FunctionAddr=0 then break; //Если функции закончились, выходим
                   inc(nFuncAddr);

                   //if (FunctionAddr=FuncAddrToFind) then begin
                   if nFuncAddr=nFuncName then begin
                    //Нашли - выполняем патч
                     AddrWherePatching:=GetPointerByRva(OffsetFuncAddrs);
                      say('AddrWherePatching: '+IntToHex(Dword(AddrWherePatching),8));





                      OldFunctionAddr:=Pointer(GetDwordFromMemory(AddrWherePatching));
                      Result:=True;

//                      MessageBox(0, pchar(IntToHex(Dword(OldFunctionAddr), 8)),
//                        pchar(DllNameToPatch+' '+FuncNameToFind+' sleep_dbf'), 0);
                      //OldFunctionAddr:=OldFunctionAddr1;

                     WriteDwordToMemory(
                      AddrWherePatching,
                      DWORD(NewFunctionAddr));

                      say('AddrWherePatching: '+IntToHex(Dword(AddrWherePatching),8));
                   end;


                   inc(OffsetFuncAddrs,4);
                 until false;
               end;

             end;
          rva:=rva+20;
  until false;

end;


//////////////////////////////////////////////////////////
procedure TPatchMemory.UnPatch;
begin
   say('AddrWherePatching: '+IntToHex(Dword(AddrWherePatching),8));
   say('OldFunctionAddr: '+IntToHex(Dword(OldFunctionAddr),8));
   WriteDwordToMemory(
     AddrWherePatching,
     DWORD(OldFunctionAddr));
end;


end.
