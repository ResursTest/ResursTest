000100171102**free
000101171113       ctl-opt
000102181010               DFTACTGRP(*NO) ACTGRP('KORRP0008')
000103171113               OPTION(*SRCSTMT : *NODEBUGIO)
000104171113               DECEDIT ('0,')
000105171116               datfmt(*ISO)
000106171124               pgminfo(*pcml:*module:*dclcase)
000107171113               expropts(*resdecpos);
000108180619
000109180619  ctl-opt bnddir('KSRRM0000');
000110180619
000111171102//----------------------------------------------------------------
000112171102//
000113181010//  Program: KORRP0008                  Patrik S. 20181010
000114171102//
000115181015//  Spärrar alla hittade kort mot konto
000116171102//
000117171102//----------------------------------------------------------------
000118171102//  Ändringar:
000119171102//  ---------------
000120181010//  181010 PSC Skapat
000121181115//  181010 PSC Ändrat
000122181115//             Provat Git, vet ej vad jag gör
000123171102//
000124180517
000135180619/include QCPYSRC,KSRRC0000
000136180521
000137180119// datastruktur för att hantera responskod vid fel.
000138180119/if defined(sqlCodeDS)
000139180119/else
000140180119  dcl-ds sqlCodeDS;
000141180119    wk_sql char(3) inz('SQL');
000142180119    wk_sqlCode zoned(4:0);
000143180119  END-DS;
000144180119/define sqlCodeDS
000145180119/endif
000146180516
000147180516//---------------------------------------------------------------------//
000148180516// Prototyper                                                          //
000149180516//---------------------------------------------------------------------//
000158180516
000159181010Dcl-pr Declare_Kort_cursor_;
000160180516End-Pr;
000161180516
000162181010Dcl-pr Fetch_Kort_Cursor_;
000163180516End-Pr;
000164180516
000165181010Dcl-pr Close_Kort_Cursor_;
000166180516End-Pr;
000176180516
000177180620Dcl-pr Las_FITBLT_;
000178180620End-Pr;
000179180620
000211181010  DCL-PI KORRP0008;
000212181011    in_fordrojDagar      Char(10)  const;
000219171116  END-PI;
000220171102
000221171113
000222171102//----------------------------------------------------------------
000223171102// Variabler
000224180118dcl-s wk_ok               ind;
000225180516dcl-s wk_next             ind inz(*on);
000227180124dcl-s wk_fromTimestamp    timestamp;
000232180516dcl-s wk_FelKod           char(3);
000236180518dcl-s wk_FelTxt           char(30);
000237181010dcl-s wk_KTKRTN           char(19);
000238181010dcl-s wk_KRKNTN           char(16);
000246180516dcl-s wk_DATUM            char(8);
000247180620dcl-s wk_FORDR_DAG        int(10);
000248180620dcl-s wk_FORDR_SPR        char(1);
000249180620dcl-s wk_FICSRF           char(1024);
000250180521
000253180521
000259180517dcl-s wk_date             zoned(8:0);
000260180517dcl-s wk_todaysDate       date;
000261180517dcl-s wk_dateYesterday    date;
000263180615
000264180620dcl-s FL_Avsluta          ind inz(*off);
000270171102//----------------------------------------------------------------
000271171102// Konstanter
000272180119dcl-c c_CREATE            const('*CREATE');
000273180119dcl-c c_DELETE            const('*DELETE');
000274180119dcl-c c_EXECUTE           const('*EXECUTE');
000275180119
000276180119dcl-c c_ok                const('');
000277180119dcl-c c_error             const('*ERROR');
000278180508dcl-c c_obehandlad        const('0');
000279180508dcl-c c_behandlad         const('2');
000280180517
000287180521
000288180517 DCL-DS wk_date_ds;
000289180517        wk_date_all     zoned(8:0);
000290180517        wk_date_year    zoned(4:0) OVERLAY(wk_date_all:1);
000291180517        wk_date_month   zoned(2:0) OVERLAY(wk_date_all:*next);
000292180517        wk_date_day     zoned(2:0) OVERLAY(wk_date_all:*next);
000293180517 end-ds ;
000294180517
000305180119//-----------------------------------------------------------------
000306180119// Mainline
000307180516
000308180516
000309180516 Exec SQL Set Option CloSQLCsr = *EndMod,
000310180516                     Commit    = *None,
000311180516                     DlyPrp    = *Yes,
000312180516                     DynUsrPrf = *Owner,
000313180516                     Naming    = *Sys,
000314180516                     UsrPrf    = *Owner,
000315180516                     DatFmt    = *ISO;
000316180516
000317180119  wk_ok = *on;
000318180119
000319180119//-----------------------------------------------------------------
000320180119
000321180124// sätt från och med timestamp till
000322180124wk_fromTimestamp = %timestamp() - %months(1);
000323180517
000324180517wk_Date = %dec(%date( ));
000325180517wk_date_all = wk_date;
000326180517wk_todaysDate = %date();
000327180517wk_dateYesterday = wk_todaysDate - %days(1);
000358180620
000359180620// läser parametervärde
000360180620Las_FITBLT_();
000361181011
000363181011// skall spärra direkt
000364181011wk_FORDR_DAG = %int(in_fordrojDagar);
000365181011if wk_FORDR_DAG > 0;
000366181011  wk_FORDR_SPR ='1';
000367181011else;
000368181011  wk_FORDR_SPR ='0';
000370181011endif;
000371181011
000372181011
000373180620// Avsluta direkt
000374180620if FL_Avsluta;
000375180620  wk_felkod = '1';
000376180620Endif;
000377180615
000378180516select;
000379180516
000380180516// inget fel
000381180516when wk_felkod = ' ';
000382180516
000383181010  Declare_Kort_Cursor_();
000384180516
000385180516  Dow wk_next;
000386180516
000387181011    // Hämtar nästa Kort som skall spärras
000388181010    Fetch_Kort_Cursor_();
000389180516
000390180516    Select;
000391180516      when wk_next;
000392181010        Handle_Kort_();
000393180516
000394180516      other;
000395180516          wk_next = *off;
000396180516    Endsl;
000397180516  Enddo;
000398180516
000399181010  Close_Kort_cursor_();
000400180516
000401180516//Fel
000402180516other;
000403180518
000404180516Endsl;
000405180516
000406180516*inlr = *on;
000407180516return;
000408180516
000409180516// -----------------------------------
000410180516// Hanterar hittade poster
000411180516// -----------------------------------
000412181010Dcl-Proc Handle_Kort_;
000413181010
000414181010      // spärrar kort
000415181010    if sparraKort(wk_KRKNTN :wk_FORDR_SPR  :wk_FORDR_DAG);
000416181010    Endif;
000509180516
000510181010END-PROC Handle_Kort_;
000511180516
000512180516// -----------------------------------
000513181010// Deklarerar Cursor, hämtar de Kort poster som skall hanteras
000514180516// -----------------------------------
000515181010Dcl-Proc Declare_Kort_Cursor_;
000516180615
000519180615      EXEC SQL
000520181010           Declare Hamta_Kort Cursor For
000521181010                 Select a.ktkrtn, b.KRKNTN
000522181010                        From  fikort a
000523181010                        Join  fiktot b
000525181010                        on    a.krkntn = b.krkntn
000527181010                   where a.KRSID  = '0 '
000528181010                   and (b.KSSID = '10' or b.KSSID = '11')
000529181010                   order by a.KRKNTN, a.ktkrtn;
000542180615
000543180615      EXEC SQL
000544181010           Open Hamta_Kort;
000545180615
000576181010End-Proc Declare_Kort_cursor_;
000577180516
000578180516// -----------------------------------
000579181010// Hämtar nästa kort post,
000580180516// -----------------------------------
000581181010Dcl-Proc Fetch_Kort_Cursor_;
000582180516
000585180618
000586180618      EXEC SQL
000587181010           Fetch Hamta_Kort
000588181010           Into  :wk_KTKRTN , :wk_KRKNTN;
000589180516
000590180618      If SQLCODE <> 0;
000591180618        wk_next = *off;
000592180618      Endif;
000593180618
000622180618
000623181010End-Proc Fetch_Kort_Cursor_;
000624180516
000625180516// -----------------------------------
000626180516// Stänger cursor  Inkasso
000627180516// -----------------------------------
000628181010Dcl-Proc Close_Kort_Cursor_;
000629180516
000630180516  EXEC SQL
000631181010       Close Hamta_Kort;
000632181010
000639181010End-Proc Close_Kort_Cursor_;
000640180516
001105180619//------------------------------------------------------------------------------
001106180619// Spärrar Kort på KOnto
001107180619//------------------------------------------------------------------------------
001108180619dcl-proc sparraKort;
001109180619  Dcl-Pi *N ind;
001110180619    in_kontonummer   char(16);
001111180620    in_fordrojdSparr Char(1);
001112180620    in_fordrojDagar  int(10);
001113180619  End-Pi;
001114180619
001115180619  dcl-s Kontonr       char(19);
001116180620  dcl-s fordrojdSparr Char(1);
001117180620  dcl-s fordrojDagar  int(10);
001118180619
001119180620    Kontonr       = %trim(in_kontonummer);
001120180620    fordrojdSparr = in_fordrojdSparr;
001121180620    fordrojDagar  = in_fordrojDagar;
001122180620
001123180620    KSR00_sparraAllaAktivaKortPaEttKonto( Kontonr : fordrojdSparr : fordrojDagar );
001124180619
001125180619  if in_kontonummer  = *Blank;
001126180619    Return *On;
001127180619  Else;
001128180619    Return *Off;
001129180619  ENDIF;
001130180619
001131180619END-PROC;
001132180620
001133180620// -----------------------------------
001134180620// Läser parametrar i FITBLT
001135180620// -----------------------------------
001136180620Dcl-Proc Las_FITBLT_;
001137180620
001138180620  dcl-s w_FICSPF           char(10);
001139180620  dcl-s FORDR_DAG          char(10);
001140180620  dcl-s FORDR_SPR          char(10);
001141180620
001142180620  w_FICSPF  = '10INKASSO';
001143180620  FORDR_DAG = 'FORDR_DAG';
001144180620  FORDR_SPR = 'FORDR_SPR';
001145180620
001146180620  // hämtar antal fördröjningsdagar för att spärra kort
001147180620  EXEC SQL
001148180620       select   FICSRF
001149180620         into  : wk_FICSRF
001150180620         from  FITBLT
001151180620         where FICSPF = : w_FICSPF
001152180620         and   FICSQF = : FORDR_DAG;
001153180620
001154180620  if sqlcode = 0;
001155180620    wk_FORDR_DAG = %int(wk_FICSRF);
001156180620  else;
001157180620     FL_Avsluta = *on;
001158180620  Endif;
001159180620
001160180620  // hämtar fördröjningspärr för att spärra kort
001161180620  EXEC SQL
001162180620       select   FICSRF
001163180620         into  : wk_FICSRF
001164180620         from  FITBLT
001165180620         where FICSPF = : w_FICSPF
001166180620         and   FICSQF = : FORDR_SPR;
001167180620
001168180620  if sqlcode = 0;
001169180620    wk_FORDR_SPR = %trim(wk_FICSRF);
001170180620  else;
001171180620     FL_Avsluta = *on;
001172180620  Endif;
001176180620
001177180620End-Proc Las_FITBLT_;
