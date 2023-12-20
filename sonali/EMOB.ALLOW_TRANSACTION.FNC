CREATE OR REPLACE FUNCTION EMOB.ALLOW_TRANSACTION (pAppId     VARCHAR2,
                                                   pPageId    VARCHAR2)
   RETURN BOOLEAN
IS
----Changed---Miaze12/18/2023002000asdaasfdffeshita22ne111miaziiiiiii54564555------
   vCurrentHr          VARCHAR2 (2);
   vAllowTransaction   VARCHAR2 (1);
   vCurrentMinute      VARCHAR2 (2);
   vCurrentAm          VARCHAR2 (2);
   vTranStatHr         VARCHAR2 (2);
   vTranStatMin        VARCHAR2 (2);
   vTranStatAM         VARCHAR2 (2);
   vTranEndHr          VARCHAR2 (2);
   vTranEndMin         VARCHAR2 (2);
   vTranEndPM          VARCHAR2 (2);
   vTran               VARCHAR2 (1);
   vTranStatTime       NUMBER;
   vTranEndTime        NUMBER;
   vCurrentTime        NUMBER;
   vHolidayFlag        VARCHAR2 (1);
   vErrorMessage       VARCHAR2 (500);
   vMyException        EXCEPTION;
BEGIN
   vHolidayFlag := 'N';
   vAllowTransaction := 'N';
/
